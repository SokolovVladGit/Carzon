-- Carzon — P1 M1.4 Phase A: multiple saved searches (v2 foundation).
--
-- • New table `saved_searches` (up to 5 per user, RPC-managed writes).
-- • Idempotent backfill from legacy `filter_alert_settings` (criteria not null).
-- • `filter_alert_settings` is retained for v1 client compatibility until Phase C.
-- • Enqueue worker scans `saved_searches`; Edge Phase B must validate saved rows.
-- • Notification dedupe unchanged: one filter_alert_listing_match per recipient + listing.

------------------------------------------------------------------------------
-- 1 — Table
------------------------------------------------------------------------------

create table if not exists public.saved_searches (
    id                  uuid primary key default gen_random_uuid(),
    user_id             uuid not null references auth.users (id) on delete cascade,
    name                text not null,
    criteria            jsonb not null,
    alerts_enabled      boolean not null default false,
    created_at          timestamptz not null default now(),
    updated_at          timestamptz not null default now(),
    last_notified_at    timestamptz null,

    constraint saved_searches_name_nonempty_chk check (
        char_length(trim(both from name)) > 0
    ),
    constraint saved_searches_name_max_len_chk check (
        char_length(trim(both from name)) <= 80
    ),
    constraint saved_searches_criteria_is_object_chk check (
        jsonb_typeof(criteria) = 'object'
    )
);

comment on table public.saved_searches is
    'P1 M1.4: up to 5 saved listing-discovery searches per user; optional push via alerts_enabled.';
comment on column public.saved_searches.criteria is
    'Flutter ListingDiscoveryCriteria JSON (schemaVersion 1); sort stored but matcher ignores it.';
comment on column public.saved_searches.alerts_enabled is
    'When true, enqueue may queue filter_alert_listing_match rows for this saved search.';
comment on column public.saved_searches.last_notified_at is
    'Reserved for future per-search notify bookkeeping; unused in Phase A enqueue.';

create index if not exists saved_searches_user_id_updated_at_idx
    on public.saved_searches (user_id, updated_at desc);

create index if not exists saved_searches_user_id_alerts_enabled_idx
    on public.saved_searches (user_id)
    where alerts_enabled = true;

-- Exact JSON duplicate prevention per user (same bytes / jsonb equality).
create unique index if not exists saved_searches_user_criteria_uniq_idx
    on public.saved_searches (user_id, criteria);

------------------------------------------------------------------------------
-- 2 — updated_at trigger
------------------------------------------------------------------------------

create or replace function public.touch_saved_searches_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
begin
    new.updated_at := now();
    return new;
end;
$$;

drop trigger if exists saved_searches_touch_updated_at on public.saved_searches;

create trigger saved_searches_touch_updated_at
    before update on public.saved_searches
    for each row execute function public.touch_saved_searches_updated_at();

------------------------------------------------------------------------------
-- 3 — Max 5 per user (defense in depth; RPC also checks)
------------------------------------------------------------------------------

create or replace function public.enforce_saved_searches_max_per_user()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $$
declare
    v_count integer;
begin
    select count(*)
      into v_count
      from public.saved_searches ss
     where ss.user_id = new.user_id;

    if v_count >= 5 then
        raise exception 'max_saved_searches_reached'
            using errcode = 'P0001';
    end if;

    return new;
end;
$$;

drop trigger if exists saved_searches_enforce_max_per_user_ins on public.saved_searches;

create trigger saved_searches_enforce_max_per_user_ins
    before insert on public.saved_searches
    for each row execute function public.enforce_saved_searches_max_per_user();

------------------------------------------------------------------------------
-- 4 — RLS
------------------------------------------------------------------------------

alter table public.saved_searches enable row level security;

drop policy if exists saved_searches_select_own on public.saved_searches;
create policy saved_searches_select_own
    on public.saved_searches
    for select
    to authenticated
    using (user_id = (select auth.uid()));

