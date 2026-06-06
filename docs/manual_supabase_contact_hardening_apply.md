# Manual Supabase Contact Hardening Apply Guide

## 1. Before You Start

This guide applies Phase 1 seller contact exposure hardening manually through the Supabase SQL Editor.

This changes database permissions and RPC behavior:

- Public direct reads of `public.listings` lose access to seller contact columns.
- Public direct reads of `public.listing_images` lose access to `storage_path`.
- A public explicit contact reveal RPC is created for active listings only.
- Owner-only edit RPCs are created for listing edit prefill and owner image metadata.

Run this only on the intended Carzon Supabase project.

Do not continue if:

- You are unsure which Supabase project is open.
- You may be looking at the wrong organization or project.
- You cannot tell whether this project contains real users or real listings.
- You have not taken a backup or captured inspection output for a project with real data.

Do not paste API keys, service-role keys, JWTs, passwords, or environment files into this document or into git.

## 2. Confirm Project

Before running any SQL:

- Open Supabase Dashboard.
- Confirm the project name.
- Confirm the project ref.
- Confirm this is the intended Carzon project.
- Confirm whether this project has real users or real listings.
- If real users or real listings exist, make a backup before continuing.

If anything is unclear, stop.

## 3. Backup Recommendation

This migration is designed to be forward-safe, but it changes permissions and RPC definitions. A backup gives you a recovery point if hosted state differs from the repo.

Preferred options:

- Use Supabase Dashboard backups if available for the project plan.
- If CLI/database access exists, take a database dump before applying SQL.
- At minimum, run and save the inspection queries in section 5 before applying, especially current grants and policies.

Minimum pre-apply inspection:

```sql
select
  grantee,
  table_schema,
  table_name,
  column_name,
  privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name in ('listings', 'listing_images')
  and grantee in ('anon', 'authenticated')
order by table_name, grantee, column_name;
```

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
  and tablename in ('listings', 'listing_images')
order by tablename, policyname;
```

Risk if skipped:

- If the project has drifted from migrations, you may not know which previous grants or policies were replaced.

## 4. SQL To Apply

Run the SQL below in Supabase SQL Editor for the intended project.

Run it all at once if the project already has the prior Carzon migration chain applied. The SQL does not contain transaction-forbidden statements. It is safe to rerun in the normal idempotent sense: `REVOKE`, `GRANT`, `COMMENT`, and `CREATE OR REPLACE FUNCTION` can be repeated.

Do not run this if prior migrations are missing. It depends on:

- `public.listings`
- `public.listing_images`
- listing contact columns:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`
- listing public columns granted below
- roles `anon` and `authenticated`
- Supabase `auth.uid()`

```sql
-- Carzon — Phase 1 seller contact exposure hardening.
--
-- Public table reads are column-granted to non-contact listing fields only.
-- Explicit RPCs preserve current contact reveal UX and owner edit prefill.

------------------------------------------------------------------------------
-- Public-safe column grants
------------------------------------------------------------------------------

revoke select on table public.listings from anon;
revoke select on table public.listings from authenticated;

grant select (
    id,
    title,
    make,
    model,
    year,
    price_eur,
    price_currency,
    mileage_km,
    type,
    city,
    market_region,
    body_type,
    fuel_type,
    engine_displacement_liters,
    engine_power_hp,
    drivetrain,
    registration,
    description,
    created_at,
    status,
    cover_image_url,
    seller_id,
    vin_status
) on public.listings to anon, authenticated;

revoke select on table public.listing_images from anon;
revoke select on table public.listing_images from authenticated;

grant select (
    id,
    listing_id,
    public_url,
    position,
    created_at
) on public.listing_images to anon, authenticated;

comment on column public.listings.contact_phone is
    'Seller contact phone. Not column-granted for public listing reads; fetched only through explicit contact/owner RPCs.';
comment on column public.listings.telegram_username is
    'Seller Telegram username. Not column-granted for public listing reads; fetched only through explicit contact/owner RPCs.';
comment on column public.listings.whatsapp_enabled is
    'Seller WhatsApp preference. Not column-granted for public listing reads; fetched only through explicit contact/owner RPCs.';
comment on column public.listing_images.storage_path is
    'Storage object path. Not column-granted for public gallery reads; owner edit metadata uses an owner-only RPC.';

------------------------------------------------------------------------------
-- Public contact reveal RPC
------------------------------------------------------------------------------

create or replace function public.get_listing_public_contact(p_listing_id uuid)
returns table (
    contact_phone text,
    telegram_username text,
    whatsapp_enabled boolean
)
language sql
stable
security definer
set search_path = public, pg_temp
as $$
    select
        l.contact_phone,
        l.telegram_username,
        l.whatsapp_enabled
    from public.listings l
    where l.id = p_listing_id
      and l.status = 'active'
    limit 1;
$$;

revoke all on function public.get_listing_public_contact(uuid) from public;
grant execute on function public.get_listing_public_contact(uuid)
    to anon, authenticated;

------------------------------------------------------------------------------
-- Owner edit initialization RPCs
------------------------------------------------------------------------------

create or replace function public.get_my_listing_for_edit(p_listing_id uuid)
returns public.listings
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_row public.listings;
begin
    if auth.uid() is null then
        raise exception 'not authenticated' using errcode = '28000';
    end if;

    select l.*
      into v_row
      from public.listings l
     where l.id = p_listing_id
       and l.seller_id = auth.uid();

    if not found then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return v_row;
end;
$$;

revoke all on function public.get_my_listing_for_edit(uuid) from public;
revoke all on function public.get_my_listing_for_edit(uuid) from anon;
grant execute on function public.get_my_listing_for_edit(uuid)
    to authenticated;

create or replace function public.get_my_listing_images_for_edit(
    p_listing_id uuid
)
returns table (
    id uuid,
    listing_id uuid,
    public_url text,
    storage_path text,
    "position" integer,
    created_at timestamptz
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null then
        raise exception 'not authenticated' using errcode = '28000';
    end if;

    if not exists (
        select 1
          from public.listings l
         where l.id = p_listing_id
           and l.seller_id = auth.uid()
    ) then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return query
    select
        li.id,
        li.listing_id,
        li.public_url,
        li.storage_path,
        li."position" as "position",
        li.created_at
      from public.listing_images li
     where li.listing_id = p_listing_id
     order by li."position" asc;
end;
$$;

revoke all on function public.get_my_listing_images_for_edit(uuid) from public;
revoke all on function public.get_my_listing_images_for_edit(uuid) from anon;
grant execute on function public.get_my_listing_images_for_edit(uuid)
    to authenticated;
```

