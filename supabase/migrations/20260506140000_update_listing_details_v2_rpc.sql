-- Carzon — Phase 4A owner-only listing details edit WITH price currency (`price_currency`).
--
-- Complements legacy `update_listing_details` with a DISTINCT PostgREST-exposed signature
-- (adds `p_price_currency`), so Flutter can migrate without breaking callers that still
-- invoke the 13-arg legacy RPC until Edit v2 is wired.
--
-- Same security posture as `update_listing_details`:
--   * SECURITY DEFINER; `search_path` pinned (public + pg_temp)
--   * authenticated only; validates inputs; UPDATE only when `seller_id = auth.uid()`
--   * does NOT mutate: `seller_id`, `cover_image_url`, `status`, `created_at`,
--     or any `listing_images` rows

create or replace function public.update_listing_details_v2(
    p_listing_id        uuid,
    p_title             text,
    p_make              text,
    p_model             text,
    p_year              integer,
    p_price_eur         numeric,
    p_price_currency    text,
    p_mileage_km        integer,
    p_type              text,
    p_market_region     text,
    p_city              text,
    p_contact_phone     text,
    p_telegram_username text,
    p_whatsapp_enabled  boolean
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row               public.listings;
    v_title             text    := btrim(coalesce(p_title, ''));
    v_make              text    := btrim(coalesce(p_make, ''));
    v_model             text    := btrim(coalesce(p_model, ''));
    v_city              text    := btrim(coalesce(p_city, ''));
    v_phone             text    := btrim(coalesce(p_contact_phone, ''));
    v_telegram          text    := nullif(btrim(coalesce(p_telegram_username, '')), '');
    v_whatsapp_enabled  boolean := coalesce(p_whatsapp_enabled, false);
    v_currency          text    := lower(btrim(coalesce(p_price_currency, 'eur')));
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    -- Required text fields.
    if v_title  = '' then raise exception 'title is required'         using errcode = '22023'; end if;
    if v_make   = '' then raise exception 'make is required'          using errcode = '22023'; end if;
    if v_model  = '' then raise exception 'model is required'         using errcode = '22023'; end if;
    if v_city   = '' then raise exception 'city is required'          using errcode = '22023'; end if;

    if p_type not in ('sale', 'exchange', 'both') then
        raise exception 'invalid listing type: %', p_type
            using errcode = '22023';
    end if;
    if p_market_region not in ('transnistria', 'moldova') then
        raise exception 'invalid market region: %', p_market_region
            using errcode = '22023';
    end if;

    if v_currency not in ('eur', 'usd') then
        raise exception 'invalid price_currency'
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

    update public.listings
       set title             = v_title,
           make              = v_make,
           model             = v_model,
           year              = p_year,
           price_eur         = p_price_eur,
           price_currency    = v_currency,
           mileage_km        = p_mileage_km,
           type              = p_type,
           city              = v_city,
           market_region     = p_market_region,
           contact_phone     = v_phone,
           telegram_username = v_telegram,
           whatsapp_enabled  = v_whatsapp_enabled
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

revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean
) from public;
revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean
) from anon;
grant execute on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean
) to authenticated;
