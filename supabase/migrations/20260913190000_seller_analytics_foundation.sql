-- Carzon — Seller Analytics Phase 1 foundation.
--
-- Adds:
--   * listings.sold_at + canonical sold lifecycle in set_listing_status
--   * get_my_seller_context / set_my_seller_type (self-service mode only;
--     verified_dealer is never self-set)
--   * seller-owned analytics RPCs over existing product tables (Option B)
--
-- Periods: 7 / 30 / 90 Moldova-local dates (Europe/Chisinau).
-- Eligible listings: current status active | sold (hidden/archived excluded).
-- Inquiry: first buyer message in a listing conversation, not thread creation.
-- Favorites: current rows only. No event history.
--
-- No new indexes: listings_seller_id_idx, listing_view_daily PK,
-- favorites_listing_id_idx, conversations_listing_id_idx, and
-- messages_conversation_created_at_idx cover the 10–1000 listing / 90-day
-- join paths. No generic analytics event table.

------------------------------------------------------------------------------
-- 1 — sold_at
------------------------------------------------------------------------------

alter table public.listings
    add column if not exists sold_at timestamptz;

alter table public.listings
    drop constraint if exists listings_sold_at_status_chk;

alter table public.listings
    add constraint listings_sold_at_status_chk
        check (sold_at is null or status = 'sold');

comment on column public.listings.sold_at is
    'Set by set_listing_status on non-sold → sold. Cleared when leaving sold. '
    'Not backfilled for historical sold rows.';

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
    transmission_type,
    variant,
    registration,
    description,
    created_at,
    sold_at,
    status,
    cover_image_url,
    seller_id,
    vin_status,
    view_count
) on public.listings to anon, authenticated;

------------------------------------------------------------------------------
-- 2 — set_listing_status sold lifecycle
------------------------------------------------------------------------------

