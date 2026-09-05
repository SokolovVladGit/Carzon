-- Carzon — seller-authored listing.variant + plug_in_hybrid fuel value.
--
-- Additive only. No catalog changes. No listing backfill.
-- Official-data identity remains listings.make / model / year.

alter table public.listings
    add column if not exists variant text;

alter table public.listings
    drop constraint if exists listings_variant_len_chk;

alter table public.listings
    add constraint listings_variant_len_chk
        check (
            variant is null
            or char_length(trim(both from variant)) <= 80
        );

comment on column public.listings.variant is
    'Optional seller-authored derivative / marketed version. Not make, model, body, fuel, trim taxonomy, or official-data identity.';

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
                'plug_in_hybrid',
                'electric',
                'lpg',
                'cng',
                'other'
            )
        );

comment on column public.listings.fuel_type is
    'Vehicle fuel category: petrol|diesel|hybrid|plug_in_hybrid|electric|lpg|cng|other.';

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
    status,
    cover_image_url,
    seller_id,
    vin_status,
    view_count
) on public.listings to anon, authenticated;

create or replace function public.carzon_enforce_user_text()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
    if tg_table_name = 'listings' then
        if tg_op = 'INSERT' or new.title is distinct from old.title then
            perform carzon_private.assert_user_text_allowed(new.title, 'listing_title');
        end if;
        if tg_op = 'INSERT' or new.description is distinct from old.description then
            perform carzon_private.assert_user_text_allowed(new.description, 'listing_description');
        end if;
        if tg_op = 'INSERT' or new.registration is distinct from old.registration then
            perform carzon_private.assert_user_text_allowed(new.registration, 'listing_registration');
        end if;
        if tg_op = 'INSERT' or new.make is distinct from old.make then
            perform carzon_private.assert_user_text_allowed(new.make, 'listing_make');
        end if;
        if tg_op = 'INSERT' or new.model is distinct from old.model then
            perform carzon_private.assert_user_text_allowed(new.model, 'listing_model');
        end if;
        if tg_op = 'INSERT' or new.variant is distinct from old.variant then
            perform carzon_private.assert_user_text_allowed(new.variant, 'listing_variant');
        end if;
        if tg_op = 'INSERT' or new.city is distinct from old.city then
            perform carzon_private.assert_user_text_allowed(new.city, 'listing_city');
        end if;
    elsif tg_table_name = 'seller_profiles' then
        if tg_op = 'INSERT' or new.display_name is distinct from old.display_name then
            perform carzon_private.assert_user_text_allowed(new.display_name, 'seller_display_name');
        end if;
    elsif tg_table_name = 'messages' then
        if tg_op = 'INSERT' or new.body is distinct from old.body then
            perform carzon_private.assert_user_text_allowed(new.body, 'message_body');
        end if;
    end if;

    return new;
end;
$$;

revoke all on function public.carzon_enforce_user_text()
    from public, anon, authenticated;

------------------------------------------------------------------------------
-- Recreate listing RPCs (variant trailing optional param; PHEV fuel accepted)
------------------------------------------------------------------------------

drop function if exists public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text, text,
    text
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
    p_transmission_type            text default null,
    p_registration                 text default null,
    p_description                  text default null,
    p_vin                          text default null,
    p_variant                      text default null
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
    v_transmission_type        text;
    v_engine_l                  numeric(8, 4);
    v_power_hp                 integer;
    v_registration             text;
    v_description              text;
    v_variant                   text;

    v_gallery_urls             text[] := '{}';
    v_gallery_paths            text[] := '{}';

    i                          integer;
    u_raw                      text;
    u                          text;
    p_raw                      text;
    img_len                    integer;
    path_len                   integer;
    pair_count                 integer;

    v_vin_norm                 text;
    v_vin_hash                 text;
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
            'petrol', 'diesel', 'hybrid', 'plug_in_hybrid', 'electric', 'lpg', 'cng', 'other'
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

    if p_transmission_type is null or btrim(coalesce(p_transmission_type, '')) = '' then
        v_transmission_type := null;
    else
        v_transmission_type := lower(btrim(p_transmission_type));
        if v_transmission_type not in (
            'manual', 'automatic', 'cvt', 'robotic', 'dual_clutch', 'other'
        ) then
            raise exception 'invalid transmission_type: %', p_transmission_type
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

    v_variant := nullif(btrim(coalesce(p_variant, '')), '');
    if v_variant is not null and length(v_variant) > 80 then
        raise exception 'variant is too long'
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

    -- VIN: validate before inserting listing if caller supplied non-empty input.
    if p_vin is not null and btrim(p_vin) <> '' then
        v_vin_norm := public.carzon_normalize_vin_input(p_vin);
        if not public.carzon_normalized_vin_syntax_ok(v_vin_norm) then
            raise exception 'invalid vin'
                using errcode = '22023';
        end if;
        v_vin_hash := public.carzon_sha256_hex_utf8(v_vin_norm);
    else
        v_vin_norm := null;
        v_vin_hash := null;
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
        transmission_type,
        variant,
        registration,
        description,
        seller_id,
        contact_phone,
        telegram_username,
        whatsapp_enabled,
        cover_image_url,
        vin_status
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
        v_transmission_type,
        v_variant,
        v_registration,
        v_description,
        auth.uid(),
        v_phone,
        v_telegram,
        v_whatsapp_enabled,
        v_cover_final,
        case when v_vin_norm is null then 'not_provided' else 'format_valid' end
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

    if v_vin_norm is not null then
        insert into public.listing_vehicle_identity (
            listing_id,
            owner_id,
            vin_normalized,
            vin_hash
        )
        values (
            v_row.id,
            auth.uid(),
            v_vin_norm,
            v_vin_hash
        );

        perform public.carzon_enqueue_vin_decode_from_identity(
            v_row.id,
            auth.uid(),
            v_vin_hash
        );
    end if;

    select * into v_row from public.listings where id = v_row.id;
    return v_row;
