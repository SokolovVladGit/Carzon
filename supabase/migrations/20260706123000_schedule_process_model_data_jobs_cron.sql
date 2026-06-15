-- Carzon — Model Passport Phase 1 scheduler: recurring invoke of Edge Function
-- `process-model-data-jobs` via pg_cron + pg_net. Headers use Supabase Vault only.
--
-- Prerequisites (one-time per environment, after migration applies):
--   1. Enable extensions **pg_net** and **pg_cron** if not already enabled.
--   2. Store two Vault secrets (Dashboard → Project Settings → Vault, or SQL):
--        • name **carzon_process_model_data_jobs_url**
--          value: full URL, e.g.
--          https://<PROJECT_REF>.supabase.co/functions/v1/process-model-data-jobs
--        • name **carzon_process_model_data_jobs_secret**
--          value: same string as Edge secret **CARZON_PROCESS_MODEL_DATA_JOBS_SECRET**
--
-- Until both secrets exist, the worker function raises WARNING and skips HTTP (no crash).
--
-- Cadence: every **30 minutes** (conservative; no real EPA HTTP in Phase 1).
--
-- See docs/ops_model_data_jobs.md for hosted verification.

create extension if not exists pg_net;
create extension if not exists pg_cron;
create extension if not exists supabase_vault cascade;

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
    'Model Passport Phase 1: invoked by pg_cron every 30 minutes; POSTs to process-model-data-jobs using Vault-backed URL and x-carzon-internal-secret. Not for PostgREST/clients.';

revoke all on function public.carzon_invoke_process_model_data_jobs_worker() from public;
revoke all on function public.carzon_invoke_process_model_data_jobs_worker() from anon;
revoke all on function public.carzon_invoke_process_model_data_jobs_worker()
    from authenticated;

do $cron$
declare
    jid bigint;
begin
    select j.jobid into jid
      from cron.job j
     where j.jobname = 'carzon_process_model_data_jobs_30m'
     limit 1;

    if jid is not null then
        perform cron.unschedule(jid);
    end if;
end
$cron$;

select cron.schedule(
    'carzon_process_model_data_jobs_30m',
    '*/30 * * * *',
    $$select public.carzon_invoke_process_model_data_jobs_worker();$$
);
