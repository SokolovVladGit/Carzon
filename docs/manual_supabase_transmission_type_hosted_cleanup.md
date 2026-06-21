# Manual hosted cleanup — transmission_type migration metadata + RPC overloads

> **Context:** `20260711120000_listing_transmission_type.sql` was applied manually in the Supabase SQL Editor. Column, CHECK, grants, and the **new** RPC overloads (with `p_transmission_type`) are present on hosted. Two cleanup steps remain:
>
> 1. Record migration metadata (`schema_migrations`).
> 2. Drop **old** RPC overloads (without `p_transmission_type`) that were left behind because the original migration `DROP FUNCTION` targeted the wrong arity.
>
> **Do not re-run** `supabase/migrations/20260711120000_listing_transmission_type.sql` on hosted. **Do not run** `supabase db push` in the same session.

## Before you start

- Confirm Dashboard project name/ref match the intended Carzon hosted project.
- This is a **hosted write** (metadata + `DROP FUNCTION` only). Owner approval required.
- No listing data is modified by these statements.
- VIN enqueue logic lives in the **remaining** (new) overloads — we only drop the old overloads.

---

## Section A — Cleanup statements (paste and run once)

```sql
-- A1. Record migration metadata (idempotent)
insert into supabase_migrations.schema_migrations (version, name)
values ('20260711120000', 'listing_transmission_type')
on conflict (version) do nothing;

-- A2. Drop pre-transmission RPC overloads (without p_transmission_type)
drop function if exists public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text,
    text
);

drop function if exists public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text,
    text
);
```

---

## Section B — Verification queries (read-only; run after Section A)

```sql
-- B1. Migration history
select version, name
from supabase_migrations.schema_migrations
where version = '20260711120000';

-- B2. RPC overload count (expect exactly one row per function)
select
  p.proname,
  pg_get_function_arguments(p.oid) as args
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('create_listing_v2', 'update_listing_details_v2')
order by p.proname;

-- B3. Remaining function bodies
select
  p.proname,
  position('p_transmission_type' in pg_get_functiondef(p.oid)) > 0 as has_transmission_param,
  position('transmission_type' in pg_get_functiondef(p.oid)) > 0 as writes_transmission_type,
  position('carzon_enqueue_vin_decode_from_identity' in pg_get_functiondef(p.oid)) > 0 as preserves_vin_enqueue
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in ('create_listing_v2', 'update_listing_details_v2')
order by p.proname;
```

### Expected after cleanup

| Check | Expected |
|-------|----------|
| B1 | One row: `20260711120000` / `listing_transmission_type` |
| B2 | **Two rows total** — one `create_listing_v2`, one `update_listing_details_v2`, each `args` includes `p_transmission_type text DEFAULT NULL` |
| B3 | Both rows: `has_transmission_param = true`, `writes_transmission_type = true`, `preserves_vin_enqueue = true` |

Optional parity re-check (repo inventory vs hosted metadata):

```sql
-- From repo: supabase/maintenance/check_hosted_migration_parity.sql
```

---

## After cleanup — manual app QA

Proceed with hosted app QA when B1–B3 pass:

1. Create listing → set «Коробка передач» → publish.
2. SQL: `select id, title, transmission_type from public.listings where transmission_type is not null order by created_at desc limit 5;`
3. Details specs show «Коробка»; edit preselects and saves; compare row appears.

If `transmission_type` stays NULL after create, STOP — RPC routing may still be wrong.

---

## Local migration fix (for future deploys)

Repo file `supabase/migrations/20260711120000_listing_transmission_type.sql` now drops **pre-transmission** signatures before `CREATE`, matching Section A2. Fresh applies and future `db push` on databases that still have the old overload will not leave duplicates.