create or replace function public.set_listing_status(
    p_listing_id uuid,
    p_status     text
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row public.listings;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_status not in ('active', 'hidden', 'sold', 'archived') then
        raise exception 'invalid listing status: %', p_status
            using errcode = '22023';
    end if;

    update public.listings
       set status = p_status,
           sold_at = case
               when p_status = 'sold' and status is distinct from 'sold'
                   then now()
               when p_status is distinct from 'sold' and status = 'sold'
                   then null
               else sold_at
           end
     where id = p_listing_id
       and seller_id = auth.uid()
    returning * into v_row;

    if not found then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return v_row;
end;
$$;

revoke all on function public.set_listing_status(uuid, text) from public;
revoke all on function public.set_listing_status(uuid, text) from anon;
grant execute on function public.set_listing_status(uuid, text) to authenticated;

------------------------------------------------------------------------------
-- 3 — seller mode / context
------------------------------------------------------------------------------

create or replace function public.get_my_seller_context()
returns table (
    seller_type text,
    verified_dealer boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    perform public.ensure_seller_profile(v_uid);

    return query
    select sp.seller_type,
           sp.verified_dealer
      from public.seller_profiles sp
     where sp.user_id = v_uid;
end;
$$;

comment on function public.get_my_seller_context() is
    'Authenticated caller reads own seller_type and verified_dealer. '
    'Does not change get_my_seller_profile() return shape.';

create or replace function public.set_my_seller_type(p_seller_type text)
returns table (
    seller_type text,
    verified_dealer boolean
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_type text;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    v_type := lower(btrim(coalesce(p_seller_type, '')));
    if v_type not in ('private', 'dealer') then
        raise exception 'invalid seller type: %', p_seller_type
            using errcode = '22023';
    end if;

    perform public.ensure_seller_profile(v_uid);

    update public.seller_profiles
       set seller_type = v_type
     where user_id = v_uid;

    return query
    select sp.seller_type,
           sp.verified_dealer
      from public.seller_profiles sp
     where sp.user_id = v_uid;
end;
$$;

comment on function public.set_my_seller_type(text) is
    'Self-service private↔dealer mode. Updates only seller_type for auth.uid(). '
    'Never writes verified_dealer.';

revoke all on function public.get_my_seller_context() from public;
revoke all on function public.get_my_seller_context() from anon;
grant execute on function public.get_my_seller_context() to authenticated;

revoke all on function public.set_my_seller_type(text) from public;
revoke all on function public.set_my_seller_type(text) from anon;
grant execute on function public.set_my_seller_type(text) to authenticated;

------------------------------------------------------------------------------
-- 4 — analytics RPCs
------------------------------------------------------------------------------

create or replace function public.get_my_seller_analytics_summary(
    p_period_days integer
)
returns table (
    seller_type text,
    verified_dealer boolean,
    active_count integer,
    sold_count integer,
    period_views integer,
    current_favorites integer,
    period_inquiries integer,
    conversion_percent numeric
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_today date;
    v_start date;
    v_active integer := 0;
    v_sold integer := 0;
    v_views integer := 0;
    v_favs integer := 0;
    v_inquiries integer := 0;
    v_type text := 'private';
    v_verified boolean := false;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_period_days is distinct from 7
       and p_period_days is distinct from 30
       and p_period_days is distinct from 90 then
        raise exception 'invalid analytics period: %', p_period_days
            using errcode = '22023';
    end if;

    perform public.ensure_seller_profile(v_uid);

    select sp.seller_type, sp.verified_dealer
      into v_type, v_verified
      from public.seller_profiles sp
     where sp.user_id = v_uid;

    v_today := (now() at time zone 'Europe/Chisinau')::date;
    v_start := v_today - (p_period_days - 1);

    select count(*) filter (where l.status = 'active')::integer,
           count(*) filter (where l.status = 'sold')::integer
      into v_active, v_sold
      from public.listings l
     where l.seller_id = v_uid
       and l.status in ('active', 'sold');

    select coalesce(sum(d.view_count), 0)::integer
      into v_views
      from public.listing_view_daily d
      join public.listings l on l.id = d.listing_id
     where l.seller_id = v_uid
       and l.status in ('active', 'sold')
       and d.view_date between v_start and v_today;

    select count(*)::integer
      into v_favs
      from public.favorites f
      join public.listings l on l.id = f.listing_id
     where l.seller_id = v_uid
       and l.status = 'active';

    select count(*)::integer
      into v_inquiries
      from (
            select c.id
              from public.conversations c
              join public.listings l on l.id = c.listing_id
              join public.messages m
                on m.conversation_id = c.id
               and m.sender_id = c.buyer_id
             where l.seller_id = v_uid
               and l.status in ('active', 'sold')
               and c.conversation_kind = 'listing'
             group by c.id
            having (min(m.created_at) at time zone 'Europe/Chisinau')::date
                   between v_start and v_today
           ) q;

    return query
    select v_type,
           v_verified,
           coalesce(v_active, 0),
           coalesce(v_sold, 0),
           coalesce(v_views, 0),
           coalesce(v_favs, 0),
           coalesce(v_inquiries, 0),
           case
               when coalesce(v_views, 0) = 0 then null::numeric
               else (coalesce(v_inquiries, 0)::numeric * 100)
                    / coalesce(v_views, 0)::numeric
           end;
end;
$$;

comment on function public.get_my_seller_analytics_summary(integer) is
    'Seller-owned analytics summary for 7/30/90 Moldova-local days. '
    'auth.uid() only. Period views from listing_view_daily, not listings.view_count.';

create or replace function public.get_my_seller_analytics_daily(
    p_period_days integer
)
returns table (
    metric_date date,
    views integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_today date;
    v_start date;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_period_days is distinct from 7
       and p_period_days is distinct from 30
       and p_period_days is distinct from 90 then
        raise exception 'invalid analytics period: %', p_period_days
            using errcode = '22023';
    end if;

    v_today := (now() at time zone 'Europe/Chisinau')::date;
    v_start := v_today - (p_period_days - 1);

    return query
    select gs.metric_date::date,
           coalesce(sum(d.view_count), 0)::integer
      from generate_series(v_start, v_today, interval '1 day') as gs(metric_date)
      left join public.listings l
        on l.seller_id = v_uid
       and l.status in ('active', 'sold')
      left join public.listing_view_daily d
        on d.listing_id = l.id
       and d.view_date = gs.metric_date::date
     group by gs.metric_date
     order by gs.metric_date;
end;
$$;

comment on function public.get_my_seller_analytics_daily(integer) is
    'Zero-filled Moldova-local daily view series for the caller''s active+sold listings.';

create or replace function public.get_my_seller_analytics_listings(
    p_period_days integer
)
returns table (
    listing_id uuid,
    title text,
    status text,
    created_at timestamptz,
    sold_at timestamptz,
    make text,
    model text,
    year integer,
    period_views integer,
    current_favorites integer,
    period_inquiries integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_today date;
    v_start date;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_period_days is distinct from 7
       and p_period_days is distinct from 30
       and p_period_days is distinct from 90 then
        raise exception 'invalid analytics period: %', p_period_days
            using errcode = '22023';
    end if;

    v_today := (now() at time zone 'Europe/Chisinau')::date;
    v_start := v_today - (p_period_days - 1);

    -- Order: active before sold; then period_views, period_inquiries,
    -- current_favorites desc; then created_at desc, listing_id.
    return query
    with eligible as (
        select l.id,
               l.title,
               l.status,
               l.created_at,
               l.sold_at,
               l.make,
               l.model,
               l.year
          from public.listings l
         where l.seller_id = v_uid
           and l.status in ('active', 'sold')
    ),
    views as (
        select d.listing_id,
               coalesce(sum(d.view_count), 0)::integer as period_views
          from public.listing_view_daily d
          join eligible e on e.id = d.listing_id
         where d.view_date between v_start and v_today
         group by d.listing_id
    ),
    favs as (
        select f.listing_id,
               count(*)::integer as current_favorites
          from public.favorites f
          join eligible e on e.id = f.listing_id
         group by f.listing_id
    ),
    inquiries as (
        select x.listing_id,
               count(*)::integer as period_inquiries
          from (
                select c.listing_id
                  from public.conversations c
                  join eligible e on e.id = c.listing_id
                  join public.messages m
                    on m.conversation_id = c.id
                   and m.sender_id = c.buyer_id
                 where c.conversation_kind = 'listing'
                 group by c.id, c.listing_id
                having (min(m.created_at) at time zone 'Europe/Chisinau')::date
                       between v_start and v_today
               ) x
         group by x.listing_id
    )
    select e.id,
           e.title,
           e.status,
           e.created_at,
           e.sold_at,
           e.make,
           e.model,
           e.year,
           coalesce(v.period_views, 0),
           coalesce(f.current_favorites, 0),
           coalesce(i.period_inquiries, 0)
      from eligible e
      left join views v on v.listing_id = e.id
      left join favs f on f.listing_id = e.id
      left join inquiries i on i.listing_id = e.id
     order by case when e.status = 'active' then 0 else 1 end,
              coalesce(v.period_views, 0) desc,
              coalesce(i.period_inquiries, 0) desc,
              coalesce(f.current_favorites, 0) desc,
              e.created_at desc,
              e.id;
end;
$$;

comment on function public.get_my_seller_analytics_listings(integer) is
    'Per-listing seller analytics for active+sold inventory. '
    'Order: active, then period_views/inquiries/favorites desc, created_at desc, id.';

revoke all on function public.get_my_seller_analytics_summary(integer) from public;
revoke all on function public.get_my_seller_analytics_summary(integer) from anon;
grant execute on function public.get_my_seller_analytics_summary(integer)
    to authenticated;

revoke all on function public.get_my_seller_analytics_daily(integer) from public;
revoke all on function public.get_my_seller_analytics_daily(integer) from anon;
grant execute on function public.get_my_seller_analytics_daily(integer)
    to authenticated;

revoke all on function public.get_my_seller_analytics_listings(integer) from public;
revoke all on function public.get_my_seller_analytics_listings(integer) from anon;
grant execute on function public.get_my_seller_analytics_listings(integer)
    to authenticated;

revoke all on table public.listing_view_daily from anon;
revoke all on table public.listing_view_daily from authenticated;
revoke all on table public.listing_view_dedupe from anon;
revoke all on table public.listing_view_dedupe from authenticated;
