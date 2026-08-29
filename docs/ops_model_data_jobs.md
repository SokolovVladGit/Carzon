# Operations: Model Passport worker (`process-model-data-jobs`)

## Scope

The Edge Function **`process-model-data-jobs`** drains **`vehicle_model_fetch_jobs`** rows using **`service_role`** RPCs and writes sanitized rows into **`vehicle_model_source_cache`**.

**Phase 2** adds an opt-in **EPA / FuelEconomy.gov** provider. **Phase 3** adds buyer-facing listing-details UI (Model Passport section). **Recall data is not implemented** in Carzon and is out of scope for this worker.

This feature is **separate** from:

- VIN decode (`process-vin-decode-jobs`)
- Buyer VIN report (`get_listing_vin_report_for_buyer`)
- Recall/history (not implemented)

Flutter listing details call **`get_listing_model_data_for_buyer`** via `GetListingModelDataForBuyer` → `SupabaseModelDataRemoteDataSource`. The section hides on failure/empty/no displayable data.

## Provider modes (Edge env)

| `CARZON_MODEL_DATA_PROVIDER_MODE` | Behavior |
|-----------------------------------|----------|
| **`fake`** (default) | Non-production **`no_data`** for all jobs. **No EPA HTTP.** Safe for cron before EPA rollout. |
| **`fake_sample`** | Deterministic succeeded sample for **Toyota Camry 2020** and **Toyota Highlander 2020** only; otherwise **`no_data`**. Manual QA only — **not for production**. |
| **`epa`** | Real **FuelEconomy.gov REST** menu + vehicle detail fetch. **Production mode for Model Passport v1.** |

**Important:** Hosted cron uses **`epa`** in production. Before switching from **`fake_sample`** to **`epa`**, delete rows in **`vehicle_model_source_cache`** and **`vehicle_model_fetch_jobs`** for `source_id = 'epa_fueleconomy'` so stale fake-sample cache (same source id) is not served to buyers.

## EPA provider behavior (Phase 2)

Server-side flow only (never from Flutter):

1. `GET /ws/rest/vehicle/menu/options?year={year}&make={make}&model={model}`
2. For each selected vehicle id (max **5** when multiple options): `GET /ws/rest/vehicle/{id}`
3. Parse XML → normalized summary (MPG, L/100km, CO₂, fuel type, vehicle class)
4. Write cache via `complete_vehicle_model_fetch_job_success`

Match behavior:

| Menu result | Cache status | Notes |
|-------------|--------------|-------|
| 0 options | `no_data` | `match_quality=no_match`, `source_data_unavailable` |
| 1 option | `succeeded` when core fields present | `exact_make_model_year` |
| 2+ options | `partial` with averaged numeric fields | `multiple_configurations_possible`, max 5 configs sampled |

Limitations always include:

- `us_market_data_only`
- `may_differ_by_trim_engine_market`
- `model_level_not_exact_vehicle`
- `not_vehicle_history`
- `not_recall_data`

EPA data is **US-market/configuration-specific**. It is catalog reference data, not Moldova/PMR homologation.

**No API key** is required for the public FuelEconomy.gov REST service at time of writing.

**Timeouts / errors:**

- 15s timeout per HTTP call
- 429 / 5xx → retryable job failure
- Other HTTP / malformed responses → non-retryable or safe failure depending on step

Raw XML is **not** stored in `normalized_summary` and is **not** returned to clients. Worker logs do not stringify raw XML or job payloads.

## Buyer RPC

**`get_listing_model_data_for_buyer(p_listing_id)`**

- Reads **`listings.make/model/year`** for **active** listings only
- Never reads VIN tables
- Enqueues fetch jobs idempotently on miss/stale
- Returns sanitized cache rows only (`succeeded` / `partial`, TTL valid)
- Projects **allowlisted** `normalized_summary` keys at the RPC boundary (fuel economy, CO₂, vehicle_class, market)
- Does **not** return `source_metadata`, `cache_key`, job identifiers, MPG, transmission, drive, engine, or `provider_vehicle_id`

Flutter uses this RPC only. The listing-details UI displays an allowlisted subset of `normalized_summary` (L/100km, CO₂ g/km, fuel type) and never shows MPG, transmission, drive, engine, or provider vehicle ids in v1.

## Secrets (two stores)

