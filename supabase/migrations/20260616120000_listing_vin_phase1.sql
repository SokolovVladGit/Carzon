-- Carzon — Phase 1 optional VIN (privacy-safe): public vin_status on listings,
-- private normalized VIN in listing_vehicle_identity, RPC wiring only.
--
-- * No plaintext full VIN on public.listings.
-- * No checksum / external decode (Phase 1).

------------------------------------------------------------------------------
-- 1 — Public-safe column on listings
------------------------------------------------------------------------------

alter table public.listings
    add column if not exists vin_status text not null default 'not_provided';

update public.listings
   set vin_status = 'not_provided'
 where vin_status is null
    or vin_status not in ('not_provided', 'format_valid');

alter table public.listings
    drop constraint if exists listings_vin_status_chk;

alter table public.listings
    add constraint listings_vin_status_chk
        check (vin_status in ('not_provided', 'format_valid'));

comment on column public.listings.vin_status is
    'Public-only VIN hint: not_provided | format_valid. Never stores full VIN.';

------------------------------------------------------------------------------
-- 2 — Helpers (no EXECUTE for clients)
------------------------------------------------------------------------------

create or replace function public.carzon_normalize_vin_input(p_vin text)
returns text
language sql
immutable
as $$
    select case
        when p_vin is null then null
        else upper(
            replace(
                replace(btrim(p_vin), ' ', ''),
                '-',
                ''
            )
        )
    end;
$$;

create or replace function public.carzon_normalized_vin_syntax_ok(p_normalized text)
returns boolean
language sql
immutable
as $$
    select p_normalized is not null
       and length(p_normalized) = 17
       and p_normalized !~ '[IOQ]'
       and p_normalized ~ '^[A-HJ-NPR-Z0-9]{17}$';
$$;

revoke all on function public.carzon_normalize_vin_input(text) from public;
revoke all on function public.carzon_normalize_vin_input(text) from anon;
revoke all on function public.carzon_normalize_vin_input(text) from authenticated;

revoke all on function public.carzon_normalized_vin_syntax_ok(text) from public;
revoke all on function public.carzon_normalized_vin_syntax_ok(text) from anon;
revoke all on function public.carzon_normalized_vin_syntax_ok(text) from authenticated;

------------------------------------------------------------------------------
-- 3 — Private identity table
------------------------------------------------------------------------------

create table if not exists public.listing_vehicle_identity (
    listing_id      uuid primary key references public.listings(id)
                                         on delete cascade,
    owner_id        uuid not null references auth.users(id) on delete cascade,
    vin_normalized  text not null,
    vin_hash        text not null,
    created_at      timestamptz not null default now(),
    updated_at      timestamptz not null default now(),

    constraint listing_vehicle_identity_vin_normalized_chk
        check (
            length(vin_normalized) = 17
            and vin_normalized !~ '[IOQ]'
            and vin_normalized ~ '^[A-HJ-NPR-Z0-9]{17}$'
        )
);

create index if not exists listing_vehicle_identity_owner_id_idx
    on public.listing_vehicle_identity (owner_id);

create index if not exists listing_vehicle_identity_vin_hash_idx
    on public.listing_vehicle_identity (vin_hash);

comment on table public.listing_vehicle_identity is
    'Owner-private normalized VIN storage; never exposed to anon / non-owners.';

drop trigger if exists listing_vehicle_identity_set_updated_at
    on public.listing_vehicle_identity;

create trigger listing_vehicle_identity_set_updated_at
    before update on public.listing_vehicle_identity
    for each row
    execute function public.set_listings_updated_at();

alter table public.listing_vehicle_identity enable row level security;

-- Deny direct client access; SECURITY DEFINER RPCs perform mutations/selects.
revoke all on table public.listing_vehicle_identity from public;
revoke all on table public.listing_vehicle_identity from anon;
revoke all on table public.listing_vehicle_identity from authenticated;

------------------------------------------------------------------------------
-- 4 — Owner read RPC
------------------------------------------------------------------------------

create or replace function public.get_my_listing_vehicle_identity(p_listing_id uuid)
returns table (
    listing_id uuid,
    vin_normalized text,
    vin_status text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if not exists (
        select 1
          from public.listings li
         where li.id = p_listing_id
           and li.seller_id = auth.uid()
    ) then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    return query
    select
        l.id,
        i.vin_normalized,
        l.vin_status
      from public.listings l
      left join public.listing_vehicle_identity i
             on i.listing_id = l.id
     where l.id = p_listing_id;
end;
$$;

revoke all on function public.get_my_listing_vehicle_identity(uuid) from public;
revoke all on function public.get_my_listing_vehicle_identity(uuid) from anon;
grant execute on function public.get_my_listing_vehicle_identity(uuid)
    to authenticated;

------------------------------------------------------------------------------
-- 5 — Replace create_listing_v2 (append p_vin default null)
------------------------------------------------------------------------------

drop function if exists public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text
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
    p_description                  text default null,
    p_vin                          text default null
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
    v_engine_l                  numeric(8, 4);
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

    -- VIN: validate before inserting listing if caller supplied non-empty input.
    if p_vin is not null and btrim(p_vin) <> '' then
        v_vin_norm := public.carzon_normalize_vin_input(p_vin);
        if not public.carzon_normalized_vin_syntax_ok(v_vin_norm) then
            raise exception 'invalid vin'
                using errcode = '22023';
        end if;
        v_vin_hash := encode(digest(convert_to(v_vin_norm, 'UTF8'), 'sha256'), 'hex');
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
    end if;

    select * into v_row from public.listings where id = v_row.id;
    return v_row;
end;
$$;

revoke all on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text,
    text
) from public;

revoke all on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text,
    text
) from anon;

grant execute on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text,
    text
) to authenticated;

------------------------------------------------------------------------------
-- 6 — Replace update_listing_details_v2 (append p_vin default null)
------------------------------------------------------------------------------

drop function if exists public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text
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
    p_registration                 text default null,
    p_description                  text default null,
    p_vin                          text default null
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

    -- Non-null non-empty p_vin: validate before mutating listing core fields.
    if p_vin is not null and btrim(p_vin) <> '' then
        v_vin_norm := public.carzon_normalize_vin_input(p_vin);
        if not public.carzon_normalized_vin_syntax_ok(v_vin_norm) then
            raise exception 'invalid vin'
                using errcode = '22023';
        end if;
        v_vin_hash := encode(digest(convert_to(v_vin_norm, 'UTF8'), 'sha256'), 'hex');
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

            update public.listings l
               set vin_status = 'format_valid'
             where l.id = p_listing_id
               and l.seller_id = auth.uid();
        end if;

        select * into v_row from public.listings where id = p_listing_id;
    end if;

    return v_row;
end;
$$;

revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text,
    text
) from public;

revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text,
    text
) from anon;

grant execute on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text,
    text
) to authenticated;
