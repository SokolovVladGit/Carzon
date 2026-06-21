-- Carzon — P2 V1: price drop alerts for favorites (queue + enqueue on listing edit).
--
-- • Adds notification_preferences.price_drops_enabled (default false).
-- • New event_type price_drop_favorite on notification_delivery_events.
-- • Enqueues on update_listing_details_v2 when active listing price decreases (same currency).
-- • Edge Function process-price-drop-notifications claims rows via dedicated RPC.
-- • pg_cron worker POST via Vault (safe skip when secrets missing).
--
-- Prerequisites (one-time per environment, after migration applies):
--   Vault secrets:
--     • carzon_process_price_drop_notifications_url
--     • carzon_process_price_drop_notifications_secret
--   Edge secret CARZON_PROCESS_PRICE_DROP_NOTIFICATIONS_SECRET must match Vault secret.

------------------------------------------------------------------------------
-- 1 — notification_preferences.price_drops_enabled
------------------------------------------------------------------------------

alter table public.notification_preferences
    add column if not exists price_drops_enabled boolean not null default false;

comment on column public.notification_preferences.price_drops_enabled is
    'Opt-in for push when a favorited listing price decreases (requires global_enabled).';

------------------------------------------------------------------------------
-- 2 — Extend event_type check constraint
------------------------------------------------------------------------------

alter table public.notification_delivery_events
    drop constraint if exists notification_delivery_events_event_type_chk;

alter table public.notification_delivery_events
    add constraint notification_delivery_events_event_type_chk check (
        event_type in (
            'message_created',
            'filter_alert_listing_match',
            'price_drop_favorite'
        )
    );

------------------------------------------------------------------------------
-- 3 — Dedup: one queue row per recipient + listing + new price transition
------------------------------------------------------------------------------

create unique index if not exists notification_delivery_events_price_drop_dedup_idx
    on public.notification_delivery_events (
        recipient_user_id,
        listing_id,
        (payload->>'new_price_eur')
    )
    where (event_type = 'price_drop_favorite');

------------------------------------------------------------------------------
-- 4 — Enqueue helper (no network)
------------------------------------------------------------------------------

create or replace function public.enqueue_price_drop_favorite_notification_events(
    p_listing_id    uuid,
    p_old_price_eur numeric,
    p_new_price_eur numeric,
    p_seller_id     uuid
)
returns void
language plpgsql
security definer
set search_path = public, pg_temp
as $$
begin
    if p_listing_id is null
       or p_seller_id is null
       or p_old_price_eur is null
       or p_new_price_eur is null then
        return;
    end if;

    if p_new_price_eur >= p_old_price_eur then
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
        'price_drop_favorite',
        f.user_id,
        p_seller_id,
        null,
        null,
        p_listing_id,
        jsonb_build_object(
            'listing_id', p_listing_id,
            'old_price_eur', p_old_price_eur,
            'new_price_eur', p_new_price_eur
        ),
        'pending'
    from public.favorites f
    inner join public.notification_preferences np
        on np.user_id = f.user_id
       and np.global_enabled = true
       and np.price_drops_enabled = true
    where f.listing_id = p_listing_id
      and f.user_id is distinct from p_seller_id
      and exists (
          select 1
            from public.user_push_tokens upt
           where upt.user_id = f.user_id
             and upt.is_active = true
      )
    on conflict (recipient_user_id, listing_id, (payload->>'new_price_eur'))
        where (event_type = 'price_drop_favorite')
    do nothing;
end;
$$;

comment on function public.enqueue_price_drop_favorite_notification_events(uuid, numeric, numeric, uuid) is
    'P2 V1: inserts price_drop_favorite queue rows for favoriting subscribers; service_role/trigger/RPC only.';

revoke all on function public.enqueue_price_drop_favorite_notification_events(uuid, numeric, numeric, uuid)
    from public;
revoke all on function public.enqueue_price_drop_favorite_notification_events(uuid, numeric, numeric, uuid)
    from anon;
revoke all on function public.enqueue_price_drop_favorite_notification_events(uuid, numeric, numeric, uuid)
    from authenticated;

------------------------------------------------------------------------------
-- 5 — RPC: update_my_notification_preferences (4 toggles)
------------------------------------------------------------------------------

drop function if exists public.update_my_notification_preferences(boolean, boolean, boolean);

