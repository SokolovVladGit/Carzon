-- Carzon — listing view counting (total + Moldova-local daily + dedupe).
--
-- Public clients read listings.view_count via column grant only.
-- Writes and daily/dedupe analytics stay RPC-only (SECURITY DEFINER).
-- Viewer identity is hashed server-side; raw anonymous ids are never stored.

------------------------------------------------------------------------------
-- 1 — listings.view_count (public-safe aggregate)
------------------------------------------------------------------------------

alter table public.listings
    add column if not exists view_count integer not null default 0;

alter table public.listings
    drop constraint if exists listings_view_count_chk;

alter table public.listings
    add constraint listings_view_count_chk
        check (view_count >= 0);

comment on column public.listings.view_count is
    'Public aggregate listing detail view count. Incremented only via record_listing_view RPC.';

------------------------------------------------------------------------------
-- 2 — Daily buckets (Europe/Chisinau local date)
------------------------------------------------------------------------------

create table if not exists public.listing_view_daily (
    listing_id  uuid        not null references public.listings(id) on delete cascade,
    view_date   date        not null,
    view_count  integer     not null default 0,
    created_at  timestamptz not null default now(),
    updated_at  timestamptz not null default now(),
    primary key (listing_id, view_date),
    constraint listing_view_daily_count_chk check (view_count >= 0)
);

comment on table public.listing_view_daily is
    'Per-listing daily view totals keyed by Moldova-local calendar date. RPC-only writes.';

------------------------------------------------------------------------------
-- 3 — Same-day viewer dedupe (hashed viewer identity)
------------------------------------------------------------------------------

create table if not exists public.listing_view_dedupe (
    listing_id   uuid        not null references public.listings(id) on delete cascade,
    view_date    date        not null,
    viewer_hash  text        not null,
    created_at   timestamptz not null default now(),
    primary key (listing_id, view_date, viewer_hash)
);

comment on table public.listing_view_dedupe is
    'One row per listing + Moldova-local day + hashed viewer. Prevents repeat increments.';

------------------------------------------------------------------------------
-- 4 — RLS + revoke direct client access to analytics tables
------------------------------------------------------------------------------

alter table public.listing_view_daily enable row level security;
alter table public.listing_view_dedupe enable row level security;

revoke all on table public.listing_view_daily from anon;
revoke all on table public.listing_view_daily from authenticated;
revoke all on table public.listing_view_dedupe from anon;
revoke all on table public.listing_view_dedupe from authenticated;

------------------------------------------------------------------------------
-- 5 — Extend public listings column grant (contact hardening safe set)
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
    vin_status,
    view_count
) on public.listings to anon, authenticated;

------------------------------------------------------------------------------
-- 6 — record_listing_view RPC
------------------------------------------------------------------------------

create or replace function public.record_listing_view(
    p_listing_id uuid,
    p_anonymous_viewer_id text default null
)
returns table (
    total_views integer,
    today_views integer
)
language plpgsql
volatile
security definer
set search_path = public, extensions, pg_temp
as $$
declare
    v_listing public.listings%rowtype;
    v_view_date date := (now() at time zone 'Europe/Chisinau')::date;
    v_viewer_key text;
    v_viewer_hash text;
    v_rows_inserted integer;
    v_total integer;
    v_today integer;
begin
    select l.*
      into v_listing
      from public.listings l
     where l.id = p_listing_id;

    if not found then
        return query select 0::integer, 0::integer;
        return;
    end if;

    v_total := coalesce(v_listing.view_count, 0);

    select coalesce(d.view_count, 0)
      into v_today
      from public.listing_view_daily d
     where d.listing_id = p_listing_id
       and d.view_date = v_view_date;

    v_today := coalesce(v_today, 0);

    if v_listing.status is distinct from 'active' then
        return query select v_total, v_today;
        return;
    end if;

    if auth.uid() is not null
       and v_listing.seller_id is not null
       and auth.uid() = v_listing.seller_id then
        return query select v_total, v_today;
        return;
    end if;

    if auth.uid() is not null then
        v_viewer_key := 'auth:' || auth.uid()::text;
    elsif p_anonymous_viewer_id is not null
          and length(btrim(p_anonymous_viewer_id)) > 0 then
        v_viewer_key := 'anon:' || btrim(p_anonymous_viewer_id);
    else
        return query select v_total, v_today;
        return;
    end if;

    v_viewer_hash := public.carzon_sha256_hex_utf8(v_viewer_key);

    insert into public.listing_view_dedupe (listing_id, view_date, viewer_hash)
    values (p_listing_id, v_view_date, v_viewer_hash)
    on conflict do nothing;

    get diagnostics v_rows_inserted = row_count;

    if v_rows_inserted > 0 then
        update public.listings
           set view_count = view_count + 1
         where id = p_listing_id
         returning view_count into v_total;

        insert into public.listing_view_daily as d (listing_id, view_date, view_count)
        values (p_listing_id, v_view_date, 1)
        on conflict (listing_id, view_date) do update
            set view_count = d.view_count + 1,
                updated_at = now()
        returning view_count into v_today;
    end if;

    return query select coalesce(v_total, 0), coalesce(v_today, 0);
end;
$$;

revoke all on function public.record_listing_view(uuid, text) from public;
grant execute on function public.record_listing_view(uuid, text)
    to anon, authenticated;

comment on function public.record_listing_view(uuid, text) is
    'Records one listing detail view per viewer per Moldova-local day. '
    'Skips owner views and non-active listings. Returns aggregate stats.';