drop policy if exists saved_searches_insert_own on public.saved_searches;
create policy saved_searches_insert_own
    on public.saved_searches
    for insert
    to authenticated
    with check (
        user_id = (select auth.uid())
        and user_id is not null
    );

drop policy if exists saved_searches_update_own on public.saved_searches;
create policy saved_searches_update_own
    on public.saved_searches
    for update
    to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()));

drop policy if exists saved_searches_delete_own on public.saved_searches;
create policy saved_searches_delete_own
    on public.saved_searches
    for delete
    to authenticated
    using (user_id = (select auth.uid()));

------------------------------------------------------------------------------
-- 5 — Table privileges (reads via RLS; writes via SECURITY DEFINER RPCs)
------------------------------------------------------------------------------

revoke all on table public.saved_searches from public;
revoke insert, update, delete on table public.saved_searches from authenticated;

grant select on table public.saved_searches to authenticated;

------------------------------------------------------------------------------
-- 6 — Validation helpers (internal)
------------------------------------------------------------------------------

create or replace function public.saved_searches_validate_name(p_name text)
returns text
language plpgsql
immutable
security invoker
set search_path = public, pg_temp
as $$
declare
    v_name text := trim(both from coalesce(p_name, ''));
begin
    if v_name = '' then
        raise exception 'saved_search_name_required'
            using errcode = '22023';
    end if;
    if char_length(v_name) > 80 then
        raise exception 'saved_search_name_too_long'
            using errcode = '22023';
    end if;
    return v_name;
end;
$$;

create or replace function public.saved_searches_validate_criteria(p_criteria jsonb)
returns jsonb
language plpgsql
immutable
security invoker
set search_path = public, pg_temp
as $$
declare
    v_sv text;
    v_sv_int int;
begin
    if p_criteria is null or jsonb_typeof(p_criteria) <> 'object' then
        raise exception 'saved_search_criteria_invalid'
            using errcode = '22023';
    end if;

    if p_criteria ? 'schemaVersion' then
        v_sv := p_criteria->>'schemaVersion';
        if v_sv is not null and btrim(v_sv) <> '' then
            begin
                v_sv_int := v_sv::int;
            exception
                when others then
                    raise exception 'saved_search_criteria_invalid'
                        using errcode = '22023';
            end;
            if v_sv_int is distinct from 1 then
                raise exception 'saved_search_criteria_invalid'
                    using errcode = '22023';
            end if;
        end if;
    end if;

    return p_criteria;
end;
$$;

revoke all on function public.saved_searches_validate_name(text) from public;
revoke all on function public.saved_searches_validate_name(text) from anon;
revoke all on function public.saved_searches_validate_name(text) from authenticated;

revoke all on function public.saved_searches_validate_criteria(jsonb) from public;
revoke all on function public.saved_searches_validate_criteria(jsonb) from anon;
revoke all on function public.saved_searches_validate_criteria(jsonb) from authenticated;

------------------------------------------------------------------------------
-- 7 — Backfill from v1 filter_alert_settings (idempotent)
------------------------------------------------------------------------------

insert into public.saved_searches (
    user_id,
    name,
    criteria,
    alerts_enabled,
    created_at,
    updated_at,
    last_notified_at
)
select
    fas.user_id,
    'Search',
    fas.criteria,
    fas.notifications_enabled,
    fas.created_at,
    fas.updated_at,
    null
from public.filter_alert_settings fas
where fas.criteria is not null
  and jsonb_typeof(fas.criteria) = 'object'
  and not exists (
      select 1
        from public.saved_searches ss
       where ss.user_id = fas.user_id
         and ss.criteria = fas.criteria
  );

------------------------------------------------------------------------------
-- 8 — RPCs
------------------------------------------------------------------------------

create or replace function public.list_my_saved_searches()
returns setof public.saved_searches
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    return query
    select ss.*
      from public.saved_searches ss
     where ss.user_id = v_uid
     order by ss.updated_at desc, ss.created_at desc;
