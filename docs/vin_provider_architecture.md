# VIN provider architecture (Carzon)

This document describes how Carzon models **multiple VIN data sources**, **access modes**, and **visibility** without assuming every provider can be called server-side. It complements the operational decode worker notes in `docs/ops_vin_decode_jobs.md`.

## Goals

- Treat the VIN as a **trust/report layer** over time, not only a stored field.
- Keep **full VIN** and **vin_hash** off client surfaces and out of public APIs.
- Store **normalized, source-scoped** outcomes; avoid **raw provider payloads** unless a future phase explicitly allows it under retention and legal review.
- Support **“no data found”** as a valid outcome, distinct from hard failure.
- Never claim **official Moldova/PMR verification** in product copy unless backed by a named official source and scope.

## Data stores (high level)

| Store | Role |
|--------|------|
| `listing_vehicle_identity` | Owner-private normalized VIN + hash (existing). |
| `vin_decode_cache` | Shared decode cache by `vin_hash` (existing; no raw payloads). |
| `listing_vin_report_snapshot` | Listing-level processing/decode snapshot for workers and owner RPC (existing). |
| `listing_vin_source_results` | **Phase 2E+2F+2G:** one row per `(listing_id, source_id)` for taxonomy, access mode, status, and small normalized summaries. |

NHTSA vPIC decode remains the **basic_decode** path; it is **not** Moldova or PMR official verification.

### Phase 2F — `nhtsa_vpic` bridge

When the Edge worker completes a decode with **`nhtsa_vpic`**, `complete_vin_decode_job_success` **upserts** `listing_vin_source_results`:

- **`source_id`:** `nhtsa_vpic`
- **`region`:** `international`
- **`access_mode`:** `carzon_partner_api` (US public vPIC API called server-side; not a Moldova government contract)
- **`confidence`:** `basic_decode` only
- **`visibility`:** **`public_summary`** for NHTSA after **Phase 2K** (buyer VIN report modal only); earlier migrations used **`owner`** until **2K** backfill/live completes adopted **`public_summary`**
- **`limitation_codes`:** conservative set including `basic_decode_only`, `not_md_pmr_official_verification`, and explicit **not** accident/ownership/insurance/mileage/registration checks
- **`status`:** `succeeded` when at least one useful catalog field is present; **`partial`** when the HTTP decode succeeds but fields are empty (still not Moldova/PMR verification)

The fake decoder (`carzon_fake_vin_decoder`) does **not** write this row.

### Phase 2G — historical backfill (internal, one-time migration)

Migration **`20260625120000_vin_phase2g_backfill_nhtsa_source_results.sql`** inserts missing `nhtsa_vpic` rows for listings that already have **successful** snapshot + **NHTSA** cache history **before** Phase 2F shipped:

- **Sources:** `listing_vin_report_snapshot` joined to `vin_decode_cache` on `vin_hash` (join only — **no** `vin_hash` stored in source results).
- **Evidence:** `processing_status = succeeded`, `decode_status = decoded`, cache `provider_id = nhtsa_vpic`, cache `decode_status = decoded`, and at least one useful catalog field (snapshot columns and/or normalized `engine` / `transmission` / `bodyType` / `fuelType` from cache JSON).
- **Skipped:** fake decoder rows, failed/pending snapshots, cache misses, listings with only empty decoded fields, or listings that already have `(listing_id, nhtsa_vpic)` (**`ON CONFLICT DO NOTHING`** — never replaces a fresher Phase 2F row).
- **`source_metadata`:** includes `backfilled: true`, `backfilled_at`, plus `provider_version` from cache when present (default `decode-vin-values-v1`), optional `warning_codes` from cached normalized warnings.
- **`fetched_at`:** `coalesce(cache.fetched_at, snapshot.last_processed_at, snapshot.updated_at, now())`; **`ttl_until`** from cache when present.

Still **not** Moldova/PMR official verification; **not** accident, ownership, insurance, mileage, or registration history. No full VIN, no `vin_hash`, and no verbatim provider response bodies in `listing_vin_source_results`. Public listing UI unchanged; future owner/public RPCs for source results remain separate work.

