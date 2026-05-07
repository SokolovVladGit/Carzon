-- Carzon — Seller public profiles foundation (schema, storage, RLS, RPC).
--
-- Scope:
--   * Table `seller_profiles`: public-facing seller identity + reserved trust columns.
--   * Storage bucket `seller-avatars` (separate from `listing-images`).
--   * RLS: no anonymous direct SELECT on the table; public reads via RPC only.
--   * RPC `get_seller_public_profile`: safe summary including active listing count.
--   * `ensure_seller_profile`: SECURITY DEFINER insert-if-absent from auth.users metadata.
--   * Trigger on `listings` AFTER INSERT so every new listing ensures a profile row.
--   * Backfill distinct `seller_id` values from existing listings.
--
-- Privacy:
--   * Email and private auth fields are never stored on `seller_profiles` and are not
--     returned by `get_seller_public_profile`. Display name comes only from optional
--     auth metadata `full_name` during ensure/backfill — never from email.
--
-- Future trust:
--   * `rating_average`, `rating_count`, `review_count`, verification flags, and
--     `seller_type` are schema placeholders — no review tables and no fake ratings.

------------------------------------------------------------------------------
-- 1 — seller_profiles
------------------------------------------------------------------------------

create table if not exists public.seller_profiles (
    user_id              uuid primary key references auth.users(id) on delete cascade,
    display_name         text,
    avatar_url           text,
    avatar_path          text,
    member_since         timestamptz not null,
    seller_type          text not null default 'private',
    public_visibility    boolean not null default true,
    moderation_status    text not null default 'active',
    rating_average       numeric(3, 2),
    rating_count         integer not null default 0,
    review_count         integer not null default 0,
    verified_phone       boolean not null default false,
    verified_email       boolean not null default false,
    verified_dealer      boolean not null default false,
    created_at           timestamptz not null default now(),
    updated_at           timestamptz not null default now(),

    constraint seller_profiles_seller_type_chk
        check (seller_type in ('private', 'dealer')),
    constraint seller_profiles_moderation_status_chk
        check (moderation_status in ('active', 'hidden', 'suspended')),
    constraint seller_profiles_rating_average_chk
        check (
            rating_average is null
            or (rating_average >= 1.00 and rating_average <= 5.00)
        ),
    constraint seller_profiles_rating_count_chk
        check (rating_count >= 0),
    constraint seller_profiles_review_count_chk
        check (review_count >= 0),
    constraint seller_profiles_display_name_len_chk
        check (display_name is null or char_length(display_name) <= 200),
    constraint seller_profiles_avatar_url_len_chk
        check (avatar_url is null or char_length(avatar_url) <= 2048),
    constraint seller_profiles_avatar_path_len_chk
        check (avatar_path is null or char_length(avatar_path) <= 1024)
);

comment on table public.seller_profiles is
    'Public seller identity row per auth user. Trust/rating columns reserved for future features — not populated by reviews yet.';
comment on column public.seller_profiles.avatar_url is
    'Public URL for profile photo display (future upload). Not listing imagery.';
comment on column public.seller_profiles.avatar_path is
    'Storage object path under seller-avatars bucket for owner-scoped replace/delete.';
comment on column public.seller_profiles.rating_average is
    'Reserved: aggregate rating 1–5 when review system exists. Do not fabricate.';
comment on column public.seller_profiles.member_since is
    'Shown as public trust signal; typically mirrors auth user signup time at creation.';

------------------------------------------------------------------------------
-- 2 — Indexes (listings + optional seller_profiles lookup)
------------------------------------------------------------------------------

create index if not exists listings_seller_id_idx
    on public.listings (seller_id);

create index if not exists listings_active_seller_id_idx
    on public.listings (seller_id)
    where status = 'active';

------------------------------------------------------------------------------
-- 3 — updated_at touch (for future owner/RPC updates)
------------------------------------------------------------------------------