end;
$$;

create or replace function public.create_saved_search(
    p_name text,
    p_criteria jsonb,
    p_alerts_enabled boolean default true
)
returns public.saved_searches
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_name text;
    v_criteria jsonb;
    v_count integer;
    v_row public.saved_searches;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    v_name := public.saved_searches_validate_name(p_name);
    v_criteria := public.saved_searches_validate_criteria(p_criteria);

    select count(*)
      into v_count
      from public.saved_searches ss
     where ss.user_id = v_uid;

    if v_count >= 5 then
        raise exception 'max_saved_searches_reached'
            using errcode = 'P0001';
    end if;

    if exists (
        select 1
          from public.saved_searches ss
         where ss.user_id = v_uid
           and ss.criteria = v_criteria
    ) then
        raise exception 'duplicate_saved_search'
            using errcode = 'P0001';
    end if;

    insert into public.saved_searches (
        user_id,
        name,
        criteria,
        alerts_enabled
    ) values (
        v_uid,
        v_name,
        v_criteria,
        coalesce(p_alerts_enabled, true)
    )
    returning * into strict v_row;

    return v_row;
exception
    when unique_violation then
        raise exception 'duplicate_saved_search'
            using errcode = 'P0001';
end;
$$;

create or replace function public.update_saved_search(
    p_id uuid,
    p_name text default null,
    p_criteria jsonb default null,
    p_alerts_enabled boolean default null
)
returns public.saved_searches
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_row public.saved_searches;
    v_name text;
    v_criteria jsonb;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_id is null then
        raise exception 'saved_search_id_required'
            using errcode = '22023';
    end if;

    select *
      into v_row
      from public.saved_searches ss
     where ss.id = p_id
       and ss.user_id = v_uid;

    if not found then
        raise exception 'saved_search_not_found'
            using errcode = 'P0002';
    end if;

    v_name := v_row.name;
    if p_name is not null then
        v_name := public.saved_searches_validate_name(p_name);
    end if;

    v_criteria := v_row.criteria;
    if p_criteria is not null then
        v_criteria := public.saved_searches_validate_criteria(p_criteria);
    end if;

    if p_criteria is not null and exists (
        select 1
          from public.saved_searches ss
         where ss.user_id = v_uid
           and ss.id is distinct from p_id
           and ss.criteria = v_criteria
    ) then
        raise exception 'duplicate_saved_search'
            using errcode = 'P0001';
    end if;

    update public.saved_searches ss
       set name = v_name,
           criteria = v_criteria,
           alerts_enabled = coalesce(p_alerts_enabled, ss.alerts_enabled),
           updated_at = now()
     where ss.id = p_id
       and ss.user_id = v_uid
    returning ss.* into strict v_row;

    return v_row;
exception
    when unique_violation then
        raise exception 'duplicate_saved_search'
            using errcode = 'P0001';
end;
$$;