end;
$$;


revoke all on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text, text,
    text, text
) from public;

revoke all on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text, text,
    text, text
) from anon;

grant execute on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text, text,
    text, text
) to authenticated;

drop function if exists public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text, text,
    text
);

create function public.update_listing_details_v2(
    p_listing_id                   uuid,
    p_title                        text,
    p_make                         text,
    p_model                        text,
    p_year                         integer,
    p_price_eur                    numeric,
    p_price_currency               text,
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
    p_transmission_type            text default null,
    p_registration                 text default null,
    p_description                  text default null,
    p_vin                          text default null,
    p_variant                      text default null
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_old_row                   public.listings;
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
    v_transmission_type         text;
    v_engine_l                  numeric(8, 4);
    v_power_hp                  integer;
    v_registration              text;
    v_description               text;
    v_variant                   text;

    v_vin_norm                  text;
    v_vin_hash                  text;
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
            'petrol', 'diesel', 'hybrid', 'plug_in_hybrid', 'electric', 'lpg', 'cng', 'other'
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

    if p_transmission_type is null or btrim(coalesce(p_transmission_type, '')) = '' then
        v_transmission_type := null;
    else
        v_transmission_type := lower(btrim(p_transmission_type));
        if v_transmission_type not in (
            'manual', 'automatic', 'cvt', 'robotic', 'dual_clutch', 'other'
        ) then
            raise exception 'invalid transmission_type: %', p_transmission_type
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

    v_variant := nullif(btrim(coalesce(p_variant, '')), '');
    if v_variant is not null and length(v_variant) > 80 then
        raise exception 'variant is too long'
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

    select *
      into strict v_old_row
      from public.listings l
     where l.id = p_listing_id
       and l.seller_id = auth.uid();

    -- Non-null non-empty p_vin: validate before mutating listing core fields.
    if p_vin is not null and btrim(p_vin) <> '' then
        v_vin_norm := public.carzon_normalize_vin_input(p_vin);
        if not public.carzon_normalized_vin_syntax_ok(v_vin_norm) then
            raise exception 'invalid vin'
                using errcode = '22023';
        end if;
        v_vin_hash := public.carzon_sha256_hex_utf8(v_vin_norm);
    else
        v_vin_norm := null;
        v_vin_hash := null;
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
           transmission_type           = v_transmission_type,
           variant                      = v_variant,
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

    if p_vin is not null then
        if btrim(p_vin) = '' then
            delete from public.listing_vehicle_identity i
             where i.listing_id = p_listing_id
               and i.owner_id = auth.uid();

            update public.listings l
               set vin_status = 'not_provided'
             where l.id = p_listing_id
               and l.seller_id = auth.uid();
        elsif v_vin_norm is not null then
            insert into public.listing_vehicle_identity (
                listing_id,
                owner_id,
                vin_normalized,
                vin_hash
            )
            values (
                p_listing_id,
                auth.uid(),
                v_vin_norm,
                v_vin_hash
            )
            on conflict (listing_id) do update
               set vin_normalized = excluded.vin_normalized,
                   vin_hash = excluded.vin_hash,
                   owner_id = excluded.owner_id,
                   updated_at = now();

            perform public.carzon_enqueue_vin_decode_from_identity(
                p_listing_id,
                auth.uid(),
                v_vin_hash
            );

            update public.listings l
               set vin_status = 'format_valid'
             where l.id = p_listing_id
               and l.seller_id = auth.uid();
        end if;

        select * into v_row from public.listings where id = p_listing_id;
    end if;

    if v_old_row.status = 'active'
       and v_row.status = 'active'
       and v_old_row.price_currency is not distinct from v_row.price_currency
       and v_row.price_eur < v_old_row.price_eur
    then
        perform public.enqueue_price_drop_favorite_notification_events(
            v_row.id,
            v_old_row.price_eur,
            v_row.price_eur,
            v_row.seller_id
        );
    end if;

    return v_row;
exception
    when no_data_found then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
end;
$$;


revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text, text,
    text, text
) from public;

revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text, text,
    text, text
) from anon;

grant execute on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text, text,
    text, text
) to authenticated;
