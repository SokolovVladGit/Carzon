-- Carzon — favorites foundation.
--
-- Scope: per-user favorites of listings. Authenticated users can read,
-- insert, and delete only their own rows. No update policy (favorites
-- are immutable; toggling = insert/delete).

create table if not exists public.favorites (
    user_id     uuid        not null references auth.users(id)     on delete cascade,
    listing_id  uuid        not null references public.listings(id) on delete cascade,
    created_at  timestamptz not null default now(),

    primary key (user_id, listing_id)
);

-- Composite PK already covers (user_id, listing_id) lookups and
-- duplicate prevention. Add ordered index for the favorites page query
-- (newest favorites first per user).
create index if not exists favorites_user_created_at_idx
    on public.favorites (user_id, created_at desc);

-- Listing-id index supports cascade delete cleanup and any future
-- "favorited count" queries; cheap and routinely recommended for FKs.
create index if not exists favorites_listing_id_idx
    on public.favorites (listing_id);

alter table public.favorites enable row level security;

drop policy if exists "favorites_select_own" on public.favorites;
create policy "favorites_select_own"
    on public.favorites
    for select
    to authenticated
    using (user_id = auth.uid());

drop policy if exists "favorites_insert_own" on public.favorites;
create policy "favorites_insert_own"
    on public.favorites
    for insert
    to authenticated
    with check (user_id = auth.uid());

drop policy if exists "favorites_delete_own" on public.favorites;
create policy "favorites_delete_own"
    on public.favorites
    for delete
    to authenticated
    using (user_id = auth.uid());