create or replace function public.update_my_notification_preferences(
    p_global_enabled        boolean,
    p_messages_enabled      boolean,
    p_filter_alerts_enabled boolean,
    p_price_drops_enabled   boolean
) returns public.notification_preferences
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_uid uuid := auth.uid();
    v_row public.notification_preferences;
begin
    if v_uid is null then
        raise exception 'not authenticated'
            using errcode = '28000';
    end if;

    insert into public.notification_preferences (
        user_id,
        global_enabled,
        messages_enabled,
        filter_alerts_enabled,
        price_drops_enabled
    ) values (
        v_uid,
        coalesce(p_global_enabled, false),
        coalesce(p_messages_enabled, false),
        coalesce(p_filter_alerts_enabled, false),
        coalesce(p_price_drops_enabled, false)
    )
    on conflict (user_id) do update
        set global_enabled = excluded.global_enabled,
            messages_enabled = excluded.messages_enabled,
            filter_alerts_enabled = excluded.filter_alerts_enabled,
            price_drops_enabled = excluded.price_drops_enabled,
            updated_at = now()
    returning * into strict v_row;

    return v_row;
end;
$$;

revoke all on function public.update_my_notification_preferences(boolean, boolean, boolean, boolean)
    from public;
revoke all on function public.update_my_notification_preferences(boolean, boolean, boolean, boolean)
    from anon;
grant execute on function public.update_my_notification_preferences(boolean, boolean, boolean, boolean)
    to authenticated;

------------------------------------------------------------------------------
-- 6 — update_listing_details_v2: capture old price + enqueue on decrease
------------------------------------------------------------------------------

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
    p_vin                          text default null
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
    text
) from public;

revoke all on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text, text,
    text
) from anon;

grant execute on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text, text,
    text
) to authenticated;

------------------------------------------------------------------------------
-- 7 — Claim RPC: price drop worker only
------------------------------------------------------------------------------

create or replace function public.claim_price_drop_notification_events_for_processing(
    p_limit integer default 100
)
returns setof public.notification_delivery_events
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
    v_limit integer := coalesce(p_limit, 100);
begin
    if v_limit < 1 or v_limit > 100 then
        v_limit := 100;
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
                 and ne.event_type = 'price_drop_favorite'
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

comment on function public.claim_price_drop_notification_events_for_processing(integer) is
    'P2 V1: claims pending price_drop_favorite rows only; service_role / Edge.';

revoke all on function public.claim_price_drop_notification_events_for_processing(integer)
    from public;
revoke all on function public.claim_price_drop_notification_events_for_processing(integer)
    from anon;
revoke all on function public.claim_price_drop_notification_events_for_processing(integer)
    from authenticated;
grant execute on function public.claim_price_drop_notification_events_for_processing(integer)
    to service_role;

------------------------------------------------------------------------------
-- 8 — pg_cron worker + schedule (Vault; safe skip when secrets missing)
------------------------------------------------------------------------------

create or replace function public.carzon_invoke_process_price_drop_notifications_worker()
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
    where ds.name = 'carzon_process_price_drop_notifications_url'
    limit 1;

    select ds.decrypted_secret into v_secret
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_price_drop_notifications_secret'
    limit 1;

    if v_url is null
       or v_secret is null
       or btrim(v_url) = ''
       or btrim(v_secret) = ''
    then
        raise warning
            'carzon_price_drop_v1: vault secrets carzon_process_price_drop_notifications_url / carzon_process_price_drop_notifications_secret missing or empty; skip process-price-drop-notifications invoke';
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

comment on function public.carzon_invoke_process_price_drop_notifications_worker() is
    'P2 V1: pg_cron POST to process-price-drop-notifications via Vault URL + internal secret header.';

revoke all on function public.carzon_invoke_process_price_drop_notifications_worker() from public;
revoke all on function public.carzon_invoke_process_price_drop_notifications_worker() from anon;
revoke all on function public.carzon_invoke_process_price_drop_notifications_worker()
    from authenticated;

do $cron$
declare
    jid bigint;
begin
    select j.jobid into jid
      from cron.job j
     where j.jobname = 'carzon_process_price_drop_notifications_1m'
     limit 1;

    if jid is not null then
        perform cron.unschedule(jid);
    end if;
end
$cron$;

select cron.schedule(
    'carzon_process_price_drop_notifications_1m',
    '* * * * *',
    $$select public.carzon_invoke_process_price_drop_notifications_worker();$$
);
