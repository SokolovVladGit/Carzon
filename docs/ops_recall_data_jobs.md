# Operations: Recall / Safety Campaigns worker (`process-recall-data-jobs`)

## Scope

The Edge Function **`process-recall-data-jobs`** drains **`vehicle_recall_fetch_jobs`** rows using **`service_role`** RPCs and writes sanitized rows into **`vehicle_recall_source_cache`**.

Recall v1 is **model-level only** (listing make / model / year). It is **not** VIN-level open recall status.

This feature is **separate** from:

- Model Passport (`process-model-data-jobs`)
- VIN decode (`process-vin-decode-jobs`)
- Buyer VIN report (`get_listing_vin_report_for_buyer`)

Flutter listing details (future) will call **`get_listing_recalls_for_buyer`** only. UI copy must **not** claim that the exact vehicle has an open recall.

## Provider modes (Edge env)

| `CARZON_RECALL_DATA_PROVIDER_MODE` | Behavior |
|-----------------------------------|----------|
| **`fake`** (default) | Non-production **`no_data`** for all jobs. **No NHTSA HTTP.** Safe for cron before NHTSA rollout. |
| **`fake_sample`** | Deterministic sample campaigns for **Toyota Camry 2020** only; otherwise **`no_data`**. Manual QA only — **not for production**. |
| **`nhtsa`** | Real **NHTSA recallsByVehicle** JSON fetch. **Production mode for Recall v1.** |

**Important:** Before switching from **`fake_sample`** to **`nhtsa`**, delete rows in **`vehicle_recall_source_cache`** and **`vehicle_recall_fetch_jobs`** for `source_id = 'nhtsa_recalls'` so stale fake-sample cache is not served to buyers.

## NHTSA provider behavior

Server-side flow only (never from Flutter):

1. `GET https://api.nhtsa.gov/recalls/recallsByVehicle?make={MAKE}&model={MODEL}&modelYear={MODEL_YR}`
2. Map JSON `Results[]` → buyer-safe `normalized_summary.campaigns[]`
3. Write cache via `complete_vehicle_recall_fetch_job_success`

Match behavior:

| API result | Cache status | Notes |
|------------|--------------|-------|
| 0 campaigns | `no_data` | Valid outcome; buyer RPC returns empty |
| 1–10 campaigns | `succeeded` | `exact_make_model_year` |
| >10 campaigns | `partial` | First 10 campaigns stored; `make_model_year_multiple_campaigns` |

Limitations always include:

- `us_market_data_only`
- `model_level_not_exact_vehicle`
- `not_vin_verified_recall_status`
- `may_differ_by_trim_engine_market`
- `verify_with_official_dealer_or_nhtsa`

NHTSA data is **US-market model/year campaign reference data**, not Moldova/PMR homologation or VIN-verified status.

**No API key** is required for the public NHTSA recalls API at time of writing.

**Timeouts / errors:**

- 15s timeout per HTTP call
- 429 / 5xx → retryable job failure (exponential backoff via worker RPC)
- Malformed JSON → non-retryable failure
- Zero campaigns → **`no_data`**, not failure

Raw NHTSA JSON is **not** stored in `normalized_summary` and is **not** returned to clients.

## Buyer RPC

**`get_listing_recalls_for_buyer(p_listing_id)`**

- Reads **`listings.make/model/year`** for **active** listings only
- Never reads VIN tables
- Enqueues fetch jobs idempotently on miss/stale
- Returns sanitized cache rows only (`succeeded` / `partial`, TTL valid, ≥1 campaign)
- Projects **allowlisted** campaign fields at the RPC boundary

## Secrets (two stores)

| Store | Names | Consumer |
|-------|-------|----------|
| **Edge Function secrets** | `SUPABASE_URL`, `SUPABASE_SERVICE_ROLE_KEY`, `CARZON_PROCESS_RECALL_DATA_JOBS_SECRET`, optional `CARZON_RECALL_DATA_PROVIDER_MODE` | `process-recall-data-jobs` |
| **Vault (pg_cron scheduler)** | `carzon_process_recall_data_jobs_url`, `carzon_process_recall_data_jobs_secret` | `carzon_invoke_process_recall_data_jobs_worker()` |

Vault URL value example:

`https://<PROJECT_REF>.supabase.co/functions/v1/process-recall-data-jobs`

Vault secret value must match Edge **`CARZON_PROCESS_RECALL_DATA_JOBS_SECRET`**.

## Scheduler

Migration **`20260707123000_schedule_process_recall_data_jobs_cron.sql`** registers pg_cron job **`carzon_process_recall_data_jobs_30m`** (every 30 minutes).

If Vault secrets are missing, the invoke helper logs a **WARNING** and skips HTTP (no crash).

The 30-minute schedule is unchanged. The SQL invoker now checks for a due,
retry-eligible queued recall job before reading Vault or invoking the Edge
Function, so an empty queue produces no pg_net request. The claim RPC remains
authoritative; work inserted immediately after a false preflight waits for the
next scheduled run.

Migration **`20260825120000_reduce_idle_background_worker_io.sql`** also retains
14 days of completed pg_cron history through a daily cleanup capped at 10,000
rows. Existing historical rows require separate observed hosted cleanup, and the
migration does not perform pg_net physical bloat recovery.

## fake_sample QA checklist

1. Set Edge `CARZON_RECALL_DATA_PROVIDER_MODE=fake_sample`
2. Clear `vehicle_recall_source_cache` / `vehicle_recall_fetch_jobs` for `nhtsa_recalls`
3. Open an active listing with **Toyota Camry 2020** (seller-entered make/model/year)
4. Call `get_listing_recalls_for_buyer` — expect ≥1 campaign after worker runs
5. Non-matching make/model/year → buyer RPC empty (`no_data`)

## Production rollout checklist

1. Apply migrations **`20260707120000_vehicle_recall_data_foundation.sql`** and **`20260707123000_schedule_process_recall_data_jobs_cron.sql`**
2. Deploy Edge Function **`process-recall-data-jobs`**
3. Set Edge secrets (`CARZON_PROCESS_RECALL_DATA_JOBS_SECRET`, etc.)
4. Start with **`CARZON_RECALL_DATA_PROVIDER_MODE=fake`**; verify cron invokes without HTTP errors
5. Run **`fake_sample`** QA on staging
6. Clear stale cache rows; switch to **`nhtsa`**
7. Verify buyer RPC returns campaigns for a known US-model listing and empty for unmatched models
8. Confirm buyer UI copy (when implemented) uses model/year language only — **never** exact-vehicle open recall claims

## VIN-level recall

**Not implemented.** Do not read `listing_vehicle_identity` or call VIN-scoped recall endpoints from this worker.
