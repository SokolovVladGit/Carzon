-- Carzon — owner-only listing details edit via a narrow RPC.
--
-- Goal: let an authenticated owner edit the mutable fields of their
-- own listing (title, make, model, year, price, mileage, type, city,
-- market region, contact phone, telegram username, whatsapp opt-in)
-- without opening a broad UPDATE RLS policy that would also allow
-- editing `seller_id`, `status`, `created_at`, or `cover_image_url`.
--
-- Design mirrors `public.set_listing_status`:
--   * SECURITY DEFINER function; body enforces
--       - caller is authenticated (auth.uid() is not null)
--       - all required inputs pass validation matching the table CHECK
--         constraints and the Flutter form validators
--       - the target row exists AND belongs to the caller (enforced
--         atomically inside the UPDATE's WHERE clause)
--   * `search_path` pinned to defuse search_path-based privilege
--     escalation.
--   * Only the whitelisted columns are updated. Columns intentionally
--     NOT touched: `id`, `seller_id`, `created_at`, `status`,
--     `cover_image_url`.
--   * Execute is revoked from PUBLIC/anon and granted only to the
--     `authenticated` role. No direct UPDATE policy is added; anon and
--     even generic authenticated callers cannot UPDATE
--     `public.listings` directly.
--
-- Not in scope here:
--   * cover image replacement (requires Storage cleanup semantics)
--   * permanent delete
--   * status change (already owned by `set_listing_status`)
--   * moderation / admin actions
--   * audit trail / updated_at column

create or replace function public.update_listing_details(
    p_listing_id        uuid,
    p_title             text,
    p_make              text,
    p_model             text,
    p_year              integer,
    p_price_eur         numeric,
    p_mileage_km        integer,
    p_type              text,
    p_city              text,
    p_market_region     text,
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

    -- Enum-like text fields: allowed values match the table CHECK
    -- constraints exactly.
    if p_type not in ('sale', 'exchange', 'both') then
        raise exception 'invalid listing type: %', p_type
            using errcode = '22023';
    end if;
    if p_market_region not in ('transnistria', 'moldova') then
        raise exception 'invalid market region: %', p_market_region
            using errcode = '22023';
    end if;

    -- Numeric ranges: aligned with listings_year_chk / _price_chk / _mileage_chk.
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

    -- Contact phone: required; ≥ 7 digits after stripping non-digits.
    -- Matches `listings_contact_phone_chk` and Flutter `kMinPhoneDigits`.
    if v_phone = '' then
        raise exception 'contact_phone is required'
            using errcode = '22023';
    end if;
    if length(regexp_replace(v_phone, '[^0-9]', '', 'g')) < 7 then
        raise exception 'invalid contact_phone'
            using errcode = '22023';
    end if;

    -- Telegram: optional. When provided, strip one leading `@` and
    -- validate 5–32 chars of [A-Za-z0-9_]. Matches
    -- `listings_telegram_username_chk`.
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
        -- Deliberately generic: do not reveal whether the listing
        -- exists but belongs to someone else vs. does not exist at all.
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return v_row;
end;
$$;

-- Lock down the function: Postgres grants EXECUTE to PUBLIC by default.
revoke all on function public.update_listing_details(
    uuid, text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean
) from public;
revoke all on function public.update_listing_details(
    uuid, text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean
) from anon;
grant execute on function public.update_listing_details(
    uuid, text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean
) to authenticated;
