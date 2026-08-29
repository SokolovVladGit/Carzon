# Operations: message notification queue processor (Phase 3E)

## Two places secrets live (avoid mixing them up)

| Store | Where you set it | Secret / config names | Who consumes it |
|-------|------------------|------------------------|-----------------|
| **Supabase Vault** (database) | Dashboard **Project Settings → Vault**, or SQL `vault.create_secret` | **`carzon_process_message_notifications_url`**, **`carzon_process_message_notifications_secret`** | **Only** the Postgres worker **`carzon_invoke_process_message_notifications_worker()`** (pg_cron → pg_net `POST`) |
| **Edge Function secrets** | Dashboard **Edge Functions → process-message-notifications → Secrets** (or CLI secrets for deploy) | **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**, **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`**, **`FCM_*`** (see Edge source) | **Only** the deployed **`process-message-notifications`** Deno runtime |

These are **different** storage systems. The cron worker **never** reads Edge Function secrets; it only reads **Vault**. The Edge Function **never** reads Vault; it only reads **Edge secrets**.

**Same value, two names:** the random string for auth must match in both places:

- Edge env name: **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`**
- Vault: secret **name** **`carzon_process_message_notifications_secret`**; its **value** must be that **same** string — the worker sends it as the **`x-carzon-internal-secret`** HTTP header.

**Function URL:** set only in Vault as **`carzon_process_message_notifications_url`** (full `POST` URL). The Edge runtime does **not** need its own URL as an env var for sending FCM.

**Optional developer shell env (not Flutter):** Export **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`** in your shell for **`curl`** smoke only. **`Env` in Flutter (`lib/core/config/env.dart`) does not load this key** — never put it in `.env.client` or `--dart-define-from-file`.

## What runs the processor

After migration **`20260529120000_schedule_process_message_notifications_cron.sql`** is applied:

1. **`pg_cron`** runs job **`carzon_process_message_notifications_1m`** every **minute** (`* * * * *`).
2. The job executes **`public.carzon_invoke_process_message_notifications_worker()`**. The SQL invoker first checks for a due pending **`message_created`** event; only then does it read Vault and **`POST`** the Edge Function URL.
3. The Edge Function **`process-message-notifications`** (same as manual runs) claims rows via **`claim_notification_events_for_processing`** ( **`service_role`** only on DB), sends FCM when prefs/tokens allow, and updates **`notification_delivery_events`** / **`notification_delivery_attempts`**.

No secrets are stored in the migration file or in app repos. **Flutter never sees** the internal secret.

The message, filter-alert, and price-drop cron schedules remain independent and
run every minute. Each SQL invoker now applies its exact event-type eligibility
preflight, so an empty queue does not invoke its Edge Function. Claim RPCs remain
the authoritative concurrency control. Work inserted immediately after a false
preflight waits for the next one-minute run; it is not lost.

Migration **`20260825120000_reduce_idle_background_worker_io.sql`** also schedules
daily bounded cleanup of completed **`cron.job_run_details`** rows older than 14
days. It removes at most 10,000 rows per run. Existing historical rows require a
separate observed hosted cleanup; this migration does not perform pg_net physical
bloat recovery.

## One-time setup per Supabase project

1. Apply migrations through **`20260529120000_schedule_process_message_notifications_cron.sql`** (see [`RELEASE.md`](RELEASE.md) §3).
2. Ensure extensions **pg_net**, **pg_cron**, and **supabase_vault** are enabled (migration uses `CREATE EXTENSION IF NOT EXISTS`; on hosted projects they are typically available).
3. In **SQL Editor** or **Vault UI**, create two secrets (replace placeholders; **do not** commit real values):

```sql
select vault.create_secret(
  '<HTTPS_URL_TO_functions/v1/process-message-notifications>',
  'carzon_process_message_notifications_url',
  'Carzon Phase 3E: POST URL for process-message-notifications worker'
);

select vault.create_secret(
  '<SAME_VALUE_AS_EDGE_ENV_CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET>',
  'carzon_process_message_notifications_secret',
  'Carzon Phase 3E: x-carzon-internal-secret header'
);
```

The URL must match the deployed function, e.g. `https://<PROJECT_REF>.supabase.co/functions/v1/process-message-notifications`.

Until both secrets exist, the worker logs a **WARNING** in Postgres logs and **does not** call the Edge Function (queue is not drained automatically).

## Deploy / update the Edge Function (CLI)

From repo root (with CLI logged in and project linked):

```bash
supabase functions deploy process-message-notifications --no-verify-jwt
```

`supabase/config.toml` already sets **`verify_jwt = false`** for this function only; align CLI flags with deployed config if your workflow differs.

Secrets (**Dashboard → Edge Functions → process-message-notifications → Secrets**): **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**, **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`**, and FCM variables (`FCM_SERVICE_ACCOUNT_JSON` / `FCM_PROJECT_ID` + `FCM_CLIENT_EMAIL` + `FCM_PRIVATE_KEY`).

## Manual invoke (same as production auth model)

```bash
curl -sS -X POST \
  "$SUPABASE_URL/functions/v1/process-message-notifications" \
  -H "Content-Type: application/json" \
  -H "x-carzon-internal-secret: $CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET" \
  -d '{}'
```

Use the **same** secret value as in Edge Function env **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`** and as Vault secret **`carzon_process_message_notifications_secret`**. Do not pass an end-user JWT.

## Inspect queue and attempts