## Provider taxonomy (`source_id`)

Examples (extend as needed; enforce shape in application/worker code):

| `source_id` | Intent |
|-------------|--------|
| `nhtsa_vpic` | Basic vehicle attributes from NHTSA (catalog bias; not registration proof). |
| `md_rca_damage` | Moldova RCA/BNM damage or recorded-damage-style information (needs partner/legal path). |
| `md_asp_registration` | Moldova ASP registration-related extract category. |
| `md_asp_owner_extract` | Owner or entitlement-heavy ASP extract category. |
| `pmr_customs` | Transnistria/PMR customs or clearance-related category (research/partner/manual). |
| `commercial_history` | Paid multi-country history providers. |
| `seller_uploaded_document` | Seller-provided PDF/image metadata or parsed summary (consent and retention rules apply). |

## Access modes (`access_mode`)

The schema records **how** data may be obtained, not that Carzon already implements it.

| Value | Meaning |
|--------|---------|
| `carzon_partner_api` | Written partner/API agreement; Carzon may call the provider server-side under contract. |
| `user_delegated` | User completes a **provider-supported** authorization flow; Carzon stores **consent** and bounded results. **Carzon must not auto-register users** on third-party sites or silently create accounts. |
| `seller_uploaded_document` | Seller uploads an official extract or certificate; processing is ingestion/OCR optional and legally gated. |
| `manual_external_check` | Product provides **instructions or deep links only**; **no** automated provider calls from Carzon servers. |
| `commercial_api` | Paid provider with **quotas, billing, and provenance** requirements. |
| `not_available` | Known source category that is not integrable in the current product/legal posture. |
| `unknown` | Research incomplete. |

### Automatic third-party registration

**Default policy:** Carzon does **not** implement automatic sign-up on external services on behalf of users. Any integration that creates or binds third-party accounts requires **explicit user action**, **provider-supported** delegation where applicable, and **recorded consent** (`requires_user_consent`, future consent audit tables).

## Status values (`status`)

Includes lifecycle and policy outcomes, e.g. `no_data`, `requires_user_consent`, `requires_partner_access`, `requires_manual_action`, `rate_limited`, `quota_exceeded`, plus standard `pending` / `succeeded` / `failed` / etc. Workers and product copy must treat **`no_data`** as a valid business outcome.

## Visibility (`visibility`)

| Value | Intended use |
|--------|----------------|
| `internal` | Operations, debugging projections; never expose to app clients. |
| `owner` | Owner-only RPCs/UI; non-NHTSA sources (and pre-2K NHTSA) may remain here. |
| `public_summary` | Buyer-safe summaries via **`get_listing_vin_report_for_buyer`**; **Phase 2K** routes NHTSA **`basic_decode`** here (modal only, with limitations). |

Phases **2E–2G** do **not** add public listing UI or buyer-facing VIN report surfaces.

## Confidence (`confidence`)

Distinguishes **official** vs **partner** vs **commercial** vs **self_reported** vs **basic_decode** to avoid overstating authority in future UI.

## Rate limiting and quotas

Before enabling `commercial_api` or high-volume `carzon_partner_api` paths:

- Per-tenant and per-listing **quotas**.
- **TTL** and cache keys (see `ttl_until`, `fetched_at`).
- **Idempotent** writes keyed by `(listing_id, source_id)`.
- Structured handling of `rate_limited` and `quota_exceeded` statuses.

## Moldova categories (desk research summary)

- **RCA/BNM damage history:** high buyer value; typically **no** confirmed open marketplace API; needs **official/partner/legal** path; do not scrape portals. **Phase 3B (spec/outreach only):** see `docs/vin_md_rca_damage_integration_package.md`.
- **ASP registration/ownership extracts:** strong official value; likely **owner-authenticated** / e-signature / MCabinet-style flows, not anonymous VIN-for-buyers.
- **ASP SMS services:** consumer telecom channel, **not** a scalable partner API for Carzon.

## PMR categories

- **Customs/status:** possible user or document-based flows; **no** confirmed third-party REST API assumed; partner or **manual_external_check** until validated.

## Commercial providers

