-- Carzon — listing creation via SECURITY DEFINER RPC (no direct client INSERT).
--
-- Replaces the broad `listings_insert_own` RLS policy with a narrow
-- `public.create_listing(...)` function that:
--   * requires an authenticated caller (auth.uid() is not null)
--   * sets seller_id = auth.uid() — the client cannot supply or override it
--   * validates inputs consistently with `update_listing_details` and table CHECKs
--   * inserts into public.listings and returns the new row (status/created_at use
--     table defaults: active / now())
--
-- Seeds and demo SQL run as elevated roles and bypass RLS; dropping the INSERT
-- policy does not affect them.

create or replace function public.create_listing(
    p_title             text,
    p_make              text,
    p_model             text,
    p_year              integer,
    p_price_eur         numeric,
    p_mileage_km        integer,
    p_type              text,
    p_market_region     text,
    p_city              text,
    p_contact_phone     text,
    p_telegram_username text,
    p_whatsapp_enabled  boolean,
    p_cover_image_url   text
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row              public.listings;
    v_title            text := btrim(coalesce(p_title, ''));
    v_make             text := btrim(coalesce(p_make, ''));
    v_model            text := btrim(coalesce(p_model, ''));
    v_city             text := btrim(coalesce(p_city, ''));
    v_phone            text := btrim(coalesce(p_contact_phone, ''));
    v_telegram         text := nullif(btrim(coalesce(p_telegram_username, '')), '');
    v_whatsapp_enabled boolean := coalesce(p_whatsapp_enabled, false);
    v_cover_url        text;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    -- Required text fields.
    if v_title = '' then
        raise exception 'title is required'
            using errcode = '22023';
    end if;
    if v_make = '' then
        raise exception 'make is required'
            using errcode = '22023';
    end if;
    if v_model = '' then
        raise exception 'model is required'
            using errcode = '22023';
    end if;
    if v_city = '' then
        raise exception 'city is required'
            using errcode = '22023';
    end if;

    if p_type not in ('sale', 'exchange', 'both') then
        raise exception 'invalid listing type: %', p_type
            using errcode = '22023';
    end if;
    if p_market_region not in ('transnistria', 'moldova') then
        raise exception 'invalid market region: %', p_market_region
            using errcode = '22023';
    end if;

    if p_year is null or p_year < 1900 or p_year > 2100 then
        raise exception 'invalid year: %', p_year
            using errcode = '22023';
    end if;
    if p_price_eur is null or p_price_eur < 0 then
        raise exception 'invalid price'
            using errcode = '22023';
    end if;
    if p_mileage_km is null or p_mileage_km < 0 then
        raise exception 'invalid mileage'
            using errcode = '22023';
    end if;

    if v_phone = '' then
        raise exception 'contact_phone is required'
            using errcode = '22023';
    end if;
    if length(regexp_replace(v_phone, '[^0-9]', '', 'g')) < 7 then
        raise exception 'invalid contact_phone'
            using errcode = '22023';
    end if;

    if v_telegram is not null then
        if left(v_telegram, 1) = '@' then
            v_telegram := substring(v_telegram from 2);
        end if;
        if v_telegram !~ '^[A-Za-z0-9_]{5,32}$' then
            raise exception 'invalid telegram_username'
                using errcode = '22023';
        end if;
    end if;

    -- Optional cover: NULL / omitted means no image; non-null must be http(s).
    if p_cover_image_url is null then
        v_cover_url := null;
    else
        v_cover_url := btrim(p_cover_image_url);
        if v_cover_url = '' then
            v_cover_url := null;
        elsif v_cover_url !~* '^https?://' then
            raise exception 'invalid cover_image_url'
                using errcode = '22023';
        end if;
    end if;

    insert into public.listings (
        title,
        make,
        model,
        year,
        price_eur,
        mileage_km,
        type,
        city,
        market_region,
        seller_id,
        contact_phone,
        telegram_username,
        whatsapp_enabled,
        cover_image_url
    ) values (
        v_title,
        v_make,
        v_model,
        p_year,
        p_price_eur,
        p_mileage_km,
        p_type,
        v_city,
        p_market_region,
        auth.uid(),
        v_phone,
        v_telegram,
        v_whatsapp_enabled,
        v_cover_url
    )
    returning * into v_row;

    return v_row;
end;
$$;

revoke all on function public.create_listing(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean, text
) from public;
revoke all on function public.create_listing(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean, text
) from anon;
grant execute on function public.create_listing(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean, text
) to authenticated;

-- RPC-only mutations: authenticated clients must not INSERT directly.
drop policy if exists "listings_insert_own" on public.listings;