## 5. Immediate Verification SQL

Run these after applying the SQL.

### `public.listings` Column Grants

```sql
select
  grantee,
  column_name,
  privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'listings'
  and grantee in ('anon', 'authenticated')
order by grantee, column_name;
```

Expected PASS result:

- Public-safe columns are listed for `anon` and `authenticated`.
- `seller_id` may be listed.
- `contact_phone`, `telegram_username`, and `whatsapp_enabled` are not listed.

FAIL result:

- Any forbidden contact column appears for `anon` or `authenticated`.

What to do if it fails:

- Stop. Re-check that the SQL in section 4 ran successfully.
- Re-run the forbidden column query below.
- Do not continue app smoke testing until grants are fixed.

### `public.listings` Forbidden Contact Columns

```sql
select
  grantee,
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

Expected PASS result:

- Zero rows.

FAIL result:

- One or more rows.

What to do if it fails:

- Treat as a high-severity backend exposure.
- Confirm no later SQL re-granted broad `SELECT` on `public.listings`.

### `public.listing_images` Column Grants

```sql
select
  grantee,
  column_name,
  privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'listing_images'
  and grantee in ('anon', 'authenticated')
order by grantee, column_name;
```

Expected PASS result:

- Public image fields are listed:
  - `id`
  - `listing_id`
  - `public_url`
  - `position`
  - `created_at`
- `storage_path` is not listed.

FAIL result:

- `storage_path` appears for `anon` or `authenticated`.

What to do if it fails:

- Stop. Do not continue app smoke testing until `storage_path` is not publicly granted.

### `public.listing_images` Forbidden `storage_path`

```sql
select
  grantee,
  column_name,
  privilege_type
from information_schema.column_privileges
where table_schema = 'public'
  and table_name = 'listing_images'
  and grantee in ('anon', 'authenticated')
  and column_name = 'storage_path';
```

Expected PASS result:

- Zero rows.

FAIL result:

- One or more rows.

What to do if it fails:

- Treat as a backend permission defect.
- Inspect whether broad `SELECT` was re-granted after the hardening SQL.

### Function Existence And Signatures

```sql
select
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

Expected PASS result:

- `get_listing_public_contact(p_listing_id uuid)` exists.
- `get_my_listing_for_edit(p_listing_id uuid)` exists.
- `get_my_listing_images_for_edit(p_listing_id uuid)` exists.
- All three show `security_definer = true`.

FAIL result:

- Any function is missing.
- Any function has a wrong argument list.
- Any function is not security definer.

What to do if it fails:

- Stop. Re-run the function creation part only after confirming the exact SQL and project.

### Function Execute Grants

