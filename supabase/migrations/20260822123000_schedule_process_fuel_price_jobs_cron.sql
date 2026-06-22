-- Carzon — Fuel Prices v1 scheduler: recurring invoke of Edge Function
-- `process-fuel-price-jobs` via pg_cron + pg_net. Headers use Supabase Vault only.
--
-- Prerequisites (one-time per environment, after migration applies):
--   1. Enable extensions **pg_net** and **pg_cron** if not already enabled.
--   2. Store two Vault secrets (Dashboard → Project Settings → Vault, or SQL):
--        • name **carzon_process_fuel_price_jobs_url**
--          value: full URL, e.g.
--          https://<PROJECT_REF>.supabase.co/functions/v1/process-fuel-price-jobs
--        • name **carzon_process_fuel_price_jobs_secret**
--          value: same string as Edge secret **CARZON_PROCESS_FUEL_PRICE_JOBS_SECRET**
--
-- Until both secrets exist, the worker function raises WARNING and skips HTTP (no crash).
--
-- Cadence: every **6 hours** (TTL 24h).

create extension if not exists pg_net;
create extension if not exists pg_cron;
create extension if not exists supabase_vault cascade;

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
    'Fuel Prices v1: invoked by pg_cron every 6 hours; enqueues refresh jobs and POSTs to process-fuel-price-jobs using Vault-backed URL and x-carzon-internal-secret. Not for PostgREST/clients.';

revoke all on function public.carzon_invoke_process_fuel_price_jobs_worker() from public;
revoke all on function public.carzon_invoke_process_fuel_price_jobs_worker() from anon;
revoke all on function public.carzon_invoke_process_fuel_price_jobs_worker()
    from authenticated;

do $cron$
declare
    jid bigint;
begin
    select j.jobid into jid
      from cron.job j
     where j.jobname = 'carzon_process_fuel_price_jobs_6h'
     limit 1;

    if jid is not null then
        perform cron.unschedule(jid);
    end if;
end
$cron$;

select cron.schedule(
    'carzon_process_fuel_price_jobs_6h',
    '0 */6 * * *',
    $$select public.carzon_invoke_process_fuel_price_jobs_worker();$$
);
