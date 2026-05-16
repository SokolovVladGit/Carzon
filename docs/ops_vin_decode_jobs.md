# Operations: VIN decode worker (`process-vin-decode-jobs`)

## Scope

The Edge Function **`process-vin-decode-jobs`** drains **`vin_processing_jobs`** decode rows using **`service_role`** RPCs. **NHTSA vPIC** (**`CARZON_VIN_DECODER_MODE=nhtsa`**) performs **basic US catalog VIN decode only** — not Moldova or Transnistria (PMR) official verification, ownership history, accidents, or insurance.

Public listings **`vin_status`** and mobile listing UX are unchanged by the scheduler; buyers still see **`VIN указан`** when appropriate.

## Two places secrets live (avoid mixing them up)

| Store | Where you set it | Secret / config names | Who consumes it |
|-------|------------------|------------------------|-----------------|
| **Supabase Vault** (database) | Dashboard **Project Settings → Vault**, or SQL `vault.create_secret` | **`carzon_process_vin_decode_jobs_url`**, **`carzon_process_vin_decode_jobs_secret`** | **Only** **`public.carzon_invoke_process_vin_decode_jobs_worker()`** (pg_cron → pg_net `POST`) |
| **Edge Function secrets** | Dashboard **Edge Functions → process-vin-decode-jobs → Secrets** | **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**, **`CARZON_PROCESS_VIN_DECODE_JOBS_SECRET`**, **`CARZON_VIN_DECODER_MODE`** | Deployed **`process-vin-decode-jobs`** runtime |

The cron worker **never** reads Edge secrets; it only reads **Vault**. The Edge Function **never** reads Vault.

**Same value, two names:** the random string for HTTP auth must match:

- Edge env: **`CARZON_PROCESS_VIN_DECODE_JOBS_SECRET`**
- Vault secret **name** **`carzon_process_vin_decode_jobs_secret`** — **value** equals that same string (sent as **`x-carzon-internal-secret`**).

**Function URL:** set only in Vault as **`carzon_process_vin_decode_jobs_url`** (full `POST` URL including `/functions/v1/process-vin-decode-jobs`).

**Decoder mode:** set on Edge as **`CARZON_VIN_DECODER_MODE`** — use **`nhtsa`** for real vPIC calls; omit or **`fake`** for deterministic offline decode (see Edge source).

## What runs after migration

After **`20260621120000_schedule_process_vin_decode_jobs_cron.sql`** is applied:

1. **`pg_cron`** runs job **`carzon_process_vin_decode_jobs_5m`** every **5 minutes** (`*/5 * * * *`).
2. The job runs **`select public.carzon_invoke_process_vin_decode_jobs_worker();`**, which **`POST`s** the Vault URL with headers **`Content-Type: application/json`** and **`x-carzon-internal-secret`**, body **`{"limit":10}`** (JSON). When the queue is empty, the Edge response is still **`200`** with **`{"ok":true,"claimed":0,"succeeded":0,"failed":0}`** (exact field order may vary).
3. The Edge worker claims jobs, calls **`get_vin_for_decode_job`** per claimed row, decodes via configured provider, and completes via **`complete_vin_decode_job_*`** RPCs. **No full VIN or `vin_hash`** appears in HTTP responses or scheduled SQL.

Until both Vault secrets exist, the worker logs a **WARNING** and skips HTTP (no crash).

## One-time Vault setup (per project)

```sql
select vault.create_secret(
  '<HTTPS_URL_TO_functions/v1/process-vin-decode-jobs>',
  'carzon_process_vin_decode_jobs_url',
  'Carzon VIN: POST URL for process-vin-decode-jobs worker'
);

select vault.create_secret(
  '<SAME_VALUE_AS_EDGE_ENV_CARZON_PROCESS_VIN_DECODE_JOBS_SECRET>',
  'carzon_process_vin_decode_jobs_secret',
  'Carzon VIN: x-carzon-internal-secret header'
);
```

## Hosted verification SQL

**Cron job:**

```sql
select jobid, jobname, schedule, command, active
  from cron.job
 where jobname = 'carzon_process_vin_decode_jobs_5m';
```

**Latest pg_net response** (short retention; expect **`status_code = 200`** when Edge accepts the invoke). Column sets vary slightly by pg_net version; expand `select *` if needed:

```sql
select id, status_code, timed_out, error_msg, created
  from net._http_response
 order by created desc
 limit 10;
```

When debugging, confirm JSON **`ok`**, **`claimed`**, **`succeeded`**, **`failed`** via **manual curl** (above) or Edge logs; some deployments also persist response bytes on **`net._http_response.content`** (inspect as UTF-8 if present).

**Queue / outcomes** (SQL Editor as privileged role):

```sql
select id, status, job_type, attempts, last_error, updated_at
  from vin_processing_jobs
 where job_type = 'decode'
 order by updated_at desc
 limit 20;
```

Pending decode rows should move to **`succeeded`** / **`failed`** according to Edge logic; **`listing_vin_report_snapshot`** and **`vin_decode_cache`** update via existing Phase 2 RPCs.

## Manual invoke (same auth model as cron)

```bash
curl -sS -X POST \
  "$SUPABASE_URL/functions/v1/process-vin-decode-jobs" \
  -H "Content-Type: application/json" \
  -H "x-carzon-internal-secret: $CARZON_PROCESS_VIN_DECODE_JOBS_SECRET" \
  -d '{"limit":10}'
```

## Disable automatic scheduling

```sql
select cron.unschedule(j.jobid)
  from cron.job j
 where j.jobname = 'carzon_process_vin_decode_jobs_5m';
```

Re-enable by re-running the **`cron.schedule`** block from the migration file (or redeploy migration from version control).

## Related docs

- Supabase layout: [`../supabase/README.md`](../supabase/README.md)
- Message-notification scheduler pattern: [`ops_message_notifications.md`](ops_message_notifications.md)