create or replace function public.delete_saved_search(p_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_deleted boolean := false;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_id is null then
        raise exception 'saved_search_id_required'
            using errcode = '22023';
    end if;

    delete from public.saved_searches ss
     where ss.id = p_id
       and ss.user_id = v_uid;

    v_deleted := found;
    return v_deleted;
end;
$$;

create or replace function public.set_saved_search_alerts_enabled(
    p_id uuid,
    p_enabled boolean
)
returns public.saved_searches
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_row public.saved_searches;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    if p_id is null then
        raise exception 'saved_search_id_required'
            using errcode = '22023';
    end if;

    update public.saved_searches ss
       set alerts_enabled = coalesce(p_enabled, false),
           updated_at = now()
     where ss.id = p_id
       and ss.user_id = v_uid
    returning ss.* into v_row;

    if not found then
        raise exception 'saved_search_not_found'
            using errcode = 'P0002';
    end if;

    return v_row;
end;
$$;

create or replace function public.find_saved_search_by_criteria(p_criteria jsonb)
returns public.saved_searches
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_criteria jsonb;
    v_row public.saved_searches;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    v_criteria := public.saved_searches_validate_criteria(p_criteria);

    select ss.*
      into v_row
      from public.saved_searches ss
     where ss.user_id = v_uid
       and ss.criteria = v_criteria
     order by ss.updated_at desc
     limit 1;

    return v_row;
exception
    when no_data_found then
        return null;
end;
$$;

revoke all on function public.list_my_saved_searches() from public;
revoke all on function public.list_my_saved_searches() from anon;
grant execute on function public.list_my_saved_searches() to authenticated;

revoke all on function public.create_saved_search(text, jsonb, boolean) from public;
revoke all on function public.create_saved_search(text, jsonb, boolean) from anon;
grant execute on function public.create_saved_search(text, jsonb, boolean) to authenticated;

revoke all on function public.update_saved_search(uuid, text, jsonb, boolean) from public;
revoke all on function public.update_saved_search(uuid, text, jsonb, boolean) from anon;
grant execute on function public.update_saved_search(uuid, text, jsonb, boolean) to authenticated;

revoke all on function public.delete_saved_search(uuid) from public;
revoke all on function public.delete_saved_search(uuid) from anon;
grant execute on function public.delete_saved_search(uuid) to authenticated;

revoke all on function public.set_saved_search_alerts_enabled(uuid, boolean) from public;
revoke all on function public.set_saved_search_alerts_enabled(uuid, boolean) from anon;
grant execute on function public.set_saved_search_alerts_enabled(uuid, boolean) to authenticated;

revoke all on function public.find_saved_search_by_criteria(jsonb) from public;
revoke all on function public.find_saved_search_by_criteria(jsonb) from anon;
grant execute on function public.find_saved_search_by_criteria(jsonb) to authenticated;

------------------------------------------------------------------------------
-- 9 — Enqueue: scan saved_searches (dedupe per recipient + listing unchanged)
------------------------------------------------------------------------------

create or replace function public.enqueue_filter_alert_notification_events_for_listing(
    p_listing_id uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    r public.listings%rowtype;
begin
    select *
      into strict r
      from public.listings l
     where l.id = p_listing_id;

    if r.status is distinct from 'active' or r.seller_id is null then
        return;
    end if;

    insert into public.notification_delivery_events (
        event_type,
        recipient_user_id,
        actor_user_id,
        conversation_id,
        message_id,
        listing_id,
        payload,
        status
    )
    select
        'filter_alert_listing_match',
        ss.user_id,
        r.seller_id,
        null,
        null,
        r.id,
        jsonb_build_object('listing_id', r.id),
        'pending'
    from public.saved_searches ss
    inner join public.notification_preferences np
        on np.user_id = ss.user_id
       and np.global_enabled = true
       and np.filter_alerts_enabled = true
    where ss.user_id is distinct from r.seller_id
      and ss.criteria is not null
      and ss.alerts_enabled = true
      and public.listing_matches_saved_discovery_criteria(r, ss.criteria)
      and exists (
          select 1
            from public.user_push_tokens upt
           where upt.user_id = ss.user_id
             and upt.is_active = true
      )
    on conflict (recipient_user_id, listing_id)
        where (event_type = 'filter_alert_listing_match')
    do nothing;
exception
    when no_data_found then
        return;
end;
$$;

comment on function public.enqueue_filter_alert_notification_events_for_listing(uuid) is
    'P1 M1.4: inserts filter_alert_listing_match rows for saved_searches subscribers; '
    'dedupes one event per recipient+listing; service_role/trigger only.';

revoke all on function public.enqueue_filter_alert_notification_events_for_listing(uuid) from public;
revoke all on function public.enqueue_filter_alert_notification_events_for_listing(uuid) from anon;
revoke all on function public.enqueue_filter_alert_notification_events_for_listing(uuid)
    from authenticated;
