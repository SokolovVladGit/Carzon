# Operations: Fuel price worker (`process-fuel-price-jobs`)

## Scope

The Edge Function **`process-fuel-price-jobs`** drains **`fuel_price_fetch_jobs`** using **`service_role`** RPCs and writes sanitized snapshots into **`fuel_price_snapshots`**.

Flutter reads **`get_fuel_prices_for_app()`** only (Menu / Settings → `/fuel-prices`). The public RPC returns **safe, fresh territory summaries** — no `source_metadata`, `cache_key`, job IDs, raw HTML/JSON, secrets, or worker internals.

**Territories (v1):** Moldova (ANRE national ceiling, MDL, gasoline_95 + diesel) and PMR (Sheriff network, PMR RUB, five Sheriff fuels).

## Hosted status — **closed (2026-06-22)**

**No pending hosted SQL or Edge deploy remains for Fuel Prices.**

| Item | Status |
|------|--------|
| **SQL migrations (3)** | Applied on hosted Carzon |
| **Edge Function** | **`process-fuel-price-jobs`** deployed, **ACTIVE**, version **3** |
| **Edge env** | **`CARZON_FUEL_PRICE_PROVIDER_MODE=live`** |
| **Vault secrets** | **`carzon_process_fuel_price_jobs_url`**, **`carzon_process_fuel_price_jobs_secret`** synced (names only; never commit values) |
| **pg_cron** | Job **`carzon_process_fuel_price_jobs_6h`**, schedule **`0 */6 * * *`**, active |
| **Scheduler smoke** | Post secret sync: HTTP **200**, `{"ok":true,"claimed":1,"succeeded":1,"failed":0}` |
| **Public RPC** | **`get_fuel_prices_for_app()`** returns fresh Moldova + PMR snapshots |

**Ops follow-up (non-blocker):** confirm first automatic cron run in `cron.job_run_details` (join `cron.job` for job name).

The six-hour schedule remains unchanged. On each run, the SQL invoker first keeps
the existing **`enqueue_all_fuel_price_fetch_jobs()`** behavior, then checks for an
eligible queued job before reading Vault or invoking the Edge Function. A fresh
cache with no queued refresh therefore produces no pg_net request. The claim RPC
remains authoritative; work queued immediately after a false preflight waits for
the next scheduled run. Manual Edge invocation retains its own enqueue behavior.

Migration **`20260825120000_reduce_idle_background_worker_io.sql`** also retains
14 days of completed pg_cron history through a daily cleanup capped at 10,000
rows. Existing historical rows require separate observed hosted cleanup. The
migration does not perform pg_net physical bloat recovery.

### Applied migrations (hosted)

1. **`20260822120000_fuel_prices_foundation.sql`**
2. **`20260822123000_schedule_process_fuel_price_jobs_cron.sql`**
3. **`20260822130000_fix_fuel_price_job_reenqueue.sql`**

## Two places secrets live

| Store | Secret names | Consumer |
|-------|--------------|----------|
| **Supabase Vault** | **`carzon_process_fuel_price_jobs_url`**, **`carzon_process_fuel_price_jobs_secret`** | **`public.carzon_invoke_process_fuel_price_jobs_worker()`** (pg_cron → pg_net `POST`) |
| **Edge Function secrets** | **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**, **`CARZON_PROCESS_FUEL_PRICE_JOBS_SECRET`**, **`CARZON_FUEL_PRICE_PROVIDER_MODE`** | Deployed **`process-fuel-price-jobs`** runtime |

Vault **`carzon_process_fuel_price_jobs_secret`** value must equal Edge **`CARZON_PROCESS_FUEL_PRICE_JOBS_SECRET`** (sent as **`x-carzon-internal-secret`**).

**Function URL:** Vault **`carzon_process_fuel_price_jobs_url`** — full `POST` URL including `/functions/v1/process-fuel-price-jobs`.

**Provider mode:** Edge **`CARZON_FUEL_PRICE_PROVIDER_MODE=live`** for production fetches. Missing or invalid mode fails closed (500); do not rely on a silent fake default on hosted.

## Config

**`supabase/config.toml`:**

```toml
[functions.process-fuel-price-jobs]
verify_jwt = false
```

Cron/manual invoke uses **`x-carzon-internal-secret`**, not a user JWT.

## Related docs

- Release anchor: [`docs/RELEASE.md`](RELEASE.md)
- Hosted migration parity: [`docs/hosted_migration_parity_verification.md`](hosted_migration_parity_verification.md)
- Project milestones: [`docs/project_milestones.md`](project_milestones.md)