```sql
select
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

Expected PASS result:

- `get_listing_public_contact`: executable by `anon` and `authenticated`.
- `get_my_listing_for_edit`: executable by `authenticated`; not executable by `anon`.
- `get_my_listing_images_for_edit`: executable by `authenticated`; not executable by `anon`.

FAIL result:

- Owner RPCs are executable by `anon`.
- Public contact reveal is not executable by the roles required for current Phase 1 UX.

What to do if it fails:

- Stop and fix function grants with a reviewed SQL change.

### RLS Enabled Status

```sql
select
  n.nspname as schema_name,
  c.relname as table_name,
  c.relrowsecurity as rls_enabled,
  c.relforcerowsecurity as rls_forced
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('listings', 'listing_images')
order by c.relname;
```

Expected PASS result:

- `rls_enabled = true` for both `listings` and `listing_images`.

FAIL result:

- `rls_enabled = false` for either table.

What to do if it fails:

- Stop. RLS must be restored before public Data API testing.

### Policies On `public.listings`

```sql
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'listings'
order by policyname;
```

Expected PASS result:

- Public read is limited to active listings.
- Owner read behavior remains owner-scoped.

FAIL result:

- A policy allows `anon` to read hidden, sold, archived, or deleted listings.

What to do if it fails:

- Stop. Review RLS policy drift before continuing.

### Policies On `public.listing_images`

```sql
select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'listing_images'
order by policyname;
```

Expected PASS result:

- Public read is limited to images for active listings.
- Owner read behavior remains owner-scoped.

FAIL result:

- A policy allows `anon` to read images for inactive listings.

What to do if it fails:

- Stop. Review RLS policy drift before continuing.

## 6. Manual Data API Checks

Use placeholders only. Do not paste real keys into this file or commit them.

For owner checks, use `<AUTH_USER_JWT>` as the JWT of the owner account. For non-owner checks, use `<AUTH_USER_JWT>` as a different authenticated test user.

### Anon: Allowed Public Listing Columns

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listings?id=eq.<ACTIVE_LISTING_ID>&select=id,title,make,model,year,price_eur,price_currency,mileage_km,type,city,market_region,body_type,fuel_type,engine_displacement_liters,engine_power_hp,drivetrain,registration,description,created_at,status,cover_image_url,seller_id,vin_status' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

Expected HTTP status:

- `200`.

Expected body shape:

- JSON array with public-safe listing fields only.
- No `contact_phone`, `telegram_username`, or `whatsapp_enabled`.

PASS:

- Public listing fields load and no contact fields appear.

FAIL:

- Contact fields appear.
- Public-safe fields fail due to permission errors.

### Anon: Forbidden Listing Contact Columns

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listings?id=eq.<ACTIVE_LISTING_ID>&select=id,contact_phone,telegram_username,whatsapp_enabled' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

Expected HTTP status:

- Permission/error response such as `400`, `401`, or `403`.

Expected body shape:

- Error object.
- No contact values.

PASS:

- Forbidden columns cannot be selected.

FAIL:

- HTTP `200` with contact values.

### Anon: Forbidden `listing_images.storage_path`

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/listing_images?listing_id=eq.<ACTIVE_LISTING_ID>&select=id,listing_id,public_url,storage_path,position,created_at' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>'
```

Expected HTTP status:

- Permission/error response such as `400`, `401`, or `403`.

Expected body shape:

- Error object.
- No `storage_path` values.

PASS:

- `storage_path` cannot be selected.

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

Expected HTTP status:

- `200`.

Expected body shape:

- JSON array or object shape depending on PostgREST settings.
- Only these fields may appear:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`

PASS:

- Active listing contact is available only through this explicit RPC.

FAIL:

- RPC returns extra listing fields.
- RPC fails for an active listing with valid contact.

### Anon: Contact Reveal For Inactive Listing

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<INACTIVE_LISTING_ID>"}'
```

Expected HTTP status:

- `200`.

Expected body shape:

- Empty result.
- No contact values.

PASS:

- No contact data is returned for inactive listings.

FAIL:

- Any contact value is returned.

### Anon: Contact Reveal For Nonexistent Listing

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <ANON_KEY>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"00000000-0000-0000-0000-000000000000"}'
```

Expected HTTP status:

- `200`.

Expected body shape:

- Empty result.
- No contact values.

PASS:

- No contact data is returned.

FAIL:

- Any contact value is returned.

### Authenticated Non-Owner: Inactive Contact Denial

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_listing_public_contact' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<INACTIVE_LISTING_ID>"}'
```

Expected HTTP status:

- `200`.

Expected body shape:

- Empty result.
- No contact values.

PASS:

- Authenticated non-owner cannot reveal inactive listing contact.

FAIL:

- Any contact value is returned.

### Owner: Edit Listing RPC Success

