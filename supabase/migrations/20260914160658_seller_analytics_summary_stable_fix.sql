-- Carzon — Seller Analytics repair: keep summary RPC STABLE.
--
-- Drops the seller-profile write helper from the read-only summary function.
-- Profile is selected if present; missing row keeps private / unverified.
-- Analytics semantics and return contract unchanged.

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

    select sp.seller_type, sp.verified_dealer
      into v_type, v_verified
      from public.seller_profiles sp
     where sp.user_id = v_uid;

    -- SELECT INTO nulls targets when no row exists; restore read-only defaults.
    if not found then
        v_type := 'private';
        v_verified := false;
    end if;

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
    'auth.uid() only. Period views from listing_view_daily, not listings.view_count. '
    'Read-only STABLE. Reads seller_profiles if present; otherwise private/unverified. '
    'Does not create seller_profiles.';

revoke all on function public.get_my_seller_analytics_summary(integer) from public;
revoke all on function public.get_my_seller_analytics_summary(integer) from anon;
grant execute on function public.get_my_seller_analytics_summary(integer)
    to authenticated;