Path: **contract**, **DPA**, **billing**, **quota**, display **provenance** (“Source: …, date: …, limitations: …”). Prefer **Phase 4** after taxonomy and consent infrastructure are stable.

## Recommended phases

| Phase | Focus |
|--------|--------|
| **2E** | `listing_vin_source_results` schema, RLS, access-mode vocabulary, docs, static tests. |
| **2F** | Live `nhtsa_vpic` completion writes via `complete_vin_decode_job_success`. |
| **2G** | One-time migration backfill from snapshot + cache (no re-decode). |
| **2H** | Owner-only sanitized read: `get_my_listing_vin_source_results`. |
| **2J** | Buyer report **shell** + `get_listing_vin_report_for_buyer`: only `visibility = public_summary` rows; **active** listings. |
| **2K** | NHTSA **`basic_decode`** rows use **`public_summary`** (worker + backfill); buyers see **catalog decode only** inside the VIN report modal; not Moldova/PMR official, not accident/history/registration. |
| **3** | Moldova/PMR **legal** review; optional partner stubs; owner flows; **no** scraping. |
| **4** | Commercial history provider with quotas and buyer-safe summaries. |
| **Hardening** | Retention, DSAR, secret rotation, copy audit (RU/RO), monitoring. |

### Phase 2J — Buyer report shell + public-safe RPC

- **`get_listing_vin_report_for_buyer(p_listing_id)`** (`SECURITY DEFINER`): returns the **same sanitized column projection** as the owner source-results RPC, but only for rows where **`visibility = 'public_summary'`** and the listing exists with **`status = 'active'`**. Returns **empty set** when no **`public_summary`** rows exist.
- **Grants:** `EXECUTE` for **`anon`** and **`authenticated`** so public listing readers can load the shell without owning the listing. No direct **`GRANT`** on `listing_vin_source_results`.
- **Flutter:** buyer-facing bottom sheet (“Отчёт по VIN”) loads this RPC; **empty**, **loading**, and **error** states; **no** full VIN; **no** buyer access to owner RPC or owner-only rows.
- **Not** official Moldova/PMR verification; **not** accident/ownership/insurance/mileage/registration claims. Public report data remains **catalog/partner summaries** only, with limitations surfaced when rows exist.

### Phase 2K — Public NHTSA basic decode for buyers

- **`complete_vin_decode_job_success`**: for **`p_provider_id = 'nhtsa_vpic'`** only, new/updated **`listing_vin_source_results`** rows use **`visibility = 'public_summary'`** and **`confidence = 'basic_decode'`** (same normalized summary, limitation codes, and safe `source_metadata` subset as before — no VIN, vin_hash, raw payloads, or URLs).
- **Backfill** **`UPDATE`**: existing **`nhtsa_vpic`** **`basic_decode`** rows with **`visibility = 'owner'`** and **`status` in (`succeeded`, `partial`)** are set to **`public_summary`**.
- **Buyer RPC** **`get_listing_vin_report_for_buyer`** unchanged: still returns only **`public_summary`** rows for **active** listings. **RCA/BNM/ASP/PMR/commercial** sources remain **`internal` / `owner`** until separate phases.
- **Flutter:** decoded fields (make, model, year, body, fuel, optional engine/transmission), **NHTSA vPIC** source line, dates, and prominent “basic decode only” limitation copy — **only** inside the VIN report modal; listing card stays compact. Optional conservative compare listing vs decode when both sides have clear make/model/year.
- **Not** accident, ownership, insurance, mileage, registration, customs, or legal-history verification; **not** Moldova/PMR “official” claims.

## Safety checklist (engineering)

- No **full VIN** or **vin_hash** in `listing_vin_source_results`.
- No **raw payloads**, **provider URLs**, or **credentials** in this table.
- **anon** / **authenticated**: no direct `GRANT` on the table; **RLS** enabled.
- Listing detail **public** UI: Phases 2E–2G did not add buyer decode; **Phase 2J** adds a buyer **report shell**; **Phase 2K** surfaces **NHTSA `basic_decode`** as **`public_summary`** inside that modal only — still **no** “verified” or “officially confirmed” claims.