create or replace function public.touch_seller_profiles_updated_at()
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

drop trigger if exists seller_profiles_touch_updated_at on public.seller_profiles;
create trigger seller_profiles_touch_updated_at
    before update on public.seller_profiles
    for each row
    execute function public.touch_seller_profiles_updated_at();

------------------------------------------------------------------------------
-- 4 — ensure_seller_profile (SECURITY DEFINER; internal + trigger + backfill)
------------------------------------------------------------------------------

create or replace function public.ensure_seller_profile(p_user_id uuid)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_created         timestamptz;
    v_name            text;
    v_avatar          text;
    v_name_clean      text;
    v_avatar_clean    text;
begin
    if p_user_id is null then
        return;
    end if;

    select u.created_at,
           coalesce(u.raw_user_meta_data->>'full_name', ''),
           coalesce(u.raw_user_meta_data->>'avatar_url', '')
      into v_created, v_name, v_avatar
      from auth.users u
     where u.id = p_user_id;

    if not found then
        return;
    end if;

    v_name_clean := nullif(btrim(v_name), '');
    if v_name_clean is not null and char_length(v_name_clean) > 200 then
        v_name_clean := left(v_name_clean, 200);
    end if;

    v_avatar_clean := nullif(btrim(v_avatar), '');
    if v_avatar_clean is not null and char_length(v_avatar_clean) > 2048 then
        v_avatar_clean := null;
    end if;

    insert into public.seller_profiles (
        user_id,
        display_name,
        avatar_url,
        member_since
    )
    values (
        p_user_id,
        v_name_clean,
        v_avatar_clean,
        coalesce(v_created, now())
    )
    on conflict (user_id) do nothing;
end;
$$;

revoke all on function public.ensure_seller_profile(uuid) from public;
revoke all on function public.ensure_seller_profile(uuid) from anon;
revoke all on function public.ensure_seller_profile(uuid) from authenticated;

------------------------------------------------------------------------------
-- 5 — Trigger: new listing → ensure seller profile
------------------------------------------------------------------------------

create or replace function public.listings_after_insert_ensure_seller_profile()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if new.seller_id is not null then
        perform public.ensure_seller_profile(new.seller_id);
    end if;
    return new;
end;
$$;

revoke all on function public.listings_after_insert_ensure_seller_profile() from public;
revoke all on function public.listings_after_insert_ensure_seller_profile() from anon;
revoke all on function public.listings_after_insert_ensure_seller_profile() from authenticated;

drop trigger if exists listings_after_insert_ensure_seller_profile on public.listings;
create trigger listings_after_insert_ensure_seller_profile
    after insert on public.listings
    for each row
    execute function public.listings_after_insert_ensure_seller_profile();

------------------------------------------------------------------------------
-- 6 — RLS on seller_profiles
------------------------------------------------------------------------------

alter table public.seller_profiles enable row level security;

-- Authenticated users may read only their own row (account/settings future).
-- Anonymous clients must use get_seller_public_profile — no direct table read.
drop policy if exists "seller_profiles_select_own" on public.seller_profiles;
create policy "seller_profiles_select_own"
    on public.seller_profiles
    for select
    to authenticated
    using (user_id = auth.uid());

-- Inserts/updates/deletes: not exposed to clients (trigger + definer functions only).

------------------------------------------------------------------------------
-- 7 — Storage bucket seller-avatars (paths: avatars/<auth.uid()>/...)
------------------------------------------------------------------------------

insert into storage.buckets (id, name, public)
values ('seller-avatars', 'seller-avatars', true)
on conflict (id) do nothing;

drop policy if exists "seller_avatars_public_read" on storage.objects;
create policy "seller_avatars_public_read"
    on storage.objects
    for select
    to anon, authenticated
    using (bucket_id = 'seller-avatars');

