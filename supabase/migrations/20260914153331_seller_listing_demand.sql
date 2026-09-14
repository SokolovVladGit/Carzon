-- Carzon — Phase 5B: Professional Seller Buyer Demand (live matching).
--
-- Unique external accounts whose current saved searches match the caller's
-- active listings. k=5 suppression. Dealer-only. No materialization.

------------------------------------------------------------------------------
-- 1 — Per-listing demand
------------------------------------------------------------------------------

create or replace function public.get_my_seller_listing_demand()
returns table (
    listing_id uuid,
    matching_users integer,
    is_suppressed boolean
)
language plpgsql
stable
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

    perform public.ensure_seller_profile(v_uid);

    select sp.seller_type
      into v_type
      from public.seller_profiles sp
     where sp.user_id = v_uid;

    if v_type is distinct from 'dealer' then
        raise exception 'seller demand requires professional seller'
            using errcode = '42501';
    end if;

    return query
    select x.listing_id,
           case
               when x.n = 0 then 0
               when x.n < 5 then null::integer
               else x.n
           end,
           (x.n between 1 and 4)
      from (
            select l.id as listing_id,
                   count(u.user_id)::integer as n
              from public.listings l
              left join (
                    select distinct ss.user_id
                      from public.saved_searches ss
                     where ss.user_id is distinct from v_uid
              ) u
                on exists (
                    select 1
                      from public.saved_searches ss
                     where ss.user_id = u.user_id
                       and public.listing_matches_saved_discovery_criteria(
                               l,
                               ss.criteria
                           )
                )
             where l.seller_id = v_uid
               and l.status = 'active'
             group by l.id
      ) x
     order by x.listing_id;
end;
$$;

comment on function public.get_my_seller_listing_demand() is
    'Per active listing: distinct external saved-search users matching via '
    'listing_matches_saved_discovery_criteria. k=5 suppression. Dealer-only. '
    'auth.uid() only. Point-in-time. Does not count saved-search rows.';

------------------------------------------------------------------------------
-- 2 — Portfolio demand
------------------------------------------------------------------------------

create or replace function public.get_my_seller_inventory_demand()
returns table (
    matching_users integer,
    is_suppressed boolean
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_type text;
    v_n integer;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    perform public.ensure_seller_profile(v_uid);

    select sp.seller_type
      into v_type
      from public.seller_profiles sp
     where sp.user_id = v_uid;

    if v_type is distinct from 'dealer' then
        raise exception 'seller demand requires professional seller'
            using errcode = '42501';
    end if;

    select count(*)::integer
      into v_n
      from (
            select ss.user_id
              from public.saved_searches ss
             where ss.user_id is distinct from v_uid
               and exists (
                    select 1
                      from public.listings l
                     where l.seller_id = v_uid
                       and l.status = 'active'
                       and public.listing_matches_saved_discovery_criteria(
                               l,
                               ss.criteria
                           )
               )
             group by ss.user_id
      ) u;

    return query
    select case
               when coalesce(v_n, 0) = 0 then 0
               when v_n < 5 then null::integer
               else v_n
           end,
           (coalesce(v_n, 0) between 1 and 4);
end;
$$;

comment on function public.get_my_seller_inventory_demand() is
    'Distinct external saved-search users matching at least one of the caller''s '
    'active listings. k=5 suppression. Dealer-only. auth.uid() only. '
    'Zero active listings → visible zero.';

revoke all on function public.get_my_seller_listing_demand() from public;
revoke all on function public.get_my_seller_listing_demand() from anon;
grant execute on function public.get_my_seller_listing_demand()
    to authenticated;

revoke all on function public.get_my_seller_inventory_demand() from public;
revoke all on function public.get_my_seller_inventory_demand() from anon;
grant execute on function public.get_my_seller_inventory_demand()
    to authenticated;
