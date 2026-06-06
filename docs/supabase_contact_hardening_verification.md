# Supabase Contact Hardening Verification

## Purpose

Use this runbook to verify Phase 1 seller contact exposure hardening on a confirmed **staging** Supabase project.

This verifies that hosted Data API / PostgREST behavior matches the local migration:

- `supabase/migrations/20260630120000_public_contact_projection_hardening.sql`

If there is no separate confirmed staging project and the owner must apply the migration through Supabase SQL Editor, use:

- `docs/manual_supabase_contact_hardening_apply.md`

## Safety Rules

- Run this against **staging only**.
- Do **not** run this against production.
- Do **not** print, paste, or commit service-role keys, refresh tokens, user passwords, or full env files.
- Use placeholders in notes and tickets. Never store real keys in this repository.
- Stop immediately if the linked project name or ref is ambiguous.
- Stop immediately if any check fails. Do not apply ad hoc SQL patches during verification.

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

## Required Test Inputs

Prepare these values outside the repository:

- `<STAGING_PROJECT_REF>`
- `<SUPABASE_URL>`
- `<ANON_KEY>`
- `<AUTH_USER_JWT>` for an authenticated non-owner test user
- `<OWNER_USER_JWT>` for the listing owner
- `<ACTIVE_LISTING_ID>` for an active listing with contact fields
- `<INACTIVE_LISTING_ID>` for a hidden, sold, or archived listing with contact fields
- `<OWNER_LISTING_ID>` owned by `<OWNER_USER_JWT>`
- `<NON_OWNER_LISTING_ID>` not owned by `<OWNER_USER_JWT>`

## CLI Workflow

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

## SQL Verification Snippets

Run these in the Supabase SQL Editor for staging or through `psql` connected to staging.

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

- Migration was not applied to staging.

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

- Review grants and rerun `20260630120000` on staging through the approved migration path.

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

## Client Smoke Checklist

Run an app build configured only with staging client-safe values:

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Checks:

- Feed loads.
- Listing detail loads.
- Seller profile loads.
- Favorites loads for a signed-in staging user.
- Compare loads and resolves listings.
- Owner edit opens and pre-fills phone, Telegram, WhatsApp.
- Phone reveal fetches contact explicitly.
- Telegram and WhatsApp actions appear only after contact fetch succeeds.

PASS:

- All flows work and browser/network logs show no public listing payload carrying contact fields.

FAIL:

- Any public feed/detail/favorites/compare payload includes contact fields or `storage_path`.

## Stop / Rollback Guidance

If a check fails:

1. Stop verification.
2. Do not patch hosted SQL manually.
3. Capture:
   - command or SQL check name
   - expected result
   - actual result
   - HTTP status or SQL error without secrets
4. Classify:
   - backend-only: grants, RLS, RPC signature, migration drift
   - client-only: app still selecting forbidden fields
   - both: mismatch between app projection and hosted grants/RPCs
5. Open a fix task. Apply fixes through migrations and normal review.

Do not roll back blindly. If the staging migration breaks critical staging flows, prefer a forward-fix migration unless the team has an approved staging rollback procedure.

## Final Assessment Criteria

### PASS

- Staging is confirmed.
- Migration `20260630120000` is applied.
- Anon and authenticated non-owner direct Data API reads cannot retrieve forbidden fields.
- Contact reveal RPC returns contact only for active listings.
- Owner edit RPCs work for the owner and reject non-owners.
- Client smoke passes against staging.

### PARTIAL

- Local code and SQL contracts are correct, but hosted checks are incomplete.
- Or hosted grants are fixed, but client smoke has not been run.

### FAIL

- Public or authenticated non-owner Data API access can still retrieve:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`
  - `listing_images.storage_path`
- Or inactive listing contact is returned publicly.
- Or owner-only RPCs return data to non-owners.
