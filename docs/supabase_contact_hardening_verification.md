# Supabase Contact Hardening Verification

## Hosted status — **closed (2026-06)**

**Confirmed on hosted Carzon:**

- Migration `20260630120000_public_contact_projection_hardening.sql` applied
- `supabase/maintenance/check_contact_hardening.sql` → `overall_sql_metadata_result` **PASS**
- Simulator smoke after apply: **PASS**
- Hosted migration parity 45/45; runtime contracts PASS

**Current model:** Direct public/client SELECT on protected contact fields and `listing_images.storage_path` is blocked. Active listing contact uses **`get_listing_public_contact`** RPC (anon + authenticated callable — product decision for future rate limiting).

**Optional (not independently confirmed):** anon-only PostgREST Phase 3 curls in `docs/supabase_contact_hardening_post_apply_checklist.md`.

This runbook remains the reference for **future** hosted changes, staging projects, or re-verification after SQL edits.

---

## Purpose

Use this runbook to verify Phase 1 seller contact exposure hardening on the **hosted** Supabase project.

**Staging is preferred.** If no staging project exists (e.g. Supabase free-tier project limit), use the [single-project fallback](#no-staging-project-available--single-project-fallback) below and run **read-only checks first** until an explicit manual apply decision is made.

This verifies that hosted Data API / PostgREST behavior matches the local migration:

- `supabase/migrations/20260630120000_public_contact_projection_hardening.sql`

To **apply** hardening (mutates grants/RPCs — not part of verification):

- `docs/manual_supabase_contact_hardening_apply.md`
- **STOP and ask the project owner** before applying anything from that guide or from SQL Editor apply steps.

Read-only SQL bundle (SQL Editor only — no secrets, no mutations):

- `supabase/maintenance/check_contact_hardening.sql`

## Verification sequence (operator quick start)

Stop on first FAIL. Record outcomes with placeholders only — never commit keys, JWTs, or listing IDs.

### Path A — Staging available (preferred)

1. Confirm staging project ref (`supabase projects list` / Dashboard).
2. SQL Editor → run **`supabase/maintenance/check_contact_hardening.sql`** → copy/screenshot the **full summary table** (`check_name`, `status`, `details`); confirm `overall_sql_metadata_result` is PASS before Phase 3.
3. PostgREST **anon**: forbidden listing column select (section C).
4. PostgREST **anon**: `get_listing_public_contact` active + inactive + nonexistent (section D).
5. PostgREST **authenticated non-owner**: forbidden column select + inactive contact RPC (section C/D).
6. PostgREST **owner JWT**: `get_my_listing_for_edit` success + non-owner rejection (section E).
7. PostgREST **anon**: `get_seller_public_profile` — no contact values (section F).
8. PostgREST **authenticated**: `list_inbox_conversations` — listing JSON has no contact (section F).
9. Flutter/network smoke (section G).

Optional: CLI link / `supabase db push` only when staging is confirmed and owner approved (see [CLI Workflow](#cli-workflow-optional--staging-link--apply)).

### Path B — No staging / single hosted project

Follow [No staging project available / single-project fallback](#no-staging-project-available--single-project-fallback) (Phases 0–5). Do **not** apply migrations during verification.

## No staging project available / single-project fallback

Use when Carzon has **one** hosted Supabase project and no free slot for staging.

**Default mode: read-only verification only.** Any write, apply, or migration push requires a **separate manual approval** from the project owner.

### Phase 0 — Preconditions

- Confirm in Supabase Dashboard that the open project is the **current real hosted Carzon project** (name + project ref).
- Use **read-only checks first** (Phases 1–3 below).
- Prefer **existing** test listings and test users if available; do not create/delete/update rows during verification unless a separate manual test plan is explicitly approved.
- Do **not** paste service-role keys into client tools, curl history, tickets, or this repo.
- Do **not** commit secrets.
- If any check suggests hardening is **missing**, **STOP** — do not apply SQL from `docs/manual_supabase_contact_hardening_apply.md` unless the owner explicitly instructs you to proceed.

### Phase 1 — Local / static checks (no hosted access)

Run on your machine against the repo only:

| Check | PASS | STOP |
|---|---|---|
| Migration file exists: `supabase/migrations/20260630120000_public_contact_projection_hardening.sql` | File present | Missing — fix repo before hosted work |
| Read-only helper exists: `supabase/maintenance/check_contact_hardening.sql` | File present; contains **SELECT only** (no INSERT/UPDATE/DELETE/DDL) | Missing or non-read-only |
| Runbook lists Phases 0–5 and sections B–H below | This document | Incomplete runbook |

Optional local test (no secrets):

```sh
flutter test test/supabase/public_contact_projection_hardening_migration_test.dart
```

### Phase 2 — Hosted read-only SQL checks

1. Open Supabase Dashboard → **SQL Editor** for the confirmed hosted project.
2. Open repo file **`supabase/maintenance/check_contact_hardening.sql`** locally.
3. Paste the **entire file** into SQL Editor → **Run**.

The script returns **one summary table** with columns `check_name`, `status`, `details`. Supabase SQL Editor shows only the last result set — this file is written so that last table is the full summary.

**Screenshot or copy the entire summary table**, especially the `overall_sql_metadata_result` row.

| `overall_sql_metadata_result` | Meaning |
|---|---|
| **PASS** | Proceed to Phase 3 — use **`docs/supabase_contact_hardening_post_apply_checklist.md`** for the final closure checklist. |
| **STOP** | Do **not** apply migrations; ask project owner / tech lead first. |

Per-row statuses: `PASS`, `STOP`, `INFO` (non-blocking), `MANUAL` (Phase 3 reminder).

**Grant check scope:** `forbidden_direct_contact_grants` STOP means **anon**, **authenticated**, or **PUBLIC** can directly SELECT protected columns via PostgREST. Grants to **postgres**, **service_role**, or other internal/admin roles are **expected**, shown in `privileged_internal_grants` (INFO), and are **not** public exposure — **do not REVOKE** privileged roles.

This script inspects migration metadata, column grants, and RPC catalog definitions. It **does not mutate** data or schema and does not use live listing IDs.

### Phase 3 — Hosted anon / auth API checks (read-only PostgREST)

Read-only HTTP GET/RPC calls only — no inserts, updates, or deletes.

Use values prepared outside the repo (section A). Use **anon key** for anon checks; use **test user JWT** only for authenticated checks.

| Check | PASS | STOP |
|---|---|---|
| Anon `select=id,contact_phone,telegram_username,whatsapp_enabled` | Error or empty; no contact values | HTTP 200 with contact values |
| Auth non-owner same forbidden select | Error or empty | HTTP 200 with contact values |
| Anon `get_listing_public_contact` + `<ACTIVE_LISTING_ID>` | Contact fields only (active listing) | Fails for known-good active listing, or extra listing fields |
| Anon `get_listing_public_contact` + `<INACTIVE_LISTING_ID>` | Empty / no contact | Any contact returned |
| Anon `get_listing_public_contact` + nil UUID | Empty / no contact | Any contact returned |
| Anon `get_seller_public_profile` + `<SELLER_USER_ID>` | No phone/Telegram/WhatsApp/email values | Actual contact strings returned |
| Auth `list_inbox_conversations` (if token + data exist) | No contact in embedded `listings` JSON | Contact fields in payload |

Exact curl templates: sections C, D, E, F below.

Skip checks when IDs/tokens are unavailable; note **PARTIAL** in the record.

### Phase 4 — Flutter smoke checks

Point the app at the **same hosted project** using client-safe env only (`SUPABASE_URL`, `SUPABASE_ANON_KEY`). Inspect network traffic (DevTools / proxy).

| Check | PASS | STOP |
|---|---|---|
| Feed initial payload | No `contact_phone`, `telegram_username`, `whatsapp_enabled` | Contact fields in initial feed response |
| Listing detail initial payload | No contact fields on listing/images load | Contact in initial detail load |
| Contact RPC timing | `get_listing_public_contact` only after user contact/reveal action | RPC on detail load without user action |
| After reveal | Contact reveal still works | Reveal broken after hardening |
| Favorites / compare / messaging | No contact in those payloads | Contact leaked |

Full checklist: section G.

### Phase 5 — Decision gate

| Outcome | Action |
|---|---|
| All executed checks PASS | Record **PASS**; proceed with release hardening track per `docs/release_hardening_inventory.md` |
| Direct contact column select succeeds | **STOP** — do not release; hosted grants not hardened |
| Migration `20260630120000` missing | **STOP** — prepare manual apply plan; **ask owner** before apply |
| Public RPC exposes inactive/hidden/sold/archived/deleted contact | **STOP** — backend fix required |
| Flutter initial payloads include contact fields | **STOP** — client/backend contract mismatch |

Applying hardening to the real hosted project is a **separate step** documented in `docs/manual_supabase_contact_hardening_apply.md` and requires **explicit owner approval** — not part of Phase 5 PASS.

## A) Preconditions

Prepare **outside the repository** (local notes / password manager only):

| Input | Purpose |
|---|---|
| `<HOSTED_PROJECT_REF>` | Confirm correct hosted project (staging or single project) |
| `<SUPABASE_URL>` | PostgREST base URL |
| `<ANON_KEY>` | Anon PostgREST checks |
| `<AUTH_USER_JWT>` | Authenticated **non-owner** test user |
| `<OWNER_USER_JWT>` | Listing owner test user |
| `<ACTIVE_LISTING_ID>` | `status = active`, has contact fields populated |
| `<INACTIVE_LISTING_ID>` | `hidden`, `sold`, or `archived` with contact still in DB |
| `<SELLER_USER_ID>` | `seller_id` from `<ACTIVE_LISTING_ID>` (seller profile check) |
| `<OWNER_LISTING_ID>` | Owned by `<OWNER_USER_JWT>` |
| `<NON_OWNER_LISTING_ID>` | Not owned by `<OWNER_USER_JWT>` |

Notes:

- Carzon has no separate `draft` listing status; use **inactive** (hidden/sold/archived) instead.
- **Deleted** listings: use nonexistent UUID check (section D) or a known deleted id if available.
- **Staging is preferred.** If no staging project exists, use the [single-project fallback](#no-staging-project-available--single-project-fallback) and read-only checks first.
- Do not assume credentials are available in CI or this repo.
- No secrets committed to git.

## Safety Rules

- **Staging is preferred** for first-time apply and destructive operations.
- If only one hosted project exists, verification may run against it using **read-only** SQL and read-only PostgREST calls (single-project fallback).
- Do **not** apply migrations, grant changes, or manual hardening SQL during verification unless the **project owner** explicitly approves a separate apply step.
- Do **not** print, paste, or commit service-role keys, refresh tokens, user passwords, or full env files.
- Use placeholders in notes and tickets. Never store real keys in this repository.
- Stop immediately if the target project name or ref is ambiguous.
- Stop immediately if any check fails. Do not apply ad hoc SQL patches during verification.

## B) Migration applied check

Open in SQL Editor: **`supabase/maintenance/check_contact_hardening.sql`** (read-only; returns one summary table). Or run the migration query below directly for a single check only.

### Migration Presence

```sql
select version
from supabase_migrations.schema_migrations
where version = '20260630120000';
```

Expected result:

- One row.

PASS:

- `20260630120000` is present.

FAIL:

- No row.

Likely cause:

- Migration was not applied to the hosted project.

Next action:

- **STOP.** Do not apply during verification. Ask the project owner whether to use `supabase db push` (staging, owner-approved link) or `docs/manual_supabase_contact_hardening_apply.md`.

Alternative (CLI — staging + owner approval only):

```bash
supabase migration list --linked
```

PASS: `20260630120000` appears in remote column for the linked hosted project.

## Phase 1 Contract

Public/anon listing reads must not expose:

- `contact_phone`
- `telegram_username`
- `whatsapp_enabled`

Public/anon listing image reads must not expose:

- `storage_path`

Explicit contact reveal is allowed only through:

- `get_listing_public_contact(p_listing_id uuid)`

Owner edit data is allowed only through authenticated owner-only RPCs:

- `get_my_listing_for_edit(p_listing_id uuid)`
- `get_my_listing_images_for_edit(p_listing_id uuid)`

`seller_id` remains public because current seller profile routing, seller trust, and messaging guards depend on it.

## C) Direct column access checks (PostgREST)

Use placeholders only. Do not paste real keys into committed files.

Also run SQL grant blocks in `supabase/maintenance/check_contact_hardening.sql` (sections **C**).

## CLI Workflow (optional — staging link / apply; owner approval required)

**Not part of read-only verification.** Use only when a **separate staging project** exists and the owner has approved link/apply. For single-project setups, **STOP** here unless the owner explicitly requests apply.

### Confirm Current Link

```bash
supabase projects list
supabase migration list --linked
```

PASS:

- The linked project is clearly staging.
- The project ref matches the expected `<STAGING_PROJECT_REF>`.

FAIL:

- The linked project is named like production, is ambiguous, or is unknown.
- The linked project is missing expected staging markers.

Next action on FAIL:

- Stop. Do not push migrations. Confirm the staging project ref with the project owner.

### Link Staging Safely

Only run this after the staging project ref is confirmed:

```bash
supabase link --project-ref <STAGING_PROJECT_REF>
supabase projects list
supabase migration list --linked
```

PASS:

- The linked marker is on the confirmed staging project.

FAIL:

- The linked marker points anywhere else.

Next action on FAIL:

- Stop. Do not run `supabase db push`.

### Apply Pending Migrations To Staging

Only after staging is confirmed:

```bash
supabase db push
supabase migration list --linked
```

PASS:

- `20260630120000` appears in the remote migration column.
- Earlier local migrations required by staging are also applied in order.

FAIL:

- `supabase db push` fails.
- `20260630120000` remains local-only.
- Migration order is inconsistent.

Next action on FAIL:

- Stop. Capture the error without secrets. Fix migration drift or SQL defects in a separate backend task.

## SQL Verification Snippets (SQL Editor)

Run these in the Supabase SQL Editor for the target hosted project, or through `psql` if available.

**Preferred:** paste the bundled read-only script **`supabase/maintenance/check_contact_hardening.sql`** (entire file). It returns one summary table for SQL Editor. Do not run apply/migration SQL from this runbook.

### Grants On `public.listings`

```sql
select
  grantee,
  privilege_type,
  column_name
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'listings'
  and grantee in ('anon', 'authenticated')
order by grantee, column_name;
```

Expected result:

- Public-safe columns are granted.
- `seller_id` may be granted.
- Forbidden columns are not granted:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`

PASS:

- No forbidden column appears for `anon` or `authenticated`.

FAIL:

- Any forbidden column appears.

Likely cause:

- Broad table `SELECT` remains or the hardening migration did not apply.

Recommended next action:

- Review grants and rerun `20260630120000` on the hosted project through the approved migration path (owner approval required).

### Forbidden Listing Column Grant Check

```sql
select
  grantee,
  table_name,
  column_name,
  privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'listings'
  and grantee in ('anon', 'authenticated')
  and column_name in (
    'contact_phone',
    'telegram_username',
    'whatsapp_enabled'
  );
```

Expected result:

- Zero rows.

PASS:

- Zero rows.

FAIL:

- One or more rows.

### Grants On `public.listing_images`

```sql
select
  grantee,
  privilege_type,
  column_name
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'listing_images'
  and grantee in ('anon', 'authenticated')
order by grantee, column_name;
```

Expected result:

- Public-safe image columns are granted:
  - `id`
  - `listing_id`
  - `public_url`
  - `position`
  - `created_at`
- `storage_path` is not granted.

PASS:

- `storage_path` is absent.

FAIL:

- `storage_path` appears for `anon` or `authenticated`.

### Forbidden Image Column Grant Check

```sql
select
  grantee,
  table_name,
  column_name,
  privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'listing_images'
  and grantee in ('anon', 'authenticated')
  and column_name = 'storage_path';
```

Expected result:

- Zero rows.

PASS:

- Zero rows.

FAIL:

- One or more rows.

### RPC Existence And Signatures

```sql
select
  n.nspname as schema_name,
  p.proname as function_name,
  pg_get_function_identity_arguments(p.oid) as arguments,
  pg_get_function_result(p.oid) as result_type,
  p.prosecdef as security_definer
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'get_listing_public_contact',
    'get_my_listing_for_edit',
    'get_my_listing_images_for_edit'
  )
order by p.proname;
```

Expected result:

- `get_listing_public_contact(p_listing_id uuid)` returns:
  - `contact_phone text`
  - `telegram_username text`
  - `whatsapp_enabled boolean`
- `get_my_listing_for_edit(p_listing_id uuid)` returns `public.listings`.
- `get_my_listing_images_for_edit(p_listing_id uuid)` returns:
  - `id uuid`
  - `listing_id uuid`
  - `public_url text`
  - `storage_path text`
  - `position integer`
  - `created_at timestamptz`
- All three are `security_definer = true`.

PASS:

- All three functions exist with the expected signatures and `security_definer = true`.

FAIL:

- Any function is missing, has a mismatched signature, or is not security definer.

### RPC Execute Grants

```sql
select
  routine_schema,
  routine_name,
  grantee,
  privilege_type
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name in (
    'get_listing_public_contact',
    'get_my_listing_for_edit',
    'get_my_listing_images_for_edit'
  )
order by routine_name, grantee;
```

Expected result:

- `get_listing_public_contact`: executable by `anon` and `authenticated`.
- `get_my_listing_for_edit`: executable by `authenticated`, not `anon`.
- `get_my_listing_images_for_edit`: executable by `authenticated`, not `anon`.

PASS:

- Execute grants match expected roles.

FAIL:

- Owner RPCs are executable by `anon`, or contact reveal is not executable by required public roles.

### RLS Policies On `public.listings`

```sql
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'listings'
order by policyname;
```

Expected result:

- Public read policy still limits public reads to active listings.
- Owner read policy still exists where required by the app.
- RLS remains enabled.

PASS:

- No policy exposes inactive listings to `anon`.

FAIL:

- Any policy allows `anon` to read hidden, sold, archived, or deleted rows.

### RLS Policies On `public.listing_images`

```sql
select
  schemaname,
  tablename,
  policyname,
  permissive,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'listing_images'
order by policyname;
```

Expected result:

- Public image read policy is limited to images for active listings.
- Owner image read policy remains owner-scoped.

PASS:

- No policy exposes inactive listing images to `anon`.

FAIL:

- Any policy allows `anon` to read inactive listing images.

## D) Public RPC checks (`get_listing_public_contact`)

Callable by **anon** and **authenticated**. Must return contact only for **active** listings.

## Data API / PostgREST Checks

Use placeholders only. Do not paste real keys into committed files.

### Anon: Allowed Public Listing Columns

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listings?id=eq.<ACTIVE_LISTING_ID>&select=id,title,make,model,year,price_eur,price_currency,mileage_km,type,city,market_region,body_type,fuel_type,engine_displacement_liters,engine_power_hp,drivetrain,registration,description,created_at,status,cover_image_url,seller_id,vin_status' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

Expected result:

- HTTP `200`.
- JSON contains only requested public-safe fields.

PASS:

- Response succeeds and contains no contact fields.

FAIL:

- Response includes `contact_phone`, `telegram_username`, or `whatsapp_enabled`.

### Anon: Forbidden Listing Columns

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listings?id=eq.<ACTIVE_LISTING_ID>&select=id,contact_phone,telegram_username,whatsapp_enabled' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

Expected result:

- HTTP error such as `400`, `401`, or `403`, or a PostgREST permission error.
- No contact values returned.

PASS:

- Forbidden columns cannot be retrieved.

FAIL:

- HTTP `200` with contact values.

Likely cause:

- Forbidden columns remain granted to `anon`.

### Anon: Forbidden Image `storage_path`

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listing_images?listing_id=eq.<ACTIVE_LISTING_ID>&select=id,listing_id,public_url,storage_path,position,created_at' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

Expected result:

- HTTP error for `storage_path`.
- No storage paths returned.

PASS:

- `storage_path` cannot be retrieved.

FAIL:

- HTTP `200` with `storage_path`.

### Anon: Contact Reveal For Active Listing

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<ACTIVE_LISTING_ID>"}'
```

Expected result:

- HTTP `200`.
- Returns only:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`

PASS:

- Active listing contact is returned through this explicit RPC only.
- No extra listing fields are returned.

FAIL:

- RPC returns extra fields, fails for active listings, or direct table reads also expose contact.

### Anon: Contact Reveal For Inactive Listing

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<INACTIVE_LISTING_ID>"}'
```

Expected result:

- HTTP `200` with an empty result, or equivalent no-row response.
- No contact values returned.

PASS:

- No contact data for hidden, sold, archived, deleted, or nonexistent listings.

FAIL:

- Any contact data is returned.

### Anon: Contact Reveal For Nonexistent Listing

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"00000000-0000-0000-0000-000000000000"}'
```

Expected result:

- HTTP `200` with an empty result, or equivalent no-row response.

PASS:

- No contact data.

FAIL:

- Any contact data is returned.

### Authenticated Non-Owner: Forbidden Listing Columns

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listings?id=eq.<ACTIVE_LISTING_ID>&select=id,contact_phone,telegram_username,whatsapp_enabled' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>'
```

Expected result:

- Permission error for forbidden columns.
- No contact values returned.

PASS:

- Authenticated non-owner cannot retrieve contact through direct table reads.

FAIL:

- HTTP `200` with contact values.

### Authenticated Non-Owner: Forbidden Image `storage_path`

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listing_images?listing_id=eq.<ACTIVE_LISTING_ID>&select=id,listing_id,public_url,storage_path,position,created_at' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>'
```

Expected result:

- Permission error for `storage_path`.

PASS:

- Authenticated non-owner cannot retrieve storage paths through direct table reads.

FAIL:

- HTTP `200` with `storage_path`.

### Authenticated Non-Owner: Inactive Listing Public Contact

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<INACTIVE_LISTING_ID>"}'
```

Expected result:

- No contact values returned.

PASS:

- Inactive contact remains hidden.

FAIL:

- Any contact data is returned.

## E) Owner RPC checks

Owner-only: `get_my_listing_for_edit`, `get_my_listing_images_for_edit`. Must reject non-owners.

### Owner: Edit Listing RPC Success

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <OWNER_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<OWNER_LISTING_ID>"}'
```

Expected result:

- HTTP `200`.
- Owner listing row includes edit fields required by the app.
- Contact fields may be present:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`

PASS:

- Owner edit prefill data is available only through this RPC.

FAIL:

- RPC fails for the owner, or omits fields required by edit.

### Owner: Edit Images RPC Success

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_images_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <OWNER_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<OWNER_LISTING_ID>"}'
```

Expected result:

- HTTP `200`.
- Image metadata for the owner listing is returned.
- `storage_path` may be present for owner edit flow.

PASS:

- Owner receives image edit metadata through owner-only RPC.

FAIL:

- RPC fails for owner or omits required image edit metadata.

### Owner JWT Against Non-Owner Listing

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <OWNER_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<NON_OWNER_LISTING_ID>"}'
```

Expected result:

- HTTP error or no usable row.
- Error may mention not owned / forbidden.

PASS:

- Non-owner listing is rejected.

FAIL:

- A listing row is returned for a non-owner.

### Owner JWT Against Non-Owner Images

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_images_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <OWNER_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<NON_OWNER_LISTING_ID>"}'
```

Expected result:

- HTTP error or no usable rows.

PASS:

- Non-owner image metadata is rejected.

FAIL:

- Image rows or `storage_path` are returned for a non-owner listing.

## F) Non-contact public surfaces

These must not return actual phone, Telegram, WhatsApp, or email **values**.

### Anon: Seller public profile

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_seller_public_profile' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_seller_id":"<SELLER_USER_ID>"}'
```

Expected result:

- HTTP `200` with display name, avatar, trust placeholders.
- Response must **not** include: `contact_phone`, `telegram_username`, `whatsapp_enabled`, `email`.
- `verified_phone` / `verified_email` may appear as **booleans only**.

PASS:

- No actual contact values.

FAIL:

- Any phone, Telegram handle, WhatsApp flag tied to listing contact, or email string.

### Anon / authenticated: Feed-style listing projection

Same column set the Flutter feed uses:

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listings?status=eq.active&select=id,title,make,model,year,price_eur,price_currency,mileage_km,type,city,market_region,body_type,fuel_type,engine_displacement_liters,engine_power_hp,drivetrain,registration,description,created_at,status,cover_image_url,seller_id,vin_status&limit=5' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

PASS:

- HTTP `200`; no `contact_phone`, `telegram_username`, `whatsapp_enabled` in any row.

FAIL:

- Contact fields present in feed payload.

### Authenticated: Inbox conversations (messaging)

Requires a user with at least one conversation (or empty list is OK):

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/list_inbox_conversations' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{}'
```

Expected result:

- HTTP `200`.
- Embedded `listings` JSON objects contain card fields only (id, title, make, model, city, cover_image_url, price_eur, price_currency).
- No contact columns.

PASS:

- No contact values in `listings` JSON.

FAIL:

- `contact_phone`, `telegram_username`, `whatsapp_enabled`, or seller email in inbox payload.

## G) Flutter smoke checklist

Run an app build configured only with client-safe hosted values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Use DevTools / proxy / Charles — inspect network only; do not log secrets.

Checks:

- Feed loads; **initial** `/rest/v1/listings` payload has **no** contact fields.
- Listing detail loads; **initial** listing + images requests have **no** contact fields.
- **No** `get_listing_public_contact` call until user taps phone / Telegram / WhatsApp contact action.
- After reveal tap: `get_listing_public_contact` returns contact; phone reveal still works.
- Favorites (signed-in): nested `listings(...)` projection has **no** contact fields.
- Compare screen resolve: listing fetches have **no** contact fields.
- Messaging inbox/thread: conversation listing embed has **no** contact fields.
- Seller profile loads; **no** phone/Telegram/WhatsApp/email values.
- Owner edit opens and pre-fills phone, Telegram, WhatsApp via owner RPC path.
- Telegram and WhatsApp icons appear only **after** contact RPC succeeds.

PASS:

- All flows work; public payloads exclude contact fields and `storage_path`.

FAIL:

- Any public feed/detail/favorites/compare/messaging payload includes contact fields or `storage_path`.
- Contact RPC fires on detail load without user contact action.

## H) Failure handling

If a check fails:

1. Stop verification.
2. Do not patch hosted SQL manually during verification.
3. Capture: check name, expected vs actual, HTTP status or SQL error (no secrets).
4. Classify:
   - **Direct contact column select succeeds** → backend-only; migration `20260630120000` missing or grants drift; apply via approved migration path (`docs/manual_supabase_contact_hardening_apply.md`).
   - **Migration missing** → **STOP** release; ask owner before apply (`docs/manual_supabase_contact_hardening_apply.md`); re-run this runbook after apply.
   - **Public RPC exposes inactive listing contact** → backend-only; inspect `get_listing_public_contact` body on hosted DB.
   - **Client public payloads include contact fields** → client projection bug and/or hosted grants not applied; fix both tracks as needed.
   - **Owner RPC returns data to non-owner** → backend security defect; block release.
5. Open a fix task. Apply fixes through migrations and normal review.

Do not roll back blindly. Prefer forward-fix migration unless approved staging rollback exists.

## Stop / Rollback Guidance (reference)

## Final Assessment Criteria

### PASS

- Target hosted project is confirmed (staging or single-project fallback with owner awareness).
- Migration `20260630120000` is applied.
- Anon and authenticated non-owner direct Data API reads cannot retrieve forbidden fields.
- Contact reveal RPC returns contact only for active listings.
- Owner edit RPCs work for the owner and reject non-owners.
- Client smoke passes against the hosted project used for verification.

### PARTIAL

- Local code and SQL contracts are correct, but hosted checks are incomplete (e.g. missing test JWTs or listing IDs).
- Or hosted grants are fixed, but client smoke has not been run.
- Single-project read-only Phases 1–3 passed but Phase 4 not run.

### FAIL

- Public or authenticated non-owner Data API access can still retrieve:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`
  - `listing_images.storage_path`
- Or inactive listing contact is returned publicly.
- Or owner-only RPCs return data to non-owners.
