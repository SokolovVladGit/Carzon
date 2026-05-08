-- Carzon — vehicle specs + free-text listing description (additive).
--
-- New nullable columns preserve legacy rows. RPCs create_listing_v2 /
-- update_listing_details_v2 gain trailing optional params (defaults).

-- ---------------------------------------------------------------------------
-- Columns + CHECK constraints
-- ---------------------------------------------------------------------------

alter table public.listings
    add column if not exists fuel_type text;

alter table public.listings
    add column if not exists engine_displacement_liters numeric(8, 4);

alter table public.listings
    add column if not exists engine_power_hp integer;

alter table public.listings
    add column if not exists drivetrain text;

alter table public.listings
    add column if not exists registration text;

alter table public.listings
    add column if not exists description text;

alter table public.listings
    drop constraint if exists listings_fuel_type_chk;

alter table public.listings
    add constraint listings_fuel_type_chk
        check (
            fuel_type is null
            or fuel_type in (
                'petrol',
                'diesel',
                'hybrid',
                'electric',
                'lpg',
                'cng',
                'other'
            )
        );

alter table public.listings
    drop constraint if exists listings_drivetrain_chk;

alter table public.listings
    add constraint listings_drivetrain_chk
        check (
            drivetrain is null
            or drivetrain in ('fwd', 'rwd', 'awd', 'four_wheel')
        );

alter table public.listings
    drop constraint if exists listings_engine_displacement_chk;

alter table public.listings
    add constraint listings_engine_displacement_chk
        check (
            engine_displacement_liters is null
            or (
                engine_displacement_liters > 0::numeric
                and engine_displacement_liters <= 30::numeric
            )
        );

alter table public.listings
    drop constraint if exists listings_engine_power_chk;

alter table public.listings
    add constraint listings_engine_power_chk
        check (
            engine_power_hp is null
            or (
                engine_power_hp > 0
                and engine_power_hp <= 3000
            )
        );

alter table public.listings
    drop constraint if exists listings_registration_len_chk;

alter table public.listings
    add constraint listings_registration_len_chk
        check (
            registration is null
            or char_length(trim(both from registration)) <= 200
        );

alter table public.listings
    drop constraint if exists listings_description_len_chk;

alter table public.listings
    add constraint listings_description_len_chk
        check (description is null or char_length(description) <= 8000);

comment on column public.listings.fuel_type is
    'Vehicle fuel category: petrol|diesel|hybrid|electric|lpg|cng|other.';
comment on column public.listings.engine_displacement_liters is
    'Engine size in liters (e.g. 2.0), NULL when unknown.';
comment on column public.listings.engine_power_hp is
    'Engine power in metric horsepower (л.с.), NULL when unknown.';
comment on column public.listings.drivetrain is
    'Drive layout: fwd|rwd|awd|four_wheel.';
comment on column public.listings.registration is
    'Where the vehicle is registered (distinct from marketplace market_region).';
comment on column public.listings.description is
    'Seller free-text description; max 8000 characters.';

-- ---------------------------------------------------------------------------
-- Replace create_listing_v2 (extended signature)
-- ---------------------------------------------------------------------------

drop function if exists public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text
);

