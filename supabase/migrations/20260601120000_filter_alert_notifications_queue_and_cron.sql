-- Carzon — Phase 4A: filter alert notification queue, SQL matching, triggers,
-- type-safe claim RPCs, and pg_cron worker (Vault URL + secret; no literals).
--
-- Prerequisites (one-time per environment, after migration applies):
--   Store two Vault secrets (Dashboard → Project Settings → Vault, or SQL):
--     • name **carzon_process_filter_alert_notifications_url**
--       value: full URL, e.g.
--       https://<PROJECT_REF>.supabase.co/functions/v1/process-filter-alert-notifications
--     • name **carzon_process_filter_alert_notifications_secret**
--       value: same string as Edge secret **CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET**
--
--   Example (SQL Editor; replace placeholders, never commit real values):
--     select vault.create_secret(
--       '<FULL_FUNCTION_URL>',
--       'carzon_process_filter_alert_notifications_url',
--       'Carzon: POST target for process-filter-alert-notifications'
--     );
--     select vault.create_secret(
--       '<INTERNAL_SECRET_MATCHING_EDGE_ENV>',
--       'carzon_process_filter_alert_notifications_secret',
--       'Carzon: x-carzon-internal-secret header'
--     );
--
-- Until both secrets exist, the worker raises WARNING and skips HTTP (no crash).
--
-- • Reuses notification_delivery_events / notification_delivery_attempts.
-- • New event_type: filter_alert_listing_match.
-- • Enqueue on listings INSERT (active) or UPDATE transition into active only.
-- • No HTTP/FCM from Postgres; Edge Function process-filter-alert-notifications
--   claims rows and sends FCM (Phase 4A backend only; UI prefs still default off).
-- • claim_notification_events_for_processing now claims ONLY message_created.
-- • New claim_filter_alert_notification_events_for_processing for filter rows only.

------------------------------------------------------------------------------
-- 1 — Extend event_type check constraint
------------------------------------------------------------------------------

alter table public.notification_delivery_events
    drop constraint if exists notification_delivery_events_event_type_chk;

alter table public.notification_delivery_events
    add constraint notification_delivery_events_event_type_chk check (
        event_type in ('message_created', 'filter_alert_listing_match')
    );

------------------------------------------------------------------------------
-- 2 — Dedup: one filter-alert queue row per recipient + listing
------------------------------------------------------------------------------

create unique index if not exists notification_delivery_events_filter_alert_dedup_idx
    on public.notification_delivery_events (recipient_user_id, listing_id)
    where (event_type = 'filter_alert_listing_match');

------------------------------------------------------------------------------
-- 3 — Criteria matching (parity with Flutter ListingDiscoveryCriteria + feed)
------------------------------------------------------------------------------

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
        if p_listing.title is null or p_listing.title not ilike ('%' || v_search || '%') then
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

    -- typeIn: same semantics as feed `type in (...)` — listing.type must equal at
    -- least one array element. Non-array / malformed: no crash (no constraint).
    -- Empty array: no constraint. Missing key: no constraint.
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

-- Compile / sanity check after migration (SQL Editor; expect true/false only):
--   select public.listing_matches_saved_discovery_criteria(l, '{"schemaVersion":1,"typeIn":["sale"]}'::jsonb)
--     from public.listings l
--    where l.status = 'active'
--    limit 1;

comment on function public.listing_matches_saved_discovery_criteria(public.listings, jsonb) is
    'Phase 4A: JSON criteria vs listings row — mirrors feed filters; sort key ignored; internal only.';

revoke all on function public.listing_matches_saved_discovery_criteria(public.listings, jsonb)
    from public;
revoke all on function public.listing_matches_saved_discovery_criteria(public.listings, jsonb)
    from anon;
revoke all on function public.listing_matches_saved_discovery_criteria(public.listings, jsonb)
    from authenticated;

