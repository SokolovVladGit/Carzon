-- Carzon — introduce `market_region` as a first-class listings dimension.
--
-- Why: Carzon must cleanly split browsing between Transnistria and Moldova.
-- A free-text `city` field cannot carry that intent reliably. This migration
-- adds a dedicated, constrained column so the feed query, indexes, and
-- future filters can depend on it.
--
-- Allowed values: 'transnistria' | 'moldova'.
-- Scope: schema only; RLS policies are intentionally unchanged — the
-- public-read policy (status = 'active') and owner-read policy are both
-- orthogonal to market_region and remain correct.
--
-- Migration strategy (safe for existing data):
--   1. Add column nullable.
--   2. Backfill existing rows — current seed is Chișinău/Bălți (Moldova).
--   3. Set NOT NULL.
--   4. Add CHECK constraint on the allowed values.
--   5. Add a composite index aligned with the real feed query pattern:
--      (market_region, status, created_at desc).
--
-- The pre-existing `listings_status_created_at_idx` remains useful when
-- the feed is browsed without a region filter ("Both"), so it is kept.

alter table public.listings
    add column if not exists market_region text;

-- Backfill: every existing row was seeded with a Moldova city. If a future
-- seed introduces Transnistrian cities, adjust before running this migration.
update public.listings
    set market_region = 'moldova'
    where market_region is null;

alter table public.listings
    alter column market_region set not null;

alter table public.listings
    drop constraint if exists listings_market_region_chk;
alter table public.listings
    add constraint listings_market_region_chk
    check (market_region in ('transnistria', 'moldova'));

create index if not exists listings_region_status_created_at_idx
    on public.listings (market_region, status, created_at desc);
