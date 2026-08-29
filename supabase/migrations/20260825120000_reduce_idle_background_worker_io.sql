-- Carzon — suppress idle background-worker HTTP invokes and bound pg_cron history.
--
-- The queue EXISTS checks below are optimization hints only. Existing Edge
-- Function claim RPCs remain the authoritative concurrency mechanism.

------------------------------------------------------------------------------
-- 1 — Message notification worker: due message_created events only
------------------------------------------------------------------------------

create or replace function public.carzon_invoke_process_message_notifications_worker()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_url text;
    v_secret text;
begin
    if not exists (
        select 1
          from public.notification_delivery_events e
         where e.event_type = 'message_created'
           and e.status = 'pending'
           and e.next_attempt_at <= now()
    ) then
        return;
    end if;

    select ds.decrypted_secret into v_url
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_message_notifications_url'
    limit 1;

    select ds.decrypted_secret into v_secret
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_message_notifications_secret'
    limit 1;

    if v_url is null
       or v_secret is null
       or btrim(v_url) = ''
       or btrim(v_secret) = ''
    then
        raise warning
            'carzon_phase_3e: vault secrets carzon_process_message_notifications_url / carzon_process_message_notifications_secret missing or empty; skip process-message-notifications invoke';
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

comment on function public.carzon_invoke_process_message_notifications_worker() is
    'Invoked by the existing one-minute pg_cron schedule; POSTs to process-message-notifications only when a due pending message_created event exists.';

revoke all on function public.carzon_invoke_process_message_notifications_worker() from public;
revoke all on function public.carzon_invoke_process_message_notifications_worker() from anon;
revoke all on function public.carzon_invoke_process_message_notifications_worker()
    from authenticated;

------------------------------------------------------------------------------
-- 2 — Filter-alert notification worker: due filter events only
------------------------------------------------------------------------------

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
    if not exists (
        select 1
          from public.notification_delivery_events e
         where e.event_type = 'filter_alert_listing_match'
           and e.status = 'pending'
           and e.next_attempt_at <= now()
    ) then
        return;
    end if;

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
    'Invoked by the existing one-minute pg_cron schedule; POSTs to process-filter-alert-notifications only when a due pending filter_alert_listing_match event exists.';

revoke all on function public.carzon_invoke_process_filter_alert_notifications_worker() from public;
revoke all on function public.carzon_invoke_process_filter_alert_notifications_worker() from anon;
revoke all on function public.carzon_invoke_process_filter_alert_notifications_worker()
    from authenticated;

------------------------------------------------------------------------------
-- 3 — Price-drop notification worker: due price-drop events only
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
    if not exists (
        select 1
          from public.notification_delivery_events e
         where e.event_type = 'price_drop_favorite'
           and e.status = 'pending'
           and e.next_attempt_at <= now()
    ) then
        return;
    end if;

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
    'Invoked by the existing one-minute pg_cron schedule; POSTs to process-price-drop-notifications only when a due pending price_drop_favorite event exists.';

revoke all on function public.carzon_invoke_process_price_drop_notifications_worker() from public;
revoke all on function public.carzon_invoke_process_price_drop_notifications_worker() from anon;
revoke all on function public.carzon_invoke_process_price_drop_notifications_worker()
    from authenticated;

------------------------------------------------------------------------------
-- 4 — VIN decode worker: due retry-eligible decode jobs only
------------------------------------------------------------------------------

create or replace function public.carzon_invoke_process_vin_decode_jobs_worker()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_url text;
    v_secret text;
begin
    if not exists (
        select 1
          from public.vin_processing_jobs j
         where j.job_type = 'decode'
           and j.status = 'pending'
           and j.next_run_at <= now()
           and j.attempts < j.max_attempts
    ) then
        return;
    end if;

    select ds.decrypted_secret into v_url
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_vin_decode_jobs_url'
    limit 1;

    select ds.decrypted_secret into v_secret
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_vin_decode_jobs_secret'
    limit 1;

    if v_url is null
       or v_secret is null
       or btrim(v_url) = ''
       or btrim(v_secret) = ''
    then
        raise warning
            'carzon_vin_decode_scheduler: vault secrets carzon_process_vin_decode_jobs_url / carzon_process_vin_decode_jobs_secret missing or empty; skip process-vin-decode-jobs invoke';
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-carzon-internal-secret', v_secret
        ),
        body := jsonb_build_object('limit', 10),
        timeout_milliseconds := 30000
    );