Use `<AUTH_USER_JWT>` for the owner account in this check.

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<OWNER_LISTING_ID>"}'
```

Expected HTTP status:

- `200`.

Expected body shape:

- Owner listing row.
- Contact edit fields may be present:
  - `contact_phone`
  - `telegram_username`
  - `whatsapp_enabled`

PASS:

- Owner edit prefill fields are available.

FAIL:

- Owner receives an auth/permission error.
- Required edit fields are missing.

### Owner: Edit Images RPC Success

Use `<AUTH_USER_JWT>` for the owner account in this check.

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_images_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<OWNER_LISTING_ID>"}'
```

Expected HTTP status:

- `200`.

Expected body shape:

- Image rows for the owner listing.
- `storage_path` may be present for owner edit.

PASS:

- Owner edit image metadata is available.

FAIL:

- Owner receives an auth/permission error.
- Required image edit fields are missing.

### Owner RPC Non-Owner Listing Denial

Use `<AUTH_USER_JWT>` for an authenticated user who does not own `<NON_OWNER_LISTING_ID>`.

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<NON_OWNER_LISTING_ID>"}'
```

Expected HTTP status:

- Permission/error response such as `400`, `401`, or `403`.

Expected body shape:

- Error object.
- No listing row.

PASS:

- Non-owner cannot read owner edit listing data.

FAIL:

- Listing row is returned.

### Owner Images RPC Non-Owner Listing Denial

Use `<AUTH_USER_JWT>` for an authenticated user who does not own `<NON_OWNER_LISTING_ID>`.

```bash
curl -i \
  '<SUPABASE_URL>/rest/v1/rpc/get_my_listing_images_for_edit' \
  -H 'apikey: <ANON_KEY>' \
  -H 'Authorization: Bearer <AUTH_USER_JWT>' \
  -H 'Content-Type: application/json' \
  --data '{"p_listing_id":"<NON_OWNER_LISTING_ID>"}'
```

Expected HTTP status:

- Permission/error response such as `400`, `401`, or `403`.

Expected body shape:

- Error object.
- No image rows.
- No `storage_path`.

PASS:

- Non-owner cannot read owner edit image metadata.

FAIL:

- Any image rows are returned.

## 7. App Smoke Test After Apply

Run the app against the same Supabase project with client-safe configuration only.

Checklist:

- Feed loads.
- Listing details loads.
- Seller profile loads.
- Favorites loads for a signed-in test user.
- Compare loads and resolves selected listings.
- Owner edit listing loads and pre-fills phone, Telegram, and WhatsApp.
- Phone reveal works from listing details.
- Telegram and WhatsApp appear only after contact fetch succeeds.
- Inactive listing contact is not publicly exposed.

PASS:

- All app flows work.
- Network/API inspection shows public listing payloads do not include contact fields or `storage_path`.

FAIL:

- Feed/detail/favorites/compare payloads include forbidden fields.
- Owner edit cannot load contact prefill.
- Contact reveal fails for active listings after the RPC exists and is granted.

## 8. Rollback / Stop Guidance

If SQL apply fails halfway:

- Stop.
- Copy the exact SQL error into a private issue or incident note.
- Do not rerun random fragments unless you know which statement failed.
- Re-check function existence and grants before deciding whether the migration partially applied.

If public reads break:

- Stop app smoke testing.
- Run the column grant checks in section 5.
- Confirm the client is selecting only public-safe columns.

If owner edit breaks:

- Capture the RPC name, HTTP status, and sanitized error.
- Check `get_my_listing_for_edit` and `get_my_listing_images_for_edit` signatures and execute grants.
- Confirm the test JWT belongs to the listing owner.

If contact reveal fails only for active listings:

- Confirm the listing status is exactly `active`.
- Confirm `get_listing_public_contact(uuid)` exists.
- Confirm execute grants include `anon` and `authenticated`.

Rollback may require restoring previous grants/functions from backup or writing a corrective migration. Do not use a blind rollback that reopens broad public `SELECT` on contact fields unless this is an explicit emergency decision by the project owner.

Emergency-only risk note:

- Re-granting broad `SELECT` on `public.listings` or `public.listing_images` can restore old app behavior, but it also reopens the contact/storage-path exposure this migration is designed to close.

## 9. Final PASS Criteria

PASS only if:

- Public listing contact columns are not directly selectable.
- Public listing image `storage_path` is not directly selectable.
- Active listing contact reveal works only through `get_listing_public_contact`.
- Inactive listings do not reveal contact.
- Owner edit RPCs work for the owner.
- Owner RPCs reject non-owners.
- App smoke test passes.

PARTIAL if:

- Local app works but SQL/API checks were not completed.
- SQL checks pass but app smoke was not completed.

FAIL if:

- `anon` can directly select `contact_phone`, `telegram_username`, `whatsapp_enabled`, or `listing_images.storage_path`.
- Inactive listing contact is returned publicly.
- Owner-only RPCs return data to non-owners.
