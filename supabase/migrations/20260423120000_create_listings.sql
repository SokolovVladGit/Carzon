-- Carzon — initial listings read schema
--
-- Scope: public, read-only listings feed for the mobile MVP.
-- Out of scope (future migrations): seller write policies, favorites,
-- chat, dealer model, moderation, payments, full-text search.
--
-- Mapping to Flutter (lib/features/listings/data/models/listing_model.dart):
--   id                -> id (uuid, pk)
--   title             -> title (text)
--   make / model      -> make / model (text)
--   year              -> year (int)
--   price_eur         -> price_eur (numeric)
--   mileage_km        -> mileage_km (int)
--   type              -> type (text: sale | exchange | both)
--   city              -> city (text)
--   created_at        -> created_at (timestamptz)
--   cover_image_url   -> cover_image_url (text, nullable)
--   seller_id         -> seller_id (uuid, nullable, fk -> auth.users)
-- Server-only (not consumed by client today):
--   status            -> visibility flag enforced via RLS

create extension if not exists "pgcrypto";

create table if not exists public.listings (
    id               uuid        primary key default gen_random_uuid(),
    title            text        not null,
    make             text        not null,
    model            text        not null,
    year             integer     not null,
    price_eur        numeric(12,2) not null,
    mileage_km       integer     not null,
    type             text        not null default 'sale',
    city             text        not null,
    cover_image_url  text,
    seller_id        uuid        references auth.users(id) on delete set null,
    status           text        not null default 'active',
    created_at       timestamptz not null default now(),

    constraint listings_year_chk      check (year between 1900 and 2100),
    constraint listings_price_chk     check (price_eur >= 0),
    constraint listings_mileage_chk   check (mileage_km >= 0),
    constraint listings_type_chk      check (type   in ('sale','exchange','both')),
    constraint listings_status_chk    check (status in ('active','hidden','sold','archived'))
);

-- Indexes — only what the current Flutter datasource actually queries:
-- 1) Public feed: filter status='active' + order by created_at desc + paginate.
create index if not exists listings_status_created_at_idx
    on public.listings (status, created_at desc);

-- 2) Make filter (eq) restricted to publicly visible rows.
create index if not exists listings_active_make_idx
    on public.listings (make)
    where status = 'active';

-- 3) Year range (gte/lte) restricted to publicly visible rows.
create index if not exists listings_active_year_idx
    on public.listings (year)
    where status = 'active';

-- Row Level Security: public read of active listings only.
-- No write policies in this migration — writes will be added when the
-- create-listing feature lands.
alter table public.listings enable row level security;

drop policy if exists "listings_public_read_active" on public.listings;
create policy "listings_public_read_active"
    on public.listings
    for select
    to anon, authenticated
    using (status = 'active');