| Store | Names | Consumer |
|-------|-------|----------|
| **Supabase Vault** | **`carzon_process_model_data_jobs_url`**, **`carzon_process_model_data_jobs_secret`** | **`carzon_invoke_process_model_data_jobs_worker()`** |
| **Edge Function secrets** | **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**, **`CARZON_PROCESS_MODEL_DATA_JOBS_SECRET`**, **`CARZON_MODEL_DATA_PROVIDER_MODE`** | **`process-model-data-jobs`** runtime |

## Manual invoke

The pg_cron job **`carzon_process_model_data_jobs_30m`** remains on its existing
30-minute schedule. Its SQL invoker now checks for a queued, retry-eligible model
job before reading Vault or invoking the Edge Function, so an empty queue produces
no pg_net request. The claim RPC remains authoritative; a job inserted just after
a false preflight waits for the next scheduled run.

Migration **`20260825120000_reduce_idle_background_worker_io.sql`** also retains
14 days of completed pg_cron history with one daily cleanup capped at 10,000 rows.
Existing historical rows require separate observed hosted cleanup. The migration
does not perform pg_net physical bloat recovery.

```bash
curl -sS -X POST \
  "$SUPABASE_URL/functions/v1/process-model-data-jobs" \
  -H "Content-Type: application/json" \
  -H "x-carzon-internal-secret: $CARZON_PROCESS_MODEL_DATA_JOBS_SECRET" \
  -d '{"limit":10}'
```

## EPA mode smoke (after opt-in)

1. Set Edge secret **`CARZON_MODEL_DATA_PROVIDER_MODE=epa`**
2. Redeploy **`process-model-data-jobs`** (project owner — not Cursor)
3. Ensure Phase 1 SQL migrations are already applied on hosted Supabase
4. Call buyer RPC for an active US-market listing (e.g. Toyota Camry 2020)
5. Invoke worker manually (curl above) or wait for cron
6. Re-query buyer RPC; expect `epa_fueleconomy` row when EPA matches
7. Open listing details in the app (RU/RO); verify Model Passport section after seller specs

Verify in Edge logs: `mode=epa`. Verify **no** `fueleconomy.gov` traffic when mode is `fake`.

## SQL / hosted Supabase

Phase 1 migrations (apply manually if not already done):

- `supabase/migrations/20260706120000_vehicle_model_data_foundation.sql`
- `supabase/migrations/20260706123000_schedule_process_model_data_jobs_cron.sql`
- `supabase/migrations/20260706130000_model_data_buyer_rpc_volatile.sql`
- `supabase/migrations/20260706133000_model_data_buyer_rpc_safe_summary.sql`

**Production rollout (hosted):** set **`CARZON_MODEL_DATA_PROVIDER_MODE=epa`**, clear fake-sample cache/jobs (see provider modes above), redeploy **`process-model-data-jobs`**, invoke worker once, verify buyer RPC.

## Hosted verification checklist (project owner)

- [ ] Phase 1 migrations applied (including buyer RPC volatile + safe summary)
- [ ] Vault secrets configured
- [ ] Edge deployed; **`CARZON_MODEL_DATA_PROVIDER_MODE=epa`** for production
- [ ] Fake-sample cache cleared before EPA switch (if applicable)
- [ ] Cron `carzon_process_model_data_jobs_30m` active
- [ ] Buyer RPC returns empty or sanitized rows only
- [ ] Listing details: Model Passport hidden when RPC empty/fails
- [ ] Listing details: section shows after specs for US model with cache data (EPA mode)
- [ ] Listing details: disclaimers expand; no VIN/recall claims in main card
- [ ] EPA mode produces US-market rows with limitation codes
- [ ] Recall remains unimplemented

## Manual app QA (Phase 4)

Test on device/simulator with hosted Supabase:

| Scenario | Expected UI |
|----------|-------------|
| Listing with no model data (default `fake` mode) | Model Passport section **hidden**; page otherwise normal |
| Toyota Camry 2020 + `fake_sample` mode + worker run | Section visible with metric rows and EPA source badge |
| US model with EPA cache (`epa` mode) | Combined/city/highway L/100km, CO₂, fuel type; no MPG |
| Non-US / unknown model | Section hidden after worker returns `no_data` |
| RPC failure / offline | Section hidden; listing page does not crash |
| RU and RO locales | Localized title, units, limitation disclaimers |

**Do not** use Cursor to deploy Edge Functions, change hosted secrets, run Git, or apply SQL.

## Related docs

- VIN worker: `docs/ops_vin_decode_jobs.md`
- VIN provider taxonomy: `docs/vin_provider_architecture.md` (do not reuse `listing_vin_source_results` for model data)