create function public.create_listing_v2(
    p_title                        text,
    p_make                         text,
    p_model                        text,
    p_year                         integer,
    p_price_eur                    numeric,
    p_mileage_km                   integer,
    p_type                         text,
    p_market_region                text,
    p_city                         text,
    p_contact_phone                text,
    p_telegram_username            text,
    p_whatsapp_enabled             boolean,
    p_cover_image_url              text,
    p_price_currency               text default 'eur',
    p_image_urls                   text[] default null,
    p_storage_paths                text[] default null,
    p_body_type                    text default null,
    p_fuel_type                    text default null,
    p_engine_displacement_liters   numeric default null,
    p_engine_power_hp              integer default null,
    p_drivetrain                   text default null,
    p_registration                 text default null,
    p_description                  text default null
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row                      public.listings;
    v_title                    text := btrim(coalesce(p_title, ''));
    v_make                     text := btrim(coalesce(p_make, ''));
    v_model                    text := btrim(coalesce(p_model, ''));
    v_city                     text := btrim(coalesce(p_city, ''));
    v_phone                    text := btrim(coalesce(p_contact_phone, ''));
    v_telegram                 text := nullif(btrim(coalesce(p_telegram_username, '')), '');
    v_whatsapp_enabled         boolean := coalesce(p_whatsapp_enabled, false);
    v_currency                 text := lower(btrim(coalesce(p_price_currency, 'eur')));
    v_cover_legacy             text;
    v_cover_final              text;
    v_body_type                text;
    v_fuel_type                text;
    v_drivetrain               text;
    v_engine_l                 numeric(8, 4);
    v_power_hp                 integer;
    v_registration             text;
    v_description              text;

    v_gallery_urls             text[] := '{}';
    v_gallery_paths            text[] := '{}';

    i                          integer;
    u_raw                      text;
    u                          text;
    p_raw                      text;
    img_len                    integer;
    path_len                   integer;
    pair_count                 integer;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if v_currency not in ('eur', 'usd') then
        raise exception 'invalid price_currency'
            using errcode = '22023';
    end if;

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

    if p_body_type is null or btrim(coalesce(p_body_type, '')) = '' then
        v_body_type := null;
    else
        v_body_type := lower(btrim(p_body_type));
        if v_body_type not in (
            'sedan', 'hatchback', 'wagon', 'suv', 'coupe', 'convertible',
            'minivan', 'pickup', 'van', 'other'
        ) then
            raise exception 'invalid body_type: %', p_body_type
                using errcode = '22023';
        end if;
    end if;

    if p_fuel_type is null or btrim(coalesce(p_fuel_type, '')) = '' then
        v_fuel_type := null;
    else
        v_fuel_type := lower(btrim(p_fuel_type));
        if v_fuel_type not in (
            'petrol', 'diesel', 'hybrid', 'electric', 'lpg', 'cng', 'other'
        ) then
            raise exception 'invalid fuel_type: %', p_fuel_type
                using errcode = '22023';
        end if;
    end if;

    if p_drivetrain is null or btrim(coalesce(p_drivetrain, '')) = '' then
        v_drivetrain := null;
    else
        v_drivetrain := lower(btrim(p_drivetrain));
        if v_drivetrain not in ('fwd', 'rwd', 'awd', 'four_wheel') then
            raise exception 'invalid drivetrain: %', p_drivetrain
                using errcode = '22023';
        end if;
    end if;

    if p_engine_displacement_liters is null then
        v_engine_l := null;
    elsif p_engine_displacement_liters <= 0::numeric
        or p_engine_displacement_liters > 30::numeric then
        raise exception 'invalid engine displacement'
            using errcode = '22023';
    else
        v_engine_l := p_engine_displacement_liters::numeric(8, 4);
    end if;

    if p_engine_power_hp is null then
        v_power_hp := null;
    elsif p_engine_power_hp <= 0 or p_engine_power_hp > 3000 then
        raise exception 'invalid engine power'
            using errcode = '22023';
    else
        v_power_hp := p_engine_power_hp;
    end if;

    v_registration := nullif(btrim(coalesce(p_registration, '')), '');
    if v_registration is not null and length(v_registration) > 200 then
        raise exception 'registration is too long'
            using errcode = '22023';
    end if;

    v_description := nullif(btrim(coalesce(p_description, '')), '');
    if v_description is not null and length(v_description) > 8000 then
        raise exception 'description is too long'
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

    if p_cover_image_url is null then
        v_cover_legacy := null;
    else
        v_cover_legacy := btrim(p_cover_image_url);
        if v_cover_legacy = '' then
            v_cover_legacy := null;
        elsif v_cover_legacy !~* '^https?://' then
            raise exception 'invalid cover_image_url'
                using errcode = '22023';
        end if;
    end if;

    img_len := coalesce(array_length(p_image_urls, 1), 0);
    path_len := coalesce(array_length(p_storage_paths, 1), 0);

    if p_storage_paths is not null and path_len <> img_len then
        raise exception 'storage_paths length must match image_urls'
            using errcode = '22023';
    end if;

    pair_count := 0;

    for i in 1 .. img_len loop
        if p_storage_paths is not null then
            p_raw := coalesce(trim(p_storage_paths[i]::text), '');
        end if;

        u_raw := p_image_urls[i];
        if u_raw is null then
            raise exception 'image_urls slot must not be null'
                using errcode = '22023';
        end if;

        u := btrim(u_raw);
        if u = '' then
            raise exception 'image_urls slot must not be blank'
                using errcode = '22023';
        end if;
        if u !~* '^https?://' then
            raise exception 'invalid image url'
                using errcode = '22023';
        end if;

        pair_count := pair_count + 1;
        if pair_count > 9 then
            raise exception 'too many images'
                using errcode = '22023';
        end if;

        v_gallery_urls := array_append(v_gallery_urls, u);

        if p_storage_paths is not null then
            if p_raw = '' then
                v_gallery_paths := array_append(v_gallery_paths, null::text);
            else
                v_gallery_paths := array_append(v_gallery_paths, p_raw);
            end if;
        else
            v_gallery_paths := array_append(v_gallery_paths, null::text);
        end if;
    end loop;

    if pair_count > 0 then
        v_cover_final := v_gallery_urls[1];
    else
        v_cover_final := v_cover_legacy;
    end if;

    insert into public.listings (
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
        seller_id,
        contact_phone,
        telegram_username,
        whatsapp_enabled,
        cover_image_url
    )
    values (
        v_title,
        v_make,
        v_model,
        p_year,
        p_price_eur,
        v_currency,
        p_mileage_km,
        p_type,
        v_city,
        p_market_region,
        v_body_type,
        v_fuel_type,
        v_engine_l,
        v_power_hp,
        v_drivetrain,
        v_registration,
        v_description,
        auth.uid(),
        v_phone,
        v_telegram,
        v_whatsapp_enabled,
        v_cover_final
    )
    returning * into v_row;

    if pair_count > 0 then
        for i in 1 .. pair_count loop
            insert into public.listing_images (
                listing_id,
                public_url,
                storage_path,
                position
            )
            values (
                v_row.id,
                v_gallery_urls[i],
                nullif(btrim(coalesce(v_gallery_paths[i], '')), ''),
                i - 1
            );
        end loop;
    end if;

    return v_row;
end;
$$;

revoke all on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text
) from public;