end;
$$;

comment on function public.carzon_invoke_process_vin_decode_jobs_worker() is
    'Invoked by the existing five-minute pg_cron schedule; POSTs to process-vin-decode-jobs only when a due retry-eligible decode job exists.';

revoke all on function public.carzon_invoke_process_vin_decode_jobs_worker() from public;
revoke all on function public.carzon_invoke_process_vin_decode_jobs_worker() from anon;
revoke all on function public.carzon_invoke_process_vin_decode_jobs_worker()
    from authenticated;

------------------------------------------------------------------------------
-- 5 — Model-data worker: queued retry-eligible jobs only
------------------------------------------------------------------------------

create or replace function public.carzon_invoke_process_model_data_jobs_worker()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_url text;
    v_secret text;
begin
    if not exists (
        select 1
          from public.vehicle_model_fetch_jobs j
         where j.status = 'queued'
           and j.attempts < j.max_attempts
    ) then
        return;
    end if;

    select ds.decrypted_secret into v_url
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_model_data_jobs_url'
    limit 1;

    select ds.decrypted_secret into v_secret
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_model_data_jobs_secret'
    limit 1;

    if v_url is null
       or v_secret is null
       or btrim(v_url) = ''
       or btrim(v_secret) = ''
    then
        raise warning
            'carzon_model_data_scheduler: vault secrets carzon_process_model_data_jobs_url / carzon_process_model_data_jobs_secret missing or empty; skip process-model-data-jobs invoke';
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-carzon-internal-secret', v_secret
        ),
        body := jsonb_build_object('limit', 10),
        timeout_milliseconds := 30000
    );
end;
$$;

comment on function public.carzon_invoke_process_model_data_jobs_worker() is
    'Invoked by the existing 30-minute pg_cron schedule; POSTs to process-model-data-jobs only when a queued retry-eligible job exists.';

revoke all on function public.carzon_invoke_process_model_data_jobs_worker() from public;
revoke all on function public.carzon_invoke_process_model_data_jobs_worker() from anon;
revoke all on function public.carzon_invoke_process_model_data_jobs_worker()
    from authenticated;

------------------------------------------------------------------------------
-- 6 — Recall-data worker: due retry-eligible jobs only
------------------------------------------------------------------------------

create or replace function public.carzon_invoke_process_recall_data_jobs_worker()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_url text;
    v_secret text;
begin
    if not exists (
        select 1
          from public.vehicle_recall_fetch_jobs j
         where j.status = 'queued'
           and j.run_after <= now()
           and j.attempts < j.max_attempts
    ) then
        return;
    end if;

    select ds.decrypted_secret into v_url
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_recall_data_jobs_url'
    limit 1;

    select ds.decrypted_secret into v_secret
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_recall_data_jobs_secret'
    limit 1;

    if v_url is null
       or v_secret is null
       or btrim(v_url) = ''
       or btrim(v_secret) = ''
    then
        raise warning
            'carzon_recall_data_scheduler: vault secrets carzon_process_recall_data_jobs_url / carzon_process_recall_data_jobs_secret missing or empty; skip process-recall-data-jobs invoke';
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-carzon-internal-secret', v_secret
        ),
        body := jsonb_build_object('limit', 10),
        timeout_milliseconds := 30000
    );
end;
$$;

comment on function public.carzon_invoke_process_recall_data_jobs_worker() is
    'Invoked by the existing 30-minute pg_cron schedule; POSTs to process-recall-data-jobs only when a due retry-eligible job exists.';