drop policy if exists "seller_avatars_owner_insert" on storage.objects;
create policy "seller_avatars_owner_insert"
    on storage.objects
    for insert
    to authenticated
    with check (
        bucket_id = 'seller-avatars'
        and split_part(name, '/', 1) = 'avatars'
        and split_part(name, '/', 2) = auth.uid()::text
    );

drop policy if exists "seller_avatars_owner_update" on storage.objects;
create policy "seller_avatars_owner_update"
    on storage.objects
    for update
    to authenticated
    using (
        bucket_id = 'seller-avatars'
        and split_part(name, '/', 1) = 'avatars'
        and split_part(name, '/', 2) = auth.uid()::text
    )
    with check (
        bucket_id = 'seller-avatars'
        and split_part(name, '/', 1) = 'avatars'
        and split_part(name, '/', 2) = auth.uid()::text
    );

drop policy if exists "seller_avatars_owner_delete" on storage.objects;
create policy "seller_avatars_owner_delete"
    on storage.objects
    for delete
    to authenticated
    using (
        bucket_id = 'seller-avatars'
        and split_part(name, '/', 1) = 'avatars'
        and split_part(name, '/', 2) = auth.uid()::text
    );

------------------------------------------------------------------------------
-- 8 — Public read RPC (no email; visibility + moderation gated)
------------------------------------------------------------------------------

create or replace function public.get_seller_public_profile(p_seller_id uuid)
returns table (
    user_id                  uuid,
    display_name             text,
    avatar_url               text,
    member_since             timestamptz,
    seller_type              text,
    active_listings_count    bigint,
    rating_average           numeric,
    rating_count             integer,
    review_count             integer,
    verified_phone           boolean,
    verified_email           boolean,
    verified_dealer          boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_count bigint;
begin
    if p_seller_id is null then
        return;
    end if;

    select count(*)::bigint
      into v_count
      from public.listings li
     where li.seller_id = p_seller_id
       and li.status = 'active';

    return query
    select
        sp.user_id,
        sp.display_name,
        sp.avatar_url,
        sp.member_since,
        sp.seller_type,
        v_count,
        sp.rating_average,
        sp.rating_count,
        sp.review_count,
        sp.verified_phone,
        sp.verified_email,
        sp.verified_dealer
    from public.seller_profiles sp
    where sp.user_id = p_seller_id
      and sp.public_visibility is true
      and sp.moderation_status = 'active';
end;
$$;

comment on function public.get_seller_public_profile(uuid) is
    'Safe public seller summary for clients. omits email and auth internals; filters hidden/suspended sellers.';

revoke all on function public.get_seller_public_profile(uuid) from public;
grant execute on function public.get_seller_public_profile(uuid) to anon;
grant execute on function public.get_seller_public_profile(uuid) to authenticated;

------------------------------------------------------------------------------
-- 9 — Backfill existing sellers (distinct seller_id from listings)
------------------------------------------------------------------------------

insert into public.seller_profiles (
    user_id,
    display_name,
    avatar_url,
    member_since
)
select distinct on (l.seller_id)
    l.seller_id,
    case
        when nullif(btrim(coalesce(u.raw_user_meta_data->>'full_name', '')), '') is null
            then null
        when char_length(btrim(u.raw_user_meta_data->>'full_name')) > 200
            then left(btrim(u.raw_user_meta_data->>'full_name'), 200)
        else btrim(u.raw_user_meta_data->>'full_name')
    end,
    case
        when nullif(btrim(coalesce(u.raw_user_meta_data->>'avatar_url', '')), '') is null
            then null
        when char_length(btrim(u.raw_user_meta_data->>'avatar_url')) > 2048
            then null
        else btrim(u.raw_user_meta_data->>'avatar_url')
    end,
    coalesce(u.created_at, now())
from public.listings l
join auth.users u on u.id = l.seller_id
where l.seller_id is not null
order by l.seller_id, l.created_at asc
on conflict (user_id) do nothing;
