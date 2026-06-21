-- Carzon — filter-alert criteria parity for drivetrain discovery filter.
--
-- Mirrors Flutter discovery filters on listings.drivetrain.
-- Missing/empty JSON keys impose no constraint.
-- DB wire values (e.g. four_wheel) match listing_discovery_criteria_json.dart.

create or replace function public.listing_matches_saved_discovery_criteria(
    p_listing public.listings,
    p_criteria jsonb
)
returns boolean
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
    v_sv text;
    v_sv_int int;
    v_search text;
    v_search_esc text;
    v_make text;
    v_model text;
    v_city text;
    v_min_year int;
    v_max_year int;
    v_min_price numeric;
    v_max_price numeric;
    v_max_mileage int;
    v_mr text;
    v_body text;
    v_fuel text;
    v_trans text;
    v_drive text;
    v_pcf text;
    v_types jsonb;
begin
    if p_criteria is null or jsonb_typeof(p_criteria) <> 'object' then
        return false;
    end if;

    if p_criteria ? 'schemaVersion' then
        v_sv := p_criteria->>'schemaVersion';
        if v_sv is not null and btrim(v_sv) <> '' then
            begin
                v_sv_int := v_sv::int;
            exception
                when others then
                    return false;
            end;
            if v_sv_int is distinct from 1 then
                return false;
            end if;
        end if;
    end if;

    v_search := trim(both from coalesce(p_criteria->>'search', ''));
    if v_search <> '' then
        v_search_esc := replace(replace(replace(v_search, '\', '\\'), '%', '\%'), '_', '\_');
        if not (
            coalesce(p_listing.title, '') ilike ('%' || v_search_esc || '%') escape '\'
            or coalesce(p_listing.make, '') ilike ('%' || v_search_esc || '%') escape '\'
            or coalesce(p_listing.model, '') ilike ('%' || v_search_esc || '%') escape '\'
        ) then
            return false;
        end if;
    end if;

    v_make := trim(both from coalesce(p_criteria->>'make', ''));
    if v_make <> '' then
        if p_listing.make is null or p_listing.make not ilike ('%' || v_make || '%') then
            return false;
        end if;
    end if;

    v_model := trim(both from coalesce(p_criteria->>'model', ''));
    if v_model <> '' then
        if p_listing.model is null or p_listing.model not ilike ('%' || v_model || '%') then
            return false;
        end if;
    end if;

    v_city := trim(both from coalesce(p_criteria->>'city', ''));
    if v_city <> '' then
        if p_listing.city is null or p_listing.city not ilike ('%' || v_city || '%') then
            return false;
        end if;
    end if;

    if p_criteria ? 'minYear' and jsonb_typeof(p_criteria->'minYear') <> 'null' then
        begin
            v_min_year := (p_criteria->>'minYear')::int;
            if p_listing.year is null or p_listing.year < v_min_year then
                return false;
            end if;
        exception
            when others then
                null;
        end;
    end if;

    if p_criteria ? 'maxYear' and jsonb_typeof(p_criteria->'maxYear') <> 'null' then
        begin
            v_max_year := (p_criteria->>'maxYear')::int;
            if p_listing.year is null or p_listing.year > v_max_year then
                return false;
            end if;
        exception
            when others then
                null;
        end;
    end if;

    if p_criteria ? 'minPrice' and jsonb_typeof(p_criteria->'minPrice') <> 'null' then
        begin
            v_min_price := (p_criteria->>'minPrice')::numeric;
            if p_listing.price_eur is null or p_listing.price_eur < v_min_price then
                return false;
            end if;
        exception
            when others then
                null;
        end;
    end if;

    if p_criteria ? 'maxPrice' and jsonb_typeof(p_criteria->'maxPrice') <> 'null' then
        begin
            v_max_price := (p_criteria->>'maxPrice')::numeric;
            if p_listing.price_eur is null or p_listing.price_eur > v_max_price then
                return false;
            end if;
        exception
            when others then
                null;
        end;
    end if;

    if p_criteria ? 'maxMileage' and jsonb_typeof(p_criteria->'maxMileage') <> 'null' then
        begin
            v_max_mileage := (p_criteria->>'maxMileage')::int;
            if p_listing.mileage_km is null or p_listing.mileage_km > v_max_mileage then
                return false;
            end if;
        exception
            when others then
                null;
        end;
    end if;

    v_mr := lower(trim(both from coalesce(p_criteria->>'marketRegion', '')));
    if v_mr <> '' and v_mr <> 'both' then
        if lower(trim(both from coalesce(p_listing.market_region, ''))) is distinct from v_mr then
            return false;
        end if;
    end if;

    v_body := trim(both from coalesce(p_criteria->>'bodyType', ''));
    if v_body <> '' then
        if p_listing.body_type is null
           or lower(trim(both from p_listing.body_type)) is distinct from lower(v_body) then
            return false;
        end if;
    end if;

    v_fuel := trim(both from coalesce(p_criteria->>'fuelType', ''));
    if v_fuel <> '' then
        if p_listing.fuel_type is null
           or lower(trim(both from p_listing.fuel_type)) is distinct from lower(v_fuel) then
            return false;
        end if;
    end if;

    v_trans := trim(both from coalesce(p_criteria->>'transmissionType', ''));
    if v_trans <> '' then
        if p_listing.transmission_type is null
           or lower(trim(both from p_listing.transmission_type)) is distinct from lower(v_trans) then
            return false;
        end if;
    end if;

    v_drive := trim(both from coalesce(p_criteria->>'drivetrain', ''));
    if v_drive <> '' then
        if p_listing.drivetrain is null
           or lower(trim(both from p_listing.drivetrain)) is distinct from lower(v_drive) then
            return false;
        end if;
    end if;

    v_types := p_criteria->'typeIn';
    if v_types is not null and jsonb_typeof(v_types) = 'array' then
        begin
            if jsonb_array_length(v_types) > 0 then
                if not exists (
                    select 1
                      from jsonb_array_elements_text(v_types) as elem(value)
                     where lower(trim(both from coalesce(p_listing.type, '')))
                         = lower(trim(both from elem.value))
                ) then
                    return false;
                end if;
            end if;
        exception
            when others then
                return false;
        end;
    end if;

    v_pcf := lower(trim(both from coalesce(p_criteria->>'priceCurrencyFilter', '')));
    if v_pcf <> '' and v_pcf <> 'any' then
        if lower(trim(both from coalesce(p_listing.price_currency, ''))) is distinct from v_pcf then
            return false;
        end if;
    end if;

    return true;
end;
$$;

comment on function public.listing_matches_saved_discovery_criteria(public.listings, jsonb) is
    'JSON criteria vs listings row — mirrors feed filters incl. fuelType/transmissionType/drivetrain; free-text search matches title OR make OR model; sort ignored; internal only.';

create index if not exists listings_feed_active_region_drivetrain_created_idx
    on public.listings (market_region, drivetrain, created_at desc)
    where status = 'active';
