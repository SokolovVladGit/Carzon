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