revoke all on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text
) from anon;

grant execute on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text
) to authenticated;

-- ---------------------------------------------------------------------------
-- Replace update_listing_details_v2 (extended signature)
-- ---------------------------------------------------------------------------

drop function if exists public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text
);

create function public.update_listing_details_v2(
    p_listing_id                   uuid,
    p_title                        text,
    p_make                         text,
    p_model                        text,
    p_year                         integer,
    p_price_eur                    numeric,
    p_price_currency             text,
    p_mileage_km                   integer,
    p_type                         text,
    p_market_region                text,
    p_city                         text,
    p_contact_phone                text,
    p_telegram_username            text,
    p_whatsapp_enabled             boolean,
    p_body_type                    text default null,
    p_fuel_type                    text default null,
    p_engine_displacement_liters   numeric default null,
    p_engine_power_hp              integer default null,
    p_drivetrain                   text default null,
    p_registration                 text default null,
    p_description                  text default null
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row                       public.listings;
    v_title                     text := btrim(coalesce(p_title, ''));
    v_make                      text := btrim(coalesce(p_make, ''));
    v_model                     text := btrim(coalesce(p_model, ''));
    v_city                      text := btrim(coalesce(p_city, ''));
    v_phone                     text := btrim(coalesce(p_contact_phone, ''));
    v_telegram                  text := nullif(btrim(coalesce(p_telegram_username, '')), '');
    v_whatsapp_enabled          boolean := coalesce(p_whatsapp_enabled, false);
    v_currency                  text := lower(btrim(coalesce(p_price_currency, 'eur')));
    v_body_type                 text;
    v_fuel_type                 text;
    v_drivetrain                text;
    v_engine_l                  numeric(8, 4);
    v_power_hp                  integer;
    v_registration              text;
    v_description               text;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if v_title  = '' then raise exception 'title is required'         using errcode = '22023'; end if;
    if v_make   = '' then raise exception 'make is required'           using errcode = '22023'; end if;
    if v_model  = '' then raise exception 'model is required'           using errcode = '22023'; end if;
    if v_city   = '' then raise exception 'city is required'           using errcode = '22023'; end if;

    if p_type not in ('sale', 'exchange', 'both') then
        raise exception 'invalid listing type: %', p_type
            using errcode = '22023';
    end if;
    if p_market_region not in ('transnistria', 'moldova') then
        raise exception 'invalid market region: %', p_market_region
            using errcode = '22023';
    end if;

    if p_body_type is null or btrim(coalesce(p_body_type, '')) = '' then
        v_body_type := null;
    else
        v_body_type := lower(btrim(p_body_type));
        if v_body_type not in (
            'sedan', 'hatchback', 'wagon', 'suv', 'coupe', 'convertible',
            'minivan', 'pickup', 'van', 'other'
        ) then
            raise exception 'invalid body_type: %', p_body_type
                using errcode = '22023';
        end if;
    end if;

    if p_fuel_type is null or btrim(coalesce(p_fuel_type, '')) = '' then
        v_fuel_type := null;
    else
        v_fuel_type := lower(btrim(p_fuel_type));
        if v_fuel_type not in (
            'petrol', 'diesel', 'hybrid', 'electric', 'lpg', 'cng', 'other'
        ) then
            raise exception 'invalid fuel_type: %', p_fuel_type
                using errcode = '22023';
        end if;
    end if;

    if p_drivetrain is null or btrim(coalesce(p_drivetrain, '')) = '' then
        v_drivetrain := null;
    else
        v_drivetrain := lower(btrim(p_drivetrain));
        if v_drivetrain not in ('fwd', 'rwd', 'awd', 'four_wheel') then
            raise exception 'invalid drivetrain: %', p_drivetrain
                using errcode = '22023';
        end if;
    end if;

    if p_engine_displacement_liters is null then
        v_engine_l := null;
    elsif p_engine_displacement_liters <= 0::numeric
        or p_engine_displacement_liters > 30::numeric then
        raise exception 'invalid engine displacement'
            using errcode = '22023';
    else
        v_engine_l := p_engine_displacement_liters::numeric(8, 4);
    end if;

    if p_engine_power_hp is null then
        v_power_hp := null;
    elsif p_engine_power_hp <= 0 or p_engine_power_hp > 3000 then
        raise exception 'invalid engine power'
            using errcode = '22023';
    else
        v_power_hp := p_engine_power_hp;
    end if;

    v_registration := nullif(btrim(coalesce(p_registration, '')), '');
    if v_registration is not null and length(v_registration) > 200 then
        raise exception 'registration is too long'
            using errcode = '22023';
    end if;

    v_description := nullif(btrim(coalesce(p_description, '')), '');
    if v_description is not null and length(v_description) > 8000 then
        raise exception 'description is too long'
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
       set title                       = v_title,
           make                        = v_make,
           model                       = v_model,
           year                        = p_year,
           price_eur                   = p_price_eur,
           price_currency              = v_currency,
           mileage_km                  = p_mileage_km,
           type                        = p_type,
           city                        = v_city,
           market_region               = p_market_region,
           body_type                   = v_body_type,
           fuel_type                   = v_fuel_type,
           engine_displacement_liters  = v_engine_l,
           engine_power_hp             = v_power_hp,
           drivetrain                  = v_drivetrain,
           registration                = v_registration,
           description                 = v_description,
           contact_phone               = v_phone,
           telegram_username           = v_telegram,
           whatsapp_enabled            = v_whatsapp_enabled
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
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text
) from public;

revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text
) from anon;

grant execute on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text
) to authenticated;
