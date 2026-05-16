-- Carzon — VIN Phase 2C scheduler: recurring invoke of Edge Function `process-vin-decode-jobs`
-- via pg_cron + pg_net. Headers use Supabase Vault only (no literals in-repo).
--
-- Prerequisites (one-time per environment, after migration applies):
--   1. Enable extensions **pg_net** and **pg_cron** on the project if not already
--      (Dashboard → Database → Extensions, or rely on `CREATE EXTENSION IF NOT EXISTS` below).
--   2. Store two Vault secrets (Dashboard → Project Settings → Vault, or SQL):
--        • name **carzon_process_vin_decode_jobs_url**
--          value: full URL, e.g.
--          https://<PROJECT_REF>.supabase.co/functions/v1/process-vin-decode-jobs
--        • name **carzon_process_vin_decode_jobs_secret**
--          value: same string as Edge secret **CARZON_PROCESS_VIN_DECODE_JOBS_SECRET**
--
--   Example (run in SQL Editor; replace placeholders, never commit real values):
--     select vault.create_secret(
--       '<FULL_FUNCTION_URL>',
--       'carzon_process_vin_decode_jobs_url',
--       'Carzon: POST target for process-vin-decode-jobs'
--     );
--     select vault.create_secret(
--       '<INTERNAL_SECRET_MATCHING_EDGE_ENV>',
--       'carzon_process_vin_decode_jobs_secret',
--       'Carzon: x-carzon-internal-secret header value'
--     );
--
-- Until both secrets exist, the worker function raises WARNING and skips HTTP (no crash).
--
-- Cadence: every **5 minutes** to limit NHTSA / external decode traffic. The Edge worker
-- still enforces batch semantics and decoder mode (**CARZON_VIN_DECODER_MODE**).
--
-- See docs/ops_vin_decode_jobs.md for hosted verification.

------------------------------------------------------------------------------
-- Extensions (hosted Supabase: safe if already enabled)
------------------------------------------------------------------------------

create extension if not exists pg_net;
create extension if not exists pg_cron;

create extension if not exists supabase_vault cascade;

------------------------------------------------------------------------------
-- Worker: read URL + secret from Vault; POST with x-carzon-internal-secret
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
    'VIN Phase 2C: invoked by pg_cron every 5 minutes; POSTs to process-vin-decode-jobs using Vault-backed URL and x-carzon-internal-secret. Not for PostgREST/clients.';

revoke all on function public.carzon_invoke_process_vin_decode_jobs_worker() from public;
revoke all on function public.carzon_invoke_process_vin_decode_jobs_worker() from anon;
revoke all on function public.carzon_invoke_process_vin_decode_jobs_worker()
    from authenticated;

------------------------------------------------------------------------------
-- pg_cron: every 5 minutes (conservative cadence for decode providers)
------------------------------------------------------------------------------

do $cron$
declare
    jid bigint;
begin
    select j.jobid into jid
      from cron.job j
     where j.jobname = 'carzon_process_vin_decode_jobs_5m'
     limit 1;

    if jid is not null then
        perform cron.unschedule(jid);
    end if;
end
$cron$;

select cron.schedule(
    'carzon_process_vin_decode_jobs_5m',
    '*/5 * * * *',
    $$select public.carzon_invoke_process_vin_decode_jobs_worker();$$
);