revoke all on function public.carzon_invoke_process_recall_data_jobs_worker() from public;
revoke all on function public.carzon_invoke_process_recall_data_jobs_worker() from anon;
revoke all on function public.carzon_invoke_process_recall_data_jobs_worker()
    from authenticated;

------------------------------------------------------------------------------
-- 7 — Fuel-price worker: enqueue refreshes, then invoke only for eligible jobs
------------------------------------------------------------------------------

create or replace function public.carzon_invoke_process_fuel_price_jobs_worker()
returns void
language plpgsql
security definer
set search_path = public
as $$
declare
    v_url text;
    v_secret text;
begin
    perform public.enqueue_all_fuel_price_fetch_jobs();

    if not exists (
        select 1
          from public.fuel_price_fetch_jobs j
         where j.status = 'queued'
           and j.attempts < j.max_attempts
    ) then
        return;
    end if;

    select ds.decrypted_secret into v_url
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_fuel_price_jobs_url'
    limit 1;

    select ds.decrypted_secret into v_secret
    from vault.decrypted_secrets ds
    where ds.name = 'carzon_process_fuel_price_jobs_secret'
    limit 1;

    if v_url is null
       or v_secret is null
       or btrim(v_url) = ''
       or btrim(v_secret) = ''
    then
        raise warning
            'carzon_fuel_price_scheduler: vault secrets carzon_process_fuel_price_jobs_url / carzon_process_fuel_price_jobs_secret missing or empty; skip process-fuel-price-jobs invoke';
        return;
    end if;

    perform net.http_post(
        url := v_url,
        headers := jsonb_build_object(
            'Content-Type', 'application/json',
            'x-carzon-internal-secret', v_secret
        ),
        body := jsonb_build_object('limit', 10),
        timeout_milliseconds := 30000
    );
end;
$$;

comment on function public.carzon_invoke_process_fuel_price_jobs_worker() is
    'Invoked by the existing six-hour pg_cron schedule; enqueues due refreshes and POSTs to process-fuel-price-jobs only when an eligible queued job exists.';

revoke all on function public.carzon_invoke_process_fuel_price_jobs_worker() from public;
revoke all on function public.carzon_invoke_process_fuel_price_jobs_worker() from anon;
revoke all on function public.carzon_invoke_process_fuel_price_jobs_worker()
    from authenticated;

------------------------------------------------------------------------------
-- 8 — Bounded daily retention for completed pg_cron execution history
------------------------------------------------------------------------------

create or replace function public.carzon_cleanup_cron_job_run_details()
returns integer
language plpgsql
security definer
set search_path = pg_catalog, pg_temp
as $$
declare
    v_deleted integer;
begin
    with expired as (
        select d.runid
          from cron.job_run_details d
         where d.end_time is not null
           and d.end_time < now() - interval '14 days'
         order by d.end_time asc, d.runid asc
         limit 10000
    )
    delete from cron.job_run_details d
     using expired e
     where d.runid = e.runid;

    get diagnostics v_deleted = row_count;
    return v_deleted;
end;
$$;

comment on function public.carzon_cleanup_cron_job_run_details() is
    'Internal daily maintenance: deletes at most 10,000 completed pg_cron runs older than 14 days. Historical catch-up remains a separate observed hosted operation.';

revoke all on function public.carzon_cleanup_cron_job_run_details() from public;
revoke all on function public.carzon_cleanup_cron_job_run_details() from anon;
revoke all on function public.carzon_cleanup_cron_job_run_details()
    from authenticated;

do $cron$
declare
    jid bigint;
begin
    select j.jobid into jid
      from cron.job j
     where j.jobname = 'carzon_cleanup_cron_job_run_details_daily'
     limit 1;

    if jid is not null then
        perform cron.unschedule(jid);
    end if;
end
$cron$;

-- pg_cron schedules use UTC on hosted Supabase; 03:17 avoids hour boundaries.
select cron.schedule(
    'carzon_cleanup_cron_job_run_details_daily',
    '17 3 * * *',
    $$select public.carzon_cleanup_cron_job_run_details();$$
);