Internal tables (no anon/authenticated API access; use SQL Editor as admin):

- **Pending / processing / outcomes:**  
  `select id, status, event_type, attempts, next_attempt_at, last_error, created_at from notification_delivery_events order by created_at desc limit 50;`
- **Per-token FCM tries:**  
  `select * from notification_delivery_attempts order by created_at desc limit 50;`
- **pg_net last responses (short retention):**  
  `select id, status_code, timed_out, error_msg, created from net._http_response order by created desc limit 20;`

## Disable automatic scheduling

List job id:

```sql
select jobid, jobname, schedule, command, active from cron.job
 where jobname = 'carzon_process_message_notifications_1m';
```

Unschedule:

```sql
select cron.unschedule(j.jobid) from cron.job j
 where j.jobname = 'carzon_process_message_notifications_1m';
```

To **re-enable**, re-run the **`cron.schedule`** block from the migration file (or restore from version control).

## Change interval

Default is **1 minute** for MVP. To change: **unschedule** the job, then **`cron.schedule`** with a new cron expression (e.g. `*/2 * * * *` for every 2 minutes). Keep frequency moderate to avoid spamming the Edge runtime and FCM.

## Related docs

- Release checklist: [`RELEASE.md`](RELEASE.md) §2b (Phase 3A/3E behavior, RLS, Edge secrets).

## Implementation status (product)

**Implemented and hosted scheduler verified; real-device FCM/APNs smoke pending.**

The queue, Edge worker, pg_cron invoke, Vault wiring, and Flutter client paths (preferences, token registration, settings UI, tap routing, foreground local notification when push is enabled) are in the repo and can be exercised on staging. **Do not** treat end-to-end notifications as production-complete until **TestFlight / physical-device** verification (permission, delivery, tap, background) passes.

### Phase 4A — Filter alert backend (queue + Edge + cron)

**Backend path is implemented** (SQL matching, enqueue on new/active listings, dedicated claim RPC, `process-filter-alert-notifications` Edge Function, pg_cron worker). **Phase 4B** wires Flutter toggles, explicit OS permission, tap-to-listing and foreground generic copy when **`PUSH_NOTIFICATIONS_ENABLED`**. Defaults remain conservative (prefs **`false`** until the user opts in). **Do not** declare filter alerts production-live until real-device FCM smoke passes (same as messages).

| Piece | Vault secret **names** (Postgres worker) | Edge Function secrets |
|-------|------------------------------------------|------------------------|
| Filter alerts | **`carzon_process_filter_alert_notifications_url`**, **`carzon_process_filter_alert_notifications_secret`** | **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**, **`CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET`**, same **`FCM_*`** as message worker |

The operator may set **`CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET`** to the **same random string** as the message internal secret if desired; **names** must stay distinct so each worker and Vault entry are unambiguous.

**One-time Vault setup (placeholders only):**

```sql
select vault.create_secret(
  '<HTTPS_URL_TO_functions/v1/process-filter-alert-notifications>',
  'carzon_process_filter_alert_notifications_url',
  'Carzon Phase 4A: POST URL for process-filter-alert-notifications worker'
);
select vault.create_secret(
  '<SAME_VALUE_AS_EDGE_ENV_CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET>',
  'carzon_process_filter_alert_notifications_secret',
  'Carzon Phase 4A: x-carzon-internal-secret header'
);
```

**Deploy Edge Function (CLI):**

```bash
supabase functions deploy process-filter-alert-notifications --no-verify-jwt
```

**Manual invoke:**

```bash
curl -sS -X POST \
  "$SUPABASE_URL/functions/v1/process-filter-alert-notifications" \
  -H "Content-Type: application/json" \
  -H "x-carzon-internal-secret: $CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET" \
  -d '{}'
```

**Verify notification cron jobs (three unchanged schedules):**

```sql
select jobid, jobname, schedule, command, active from cron.job
 where jobname in (
   'carzon_process_message_notifications_1m',
   'carzon_process_filter_alert_notifications_1m',
   'carzon_process_price_drop_notifications_1m'
 )
 order by jobname;
```

**Inspect filter-alert queue rows:**

```sql
select id, status, event_type, recipient_user_id, listing_id, attempts, last_error, created_at
  from notification_delivery_events
 where event_type = 'filter_alert_listing_match'
 order by created_at desc
 limit 50;
```

**Disable filter-alert schedule only:** unschedule `carzon_process_filter_alert_notifications_1m` (same pattern as message job in this doc).

### Resume later: real-device smoke (iOS / Android)

1. **Build** with `PUSH_NOTIFICATIONS_ENABLED=true`, real Firebase config, and a build signed for push (APNs / FCM).  
2. **Sign in**; open **notification settings**; enable global + messages; accept OS permission when prompted (must not auto-prompt on cold start).  
3. **Confirm** token row in `user_push_tokens` and prefs in `notification_preferences`.  
4. **Send** a chat message from another account/device; expect generic title/body on device; **no** message body in payload.  
5. **Tap** notification (background/quit); should open the **existing** thread route.  
6. **Foreground (messages):** receive while app open; local notification shows same copy; tap routes via coordinator.  
7. **Filter alerts:** second account, saved + enabled filter + tokens; new **active** listing match → generic push; **tap** opens listing detail; **foreground** uses same generic copy.  
8. **Hosted:** optional SQL on `notification_delivery_events`, `notification_delivery_attempts`, `net._http_response` (see sections above).
