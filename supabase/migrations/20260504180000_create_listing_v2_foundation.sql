-- Carzon — Phase 1 foundation: price currency + gallery metadata + create_listing_v2.
--
-- Product:
--   * `listings.price_currency` complements existing `price_eur` ('eur' | 'usd').
--   * Optional ordered gallery URLs in child table `listing_images`
--     (positions 0..8, max 9 images).
--   * Fast feed/card reads unchanged: `listings.cover_image_url` remains the
--     primary hero URL; synced from first gallery URL when gallery is supplied.
--
-- Compatibility:
--   * Existing `public.create_listing` unchanged in signature; inserts omit
--     `price_currency` and rely on NOT NULL DEFAULT 'eur'.
--   * Single-cover clients keep using `create_listing` + `p_cover_image_url`; no
--     `listing_images` rows unless they migrate to `create_listing_v2`.
--
-- Security:
--   * All writes on `listing_images` go through SECURITY DEFINER RPCs only —
--     enable RLS with SELECT-only policies for feed/owner browsing.
--
-- Naming:
--   * Storage objects remain user-scoped: `listing-images/listings/<userId>/...`
--     (paths optional on rows; enforced by Storage RLS, not Postgres).

------------------------------------------------------------------------------
-- PART 1 — price_currency on public.listings
------------------------------------------------------------------------------

alter table public.listings
    add column if not exists price_currency text not null default 'eur';

-- Backfill (idempotent safety if column pre-existed as nullable)
update public.listings
set price_currency = 'eur'
where price_currency not in ('eur', 'usd')
   or price_currency is null;

alter table public.listings
    drop constraint if exists listings_price_currency_chk;

alter table public.listings
    add constraint listings_price_currency_chk
    check (price_currency in ('eur', 'usd'));

comment on column public.listings.price_currency is
    'Display/settlement currency for price_eur: eur | usd. Column price_eur still stores numeric amount until a future normalization migration.';

------------------------------------------------------------------------------
-- PART 2 — listing_images table + index + RLS (SELECT-only for clients)
------------------------------------------------------------------------------

create table if not exists public.listing_images (
    id              uuid        primary key default gen_random_uuid(),
    listing_id      uuid        not null references public.listings(id)
                                 on delete cascade,
    public_url      text        not null,
    storage_path    text,
    position        integer     not null,
    created_at      timestamptz not null default now(),

    constraint listing_images_position_range_chk check (position between 0 and 8),
    constraint listing_images_public_url_http_chk
        check (public_url ~* '^https?://'),

    constraint listing_images_listing_id_position_uniq unique (listing_id, position)
);

create index if not exists listing_images_listing_id_position_idx
    on public.listing_images (listing_id, position);

comment on table public.listing_images is
    'Ordered gallery URLs for listings (0 = cover/thumbnail synced to listings.cover_image_url). Mutations are RPC-only.';
comment on column public.listing_images.storage_path is
    'Optional object path inside listing-images bucket; may be NULL when unknown.';

alter table public.listing_images enable row level security;

-- Feed visitors: browse images only for visually active catalogue rows.
drop policy if exists "listing_images_public_read_active_catalog" on public.listing_images;
create policy "listing_images_public_read_active_catalog"
    on public.listing_images
    for select
    to anon, authenticated
    using (
        exists (
              select 1
              from public.listings li
              where li.id = listing_images.listing_id
                and li.status = 'active'
          )
    );

-- Owners: read gallery for any own listing lifecycle state (draft/hidden/etc.).
drop policy if exists "listing_images_owner_read_own" on public.listing_images;
create policy "listing_images_owner_read_own"
    on public.listing_images
    for select
    to authenticated
    using (
        exists (
              select 1
              from public.listings lo
              where lo.id = listing_images.listing_id
                and lo.seller_id = auth.uid()
          )
    );

-- Intentionally no INSERT/UPDATE/DELETE policies — clients mutate via SECURITY DEFINER RPCs only.

------------------------------------------------------------------------------
-- PART 4 — create_listing_v2 (SECURITY DEFINER; gallery optional)
------------------------------------------------------------------------------
--
-- Behaviour:
--   * When `p_image_urls` resolves to ≥1 trimmed http(s) URL after compaction:
--       gallery drives `cover_image_url` (= first URL). Parameter
--       `p_cover_image_url` is IGNORED for the stored cover column to avoid drift.
--   * Otherwise (NULL / empty / all blanks): behaves like legacy single-cover —
--       `listing_images` rows not created; `cover_image_url` comes from trimmed
--       `p_cover_image_url` (optional).
--   * `p_price_currency`: defaults 'eur'; must be trimmed lower-case invariant
--       ('eur' | 'usd').

