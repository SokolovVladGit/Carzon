-- Carzon — private reusable seller listing defaults (contact + location).
--
-- Private operational defaults for Create Listing prefill.
-- Isolated from public seller identity tables.
-- Contact phone + Telegram + last location only. No vehicle identifiers,
-- mailbox addresses, display name, photos, price, mileage, or arbitrary JSON.
--
-- Clients never touch the table directly. Authenticated callers use:
--   * get_my_listing_defaults()
--   * upsert_my_listing_defaults(...)
-- auth.uid() only; caller cannot supply user_id.

------------------------------------------------------------------------------
-- Table
------------------------------------------------------------------------------

create table if not exists public.seller_listing_defaults (
    user_id uuid primary key references auth.users (id) on delete cascade,
    contact_phone text,
    telegram_username text,
    whatsapp_enabled boolean not null default false,
    market_region text,
    city text,
    created_at timestamptz not null default now(),
    updated_at timestamptz not null default now(),

    constraint seller_listing_defaults_contact_phone_chk check (
        contact_phone is null
        or length(regexp_replace(contact_phone, '[^0-9]', '', 'g')) >= 7
    ),
    constraint seller_listing_defaults_telegram_username_chk check (
        telegram_username is null
        or telegram_username ~ '^[A-Za-z0-9_]{5,32}$'
    ),
    constraint seller_listing_defaults_market_region_chk check (
        market_region is null
        or market_region in ('transnistria', 'moldova')
    ),
    constraint seller_listing_defaults_city_trim_chk check (
        city is null
        or length(btrim(city)) > 0
    ),
    constraint seller_listing_defaults_city_requires_region_chk check (
        city is null
        or market_region is not null
    )
);

comment on table public.seller_listing_defaults is
    'Private per-user Create Listing contact/location defaults. RPC-only. Not public profile data.';

comment on column public.seller_listing_defaults.contact_phone is
    'Last successfully published listing phone; nullable. Not a public profile field.';

comment on column public.seller_listing_defaults.telegram_username is
    'Stored without leading @. Nullable.';

comment on column public.seller_listing_defaults.city is
    'Last published city text. Manual/historical values allowed; no catalog CHECK.';

alter table public.seller_listing_defaults enable row level security;

revoke all on table public.seller_listing_defaults from public;
revoke all on table public.seller_listing_defaults from anon;
revoke all on table public.seller_listing_defaults from authenticated;

------------------------------------------------------------------------------
-- get_my_listing_defaults
------------------------------------------------------------------------------

create or replace function public.get_my_listing_defaults()
returns table (
    contact_phone text,
    telegram_username text,
    whatsapp_enabled boolean,
    market_region text,
    city text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated';
    end if;

    if exists (
        select 1
          from public.seller_listing_defaults sld
         where sld.user_id = v_uid
    ) then
        return query
        select sld.contact_phone,
               sld.telegram_username,
               sld.whatsapp_enabled,
               sld.market_region,
               sld.city
          from public.seller_listing_defaults sld
         where sld.user_id = v_uid;
    else
        return query
        select null::text,
               null::text,
               false,
               null::text,
               null::text;
    end if;
end;
$$;

comment on function public.get_my_listing_defaults() is
    'Authenticated caller reads own listing contact/location defaults. Empty row when none saved. No user_id returned.';

revoke all on function public.get_my_listing_defaults() from public;
revoke all on function public.get_my_listing_defaults() from anon;
grant execute on function public.get_my_listing_defaults() to authenticated;

------------------------------------------------------------------------------
-- upsert_my_listing_defaults
------------------------------------------------------------------------------

create or replace function public.upsert_my_listing_defaults(
    p_contact_phone text,
    p_telegram_username text,
    p_whatsapp_enabled boolean,
    p_market_region text,
    p_city text
)
returns table (
    contact_phone text,
    telegram_username text,
    whatsapp_enabled boolean,
    market_region text,
    city text
)
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_phone text;
    v_telegram text;
    v_region text;
    v_city text;
    v_whatsapp boolean;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated';
    end if;

    v_phone := nullif(btrim(coalesce(p_contact_phone, '')), '');
    if v_phone is not null
       and length(regexp_replace(v_phone, '[^0-9]', '', 'g')) < 7 then
        raise exception 'invalid contact_phone';
    end if;

    v_telegram := nullif(btrim(coalesce(p_telegram_username, '')), '');
    if v_telegram is not null then
        if left(v_telegram, 1) = '@' then
            v_telegram := substring(v_telegram from 2);
        end if;
        if v_telegram !~ '^[A-Za-z0-9_]{5,32}$' then
            raise exception 'invalid telegram_username';
        end if;
    end if;

    v_whatsapp := coalesce(p_whatsapp_enabled, false);

    v_region := nullif(btrim(coalesce(p_market_region, '')), '');
    if v_region is not null
       and v_region not in ('transnistria', 'moldova') then
        raise exception 'invalid market_region';
    end if;

    v_city := nullif(btrim(coalesce(p_city, '')), '');
    if v_city is not null and v_region is null then
        raise exception 'city_requires_market_region';
    end if;

    insert into public.seller_listing_defaults (
        user_id,
        contact_phone,
        telegram_username,
        whatsapp_enabled,
        market_region,
        city,
        updated_at
    ) values (
        v_uid,
        v_phone,
        v_telegram,
        v_whatsapp,
        v_region,
        v_city,
        now()
    )
    on conflict (user_id) do update
    set contact_phone = excluded.contact_phone,
        telegram_username = excluded.telegram_username,
        whatsapp_enabled = excluded.whatsapp_enabled,
        market_region = excluded.market_region,
        city = excluded.city,
        updated_at = now();

    return query
    select sld.contact_phone,
           sld.telegram_username,
           sld.whatsapp_enabled,
           sld.market_region,
           sld.city
      from public.seller_listing_defaults sld
     where sld.user_id = v_uid;
end;
$$;

comment on function public.upsert_my_listing_defaults(text, text, boolean, text, text) is
    'Authenticated caller upserts own listing contact/location defaults. user_id is auth.uid() only.';

revoke all on function public.upsert_my_listing_defaults(text, text, boolean, text, text) from public;
revoke all on function public.upsert_my_listing_defaults(text, text, boolean, text, text) from anon;
grant execute on function public.upsert_my_listing_defaults(text, text, boolean, text, text) to authenticated;