------------------------------------------------------------------------------
-- 4 — Enqueue matching recipients for one listing (no network)
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
        fas.user_id,
        r.seller_id,
        null,
        null,
        r.id,
        jsonb_build_object('listing_id', r.id),
        'pending'
    from public.filter_alert_settings fas
    inner join public.notification_preferences np
        on np.user_id = fas.user_id
       and np.global_enabled = true
       and np.filter_alerts_enabled = true
    where fas.user_id is distinct from r.seller_id
      and fas.criteria is not null
      and fas.notifications_enabled = true
      and public.listing_matches_saved_discovery_criteria(r, fas.criteria)
      and exists (
          select 1
            from public.user_push_tokens upt
           where upt.user_id = fas.user_id
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
    'Phase 4A: inserts filter_alert_listing_match queue rows for subscribers; service_role/trigger only.';

revoke all on function public.enqueue_filter_alert_notification_events_for_listing(uuid) from public;
revoke all on function public.enqueue_filter_alert_notification_events_for_listing(uuid) from anon;
revoke all on function public.enqueue_filter_alert_notification_events_for_listing(uuid)
    from authenticated;

------------------------------------------------------------------------------
-- 5 — Listing triggers (INSERT active / transition into active)
------------------------------------------------------------------------------

create or replace function public.trigger_enqueue_filter_alert_notifications()
returns trigger
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if tg_op = 'INSERT' then
        if new.status is distinct from 'active' or new.seller_id is null then
            return new;
        end if;
    elsif tg_op = 'UPDATE' then
        if new.status is distinct from 'active' or new.seller_id is null then
            return new;
        end if;
        if not (old.status is distinct from 'active') then
            return new;
        end if;
    else
        return new;
    end if;

    perform public.enqueue_filter_alert_notification_events_for_listing(new.id);
    return new;
end;
$$;

revoke all on function public.trigger_enqueue_filter_alert_notifications() from public;
revoke all on function public.trigger_enqueue_filter_alert_notifications() from anon;
revoke all on function public.trigger_enqueue_filter_alert_notifications() from authenticated;

drop trigger if exists listings_enqueue_filter_alert_notifications_ins on public.listings;
create trigger listings_enqueue_filter_alert_notifications_ins
    after insert on public.listings
    for each row
    execute function public.trigger_enqueue_filter_alert_notifications();

drop trigger if exists listings_enqueue_filter_alert_notifications_upd on public.listings;
create trigger listings_enqueue_filter_alert_notifications_upd
    after update of status on public.listings
    for each row
    execute function public.trigger_enqueue_filter_alert_notifications();

------------------------------------------------------------------------------
-- 6 — Type-safe claim: message worker (message_created only)
------------------------------------------------------------------------------

create or replace function public.claim_notification_events_for_processing(
    p_limit integer
)
returns setof public.notification_delivery_events
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_limit integer := coalesce(p_limit, 10);
begin
    if v_limit < 1 or v_limit > 100 then
        v_limit := 10;
    end if;

    return query
    with claimed as (
        update public.notification_delivery_events e
           set status = 'processing',
               locked_at = now(),
               attempts = e.attempts + 1,
               updated_at = now()
          from (
              select ne.id
                from public.notification_delivery_events ne
               where ne.status = 'pending'
                 and ne.next_attempt_at <= now()
                 and ne.event_type = 'message_created'
               order by ne.created_at asc
               for update skip locked
               limit v_limit
          ) sub
         where e.id = sub.id
        returning e.*
    )
    select * from claimed;
end;
$$;

revoke all on function public.claim_notification_events_for_processing(integer) from public;
revoke all on function public.claim_notification_events_for_processing(integer) from anon;
revoke all on function public.claim_notification_events_for_processing(integer) from authenticated;
grant execute on function public.claim_notification_events_for_processing(integer) to service_role;

------------------------------------------------------------------------------
-- 7 — Type-safe claim: filter alert worker only
------------------------------------------------------------------------------

create or replace function public.claim_filter_alert_notification_events_for_processing(
    p_limit integer
)
returns setof public.notification_delivery_events
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_limit integer := coalesce(p_limit, 10);
begin
    if v_limit < 1 or v_limit > 100 then
        v_limit := 10;
    end if;

    return query
    with claimed as (
        update public.notification_delivery_events e
           set status = 'processing',
               locked_at = now(),
               attempts = e.attempts + 1,
               updated_at = now()
          from (
              select ne.id
                from public.notification_delivery_events ne
               where ne.status = 'pending'
                 and ne.next_attempt_at <= now()
                 and ne.event_type = 'filter_alert_listing_match'
               order by ne.created_at asc
               for update skip locked
               limit v_limit
          ) sub
         where e.id = sub.id
        returning e.*
    )
    select * from claimed;
end;
$$;

comment on function public.claim_filter_alert_notification_events_for_processing(integer) is
    'Phase 4A: claims pending filter_alert_listing_match rows only; service_role / Edge.';

revoke all on function public.claim_filter_alert_notification_events_for_processing(integer)
    from public;
revoke all on function public.claim_filter_alert_notification_events_for_processing(integer)
    from anon;
revoke all on function public.claim_filter_alert_notification_events_for_processing(integer)
    from authenticated;
grant execute on function public.claim_filter_alert_notification_events_for_processing(integer)
    to service_role;

------------------------------------------------------------------------------
-- 8 — pg_cron worker + schedule (Vault; same pattern as message worker)
------------------------------------------------------------------------------

create extension if not exists pg_net;
create extension if not exists pg_cron;
create extension if not exists supabase_vault cascade;

create or replace function public.carzon_invoke_process_filter_alert_notifications_worker()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_url text;
    v_secret text;
begin
    select ds.decrypted_secret into v_url
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_filter_alert_notifications_url'
    limit 1;

    select ds.decrypted_secret into v_secret
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_filter_alert_notifications_secret'
    limit 1;

    if v_url is null
       or v_secret is null
       or btrim(v_url) = ''
       or btrim(v_secret) = ''
    then
        raise warning
            'carzon_phase_4a: vault secrets carzon_process_filter_alert_notifications_url / carzon_process_filter_alert_notifications_secret missing or empty; skip process-filter-alert-notifications invoke';
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-carzon-internal-secret', v_secret
        ),
        body := '{}'::jsonb,
        timeout_milliseconds := 30000
    );
end;
$$;

comment on function public.carzon_invoke_process_filter_alert_notifications_worker() is
    'Phase 4A: pg_cron POST to process-filter-alert-notifications via Vault URL + internal secret header.';

revoke all on function public.carzon_invoke_process_filter_alert_notifications_worker() from public;
revoke all on function public.carzon_invoke_process_filter_alert_notifications_worker() from anon;
revoke all on function public.carzon_invoke_process_filter_alert_notifications_worker()
    from authenticated;

do $cron$
declare
    jid bigint;
begin
    select j.jobid into jid
      from cron.job j
     where j.jobname = 'carzon_process_filter_alert_notifications_1m'
     limit 1;

    if jid is not null then
        perform cron.unschedule(jid);
    end if;
end
$cron$;

select cron.schedule(
    'carzon_process_filter_alert_notifications_1m',
    '* * * * *',
    $$select public.carzon_invoke_process_filter_alert_notifications_worker();$$
);