create or replace function public.create_listing_v2(
    p_title               text,
    p_make                text,
    p_model               text,
    p_year                integer,
    p_price_eur           numeric,
    p_mileage_km          integer,
    p_type                text,
    p_market_region       text,
    p_city                text,
    p_contact_phone       text,
    p_telegram_username   text,
    p_whatsapp_enabled    boolean,
    p_cover_image_url     text,
    p_price_currency      text default 'eur',
    p_image_urls          text[] default null,
    p_storage_paths       text[] default null
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row                public.listings;
    v_title              text := btrim(coalesce(p_title, ''));
    v_make               text := btrim(coalesce(p_make, ''));
    v_model              text := btrim(coalesce(p_model, ''));
    v_city               text := btrim(coalesce(p_city, ''));
    v_phone              text := btrim(coalesce(p_contact_phone, ''));
    v_telegram           text := nullif(btrim(coalesce(p_telegram_username, '')), '');
    v_whatsapp_enabled   boolean := coalesce(p_whatsapp_enabled, false);
    v_currency           text := lower(btrim(coalesce(p_price_currency, 'eur')));
    v_cover_legacy       text;
    v_cover_final        text;

    -- Compacted paired gallery payloads (parallel 1-based arrays built in-loop).
    v_gallery_urls       text[] := '{}';
    v_gallery_paths      text[] := '{}';

    i                    integer;
    u_raw                text;
    u                    text;
    p_raw                text;
    img_len              integer;
    path_len             integer;
    pair_count           integer;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if v_currency not in ('eur', 'usd') then
        raise exception 'invalid price_currency'
            using errcode = '22023';
    end if;

    -- ---------- shared validation mirrors create_listing ----------
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

    -- Optional legacy-only cover normalization (when no gallery replaces it).
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

    -- ---------- gallery compaction ----------
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
        -- Gallery wins for cover projection.
        v_cover_final := v_gallery_urls[1];
    else
        -- Pure legacy cover path — no listing_images rows.
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
    text, text, text[], text[]
) from public;
revoke all on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[]
) from anon;
grant execute on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[]
) to authenticated;

------------------------------------------------------------------------------
-- PART 5 — replace_listing_images (owner-only RPC)
------------------------------------------------------------------------------

create or replace function public.replace_listing_images(
    p_listing_id           uuid,
    p_image_urls           text[],
    p_storage_paths        text[] default null
) returns public.listings
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_row                      public.listings;
    i                          integer;
    u_raw                      text;
    u                          text;
    p_raw                      text;
    img_len                    integer := coalesce(array_length(p_image_urls, 1), 0);
    path_len                   integer := coalesce(array_length(p_storage_paths, 1), 0);
    pair_count                 integer := 0;

    v_gallery_urls             text[] := '{}';
    v_gallery_paths            text[] := '{}';

    v_owner                    uuid;
begin
    if auth.uid() is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    select seller_id
      into v_owner
      from public.listings li
     where li.id = p_listing_id;

    if not found or v_owner is null or v_owner is distinct from auth.uid() then
        raise exception 'listing not found or not owned by caller'
            using errcode = '42501';
    end if;

    if p_storage_paths is not null and path_len <> img_len then
        raise exception 'storage_paths length must match image_urls'
            using errcode = '22023';
    end if;

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

    delete from public.listing_images gi
    where gi.listing_id = p_listing_id;

    if pair_count > 0 then
        update public.listings l
           set cover_image_url = v_gallery_urls[1]
         where l.id = p_listing_id
           and l.seller_id = auth.uid()
        returning * into v_row;

        if not found then
            raise exception 'listing not found or not owned by caller'
                using errcode = '42501';
        end if;

        for i in 1 .. pair_count loop
            insert into public.listing_images (
                listing_id,
                public_url,
                storage_path,
                position
            )
            values (
                p_listing_id,
                v_gallery_urls[i],
                nullif(btrim(coalesce(v_gallery_paths[i], '')), ''),
                i - 1
            );
        end loop;
    else
        update public.listings l
           set cover_image_url = null
         where l.id = p_listing_id
           and l.seller_id = auth.uid()
        returning * into v_row;

        if not found then
            raise exception 'listing not found or not owned by caller'
                using errcode = '42501';
        end if;
    end if;

    return v_row;
end;
$$;

revoke all on function public.replace_listing_images(uuid, text[], text[]) from public;
revoke all on function public.replace_listing_images(uuid, text[], text[]) from anon;
grant execute on function public.replace_listing_images(uuid, text[], text[]) to authenticated;
