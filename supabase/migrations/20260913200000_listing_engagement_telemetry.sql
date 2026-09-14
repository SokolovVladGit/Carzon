-- Carzon — listing engagement telemetry (Phase 4A).
--
-- Covers ONLY events with no existing product table:
--   impression | phone | whatsapp | telegram | share
--
-- Does NOT store views, favorites, inquiries, or messages.
-- Daily unique: 1 row per listing + viewer_hash + event_type + Moldova-local day.
-- Viewer identity is hashed server-side; raw auth UID / anon UUID never stored.
-- No generic append-only event log.
--
-- Indexes: PK (listing_id, event_date, event_type) already supports seller
-- aggregation after listings_seller_id_idx. No extra indexes.

------------------------------------------------------------------------------
-- 1 — Daily aggregates
------------------------------------------------------------------------------

create table if not exists public.listing_engagement_daily (
    listing_id   uuid        not null references public.listings(id) on delete cascade,
    event_date   date        not null,
    event_type   text        not null,
    event_count  integer     not null default 0,
    created_at   timestamptz not null default now(),
    updated_at   timestamptz not null default now(),
    primary key (listing_id, event_date, event_type),
    constraint listing_engagement_daily_count_chk
        check (event_count >= 0),
    constraint listing_engagement_daily_type_chk
        check (event_type in (
            'impression',
            'phone',
            'whatsapp',
            'telegram',
            'share'
        ))
);

comment on table public.listing_engagement_daily is
    'Per-listing daily unique engagement totals by event type. '
    'Moldova-local dates. RPC-only writes. Not views/favorites/inquiries.';

------------------------------------------------------------------------------
-- 2 — Same-day viewer dedupe
------------------------------------------------------------------------------

create table if not exists public.listing_engagement_dedupe (
    listing_id   uuid        not null references public.listings(id) on delete cascade,
    event_date   date        not null,
    event_type   text        not null,
    viewer_hash  text        not null,
    created_at   timestamptz not null default now(),
    primary key (listing_id, event_date, event_type, viewer_hash),
    constraint listing_engagement_dedupe_type_chk
        check (event_type in (
            'impression',
            'phone',
            'whatsapp',
            'telegram',
            'share'
        ))
);

comment on table public.listing_engagement_dedupe is
    'One row per listing + Moldova-local day + event type + hashed viewer. '
    'Enforces daily uniqueness. Never expose viewer_hash to clients.';

------------------------------------------------------------------------------
-- 3 — RLS + revoke direct client access
------------------------------------------------------------------------------

alter table public.listing_engagement_daily enable row level security;
alter table public.listing_engagement_dedupe enable row level security;

revoke all on table public.listing_engagement_daily from public;
revoke all on table public.listing_engagement_daily from anon;
revoke all on table public.listing_engagement_daily from authenticated;
revoke all on table public.listing_engagement_dedupe from public;
revoke all on table public.listing_engagement_dedupe from anon;
revoke all on table public.listing_engagement_dedupe from authenticated;

------------------------------------------------------------------------------
-- 4 — record_listing_engagement_event
------------------------------------------------------------------------------

create or replace function public.record_listing_engagement_event(
    p_listing_id uuid,
    p_event_type text,
    p_anonymous_viewer_id text default null
)
returns table (
    recorded boolean,
    today_count integer
)
language plpgsql
volatile
security definer
set search_path = public, extensions, pg_temp
as $$
declare
    v_listing public.listings%rowtype;
    v_event_date date := (now() at time zone 'Europe/Chisinau')::date;
    v_event_type text;
    v_viewer_key text;
    v_viewer_hash text;
    v_rows_inserted integer;
    v_today integer := 0;
begin
    v_event_type := lower(btrim(coalesce(p_event_type, '')));
    if v_event_type not in (
        'impression',
        'phone',
        'whatsapp',
        'telegram',
        'share'
    ) then
        raise exception 'invalid engagement event type: %', p_event_type
            using errcode = '22023';
    end if;

    select l.*
      into v_listing
      from public.listings l
     where l.id = p_listing_id;

    if not found or v_listing.status is distinct from 'active' then
        return query select false, 0;
        return;
    end if;

    select coalesce(d.event_count, 0)
      into v_today
      from public.listing_engagement_daily d
     where d.listing_id = p_listing_id
       and d.event_date = v_event_date
       and d.event_type = v_event_type;

    v_today := coalesce(v_today, 0);

    if auth.uid() is not null
       and v_listing.seller_id is not null
       and auth.uid() = v_listing.seller_id then
        return query select false, v_today;
        return;
    end if;

    if auth.uid() is not null then
        v_viewer_key := 'auth:' || auth.uid()::text;
    elsif p_anonymous_viewer_id is not null
          and length(btrim(p_anonymous_viewer_id)) > 0 then
        v_viewer_key := 'anon:' || btrim(p_anonymous_viewer_id);
    else
        return query select false, 0;
        return;
    end if;

    v_viewer_hash := public.carzon_sha256_hex_utf8(v_viewer_key);

    insert into public.listing_engagement_dedupe (
        listing_id,
        event_date,
        event_type,
        viewer_hash
    )
    values (
        p_listing_id,
        v_event_date,
        v_event_type,
        v_viewer_hash
    )
    on conflict do nothing;

    get diagnostics v_rows_inserted = row_count;

    if v_rows_inserted > 0 then
        insert into public.listing_engagement_daily as d (
            listing_id,
            event_date,
            event_type,
            event_count
        )
        values (
            p_listing_id,
            v_event_date,
            v_event_type,
            1
        )
        on conflict (listing_id, event_date, event_type) do update
            set event_count = d.event_count + 1,
                updated_at = now()
        returning event_count into v_today;
        return query select true, coalesce(v_today, 1);
        return;
    end if;

    return query select false, v_today;
