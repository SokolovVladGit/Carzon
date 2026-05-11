-- Carzon — `listings.updated_at` column + maintenance trigger.
--
-- Hosted parity gap: fresh projects from older migration chains lacked this
-- column while RPCs and clients assume rows carry a sensible `updated_at`.
-- Idempotent: safe on databases that already applied the manual SQL Editor fix.

------------------------------------------------------------------------------
-- 1 — Column (nullable first for backfill)
------------------------------------------------------------------------------

alter table public.listings
    add column if not exists updated_at timestamptz;

------------------------------------------------------------------------------
-- 2 — Backfill
------------------------------------------------------------------------------

update public.listings
   set updated_at = coalesce(created_at, now())
 where updated_at is null;

------------------------------------------------------------------------------
-- 3 — Default + NOT NULL
------------------------------------------------------------------------------

alter table public.listings
    alter column updated_at set default now(),
    alter column updated_at set not null;

------------------------------------------------------------------------------
-- 4 — Trigger function + trigger
------------------------------------------------------------------------------

create or replace function public.set_listings_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists listings_set_updated_at on public.listings;

create trigger listings_set_updated_at
    before update on public.listings
    for each row
    execute function public.set_listings_updated_at();