end;
$$;

revoke all on function public.record_listing_engagement_event(uuid, text, text)
    from public;
grant execute on function public.record_listing_engagement_event(uuid, text, text)
    to anon, authenticated;

comment on function public.record_listing_engagement_event(uuid, text, text) is
    'Records one unique daily engagement event per viewer per listing per type. '
    'Skips seller self-interaction and non-active listings. '
    'Does not return viewer_hash. Does not count views/favorites/inquiries.';

------------------------------------------------------------------------------
-- 5 — Seller aggregate RPCs (do not alter Phase 1 analytics contracts)
------------------------------------------------------------------------------

create or replace function public.get_my_seller_engagement_summary(
    p_period_days integer
)
returns table (
    period_impressions integer,
    period_phone_actions integer,
    period_whatsapp_actions integer,
    period_telegram_actions integer,
    period_shares integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_today date;
    v_start date;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_period_days is distinct from 7
       and p_period_days is distinct from 30
       and p_period_days is distinct from 90 then
        raise exception 'invalid analytics period: %', p_period_days
            using errcode = '22023';
    end if;

    v_today := (now() at time zone 'Europe/Chisinau')::date;
    v_start := v_today - (p_period_days - 1);

    return query
    select coalesce(sum(e.event_count) filter (where e.event_type = 'impression'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'phone'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'whatsapp'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'telegram'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'share'), 0)::integer
      from public.listings l
      join public.listing_engagement_daily e
        on e.listing_id = l.id
       and e.event_date between v_start and v_today
     where l.seller_id = v_uid
       and l.status in ('active', 'sold');
end;
$$;

comment on function public.get_my_seller_engagement_summary(integer) is
    'Seller-owned engagement totals for 7/30/90 Moldova-local days. '
    'auth.uid() only. Active + sold listings. Zeros when empty.';

create or replace function public.get_my_seller_engagement_listings(
    p_period_days integer
)
returns table (
    listing_id uuid,
    period_impressions integer,
    period_phone_actions integer,
    period_whatsapp_actions integer,
    period_telegram_actions integer,
    period_shares integer
)
language plpgsql
stable
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid;
    v_today date;
    v_start date;
begin
    v_uid := auth.uid();
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_period_days is distinct from 7
       and p_period_days is distinct from 30
       and p_period_days is distinct from 90 then
        raise exception 'invalid analytics period: %', p_period_days
            using errcode = '22023';
    end if;

    v_today := (now() at time zone 'Europe/Chisinau')::date;
    v_start := v_today - (p_period_days - 1);

    return query
    select l.id,
           coalesce(sum(e.event_count) filter (where e.event_type = 'impression'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'phone'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'whatsapp'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'telegram'), 0)::integer,
           coalesce(sum(e.event_count) filter (where e.event_type = 'share'), 0)::integer
      from public.listings l
      left join public.listing_engagement_daily e
        on e.listing_id = l.id
       and e.event_date between v_start and v_today
     where l.seller_id = v_uid
       and l.status in ('active', 'sold')
     group by l.id
     order by l.id;
end;
$$;

comment on function public.get_my_seller_engagement_listings(integer) is
    'Per-listing engagement for the caller''s active+sold listings. '
    'Ordered by listing_id. No viewer hashes.';

revoke all on function public.get_my_seller_engagement_summary(integer)
    from public;
revoke all on function public.get_my_seller_engagement_summary(integer)
    from anon;
grant execute on function public.get_my_seller_engagement_summary(integer)
    to authenticated;

revoke all on function public.get_my_seller_engagement_listings(integer)
    from public;
revoke all on function public.get_my_seller_engagement_listings(integer)
    from anon;
grant execute on function public.get_my_seller_engagement_listings(integer)
    to authenticated;
