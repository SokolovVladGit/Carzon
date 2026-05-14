-- Carzon — Phase 3E: recurring invoke of Edge Function `process-message-notifications`
-- via pg_cron + pg_net. Headers use Supabase Vault only (no literals in-repo).
--
-- Prerequisites (one-time per environment, after migration applies):
--   1. Enable extensions **pg_net** and **pg_cron** on the project if not already
--      (Dashboard → Database → Extensions, or rely on `CREATE EXTENSION IF NOT EXISTS` below).
--   2. Store two Vault secrets (Dashboard → Project Settings → Vault, or SQL):
--        • name **carzon_process_message_notifications_url**
--          value: full URL, e.g.
--          https://<PROJECT_REF>.supabase.co/functions/v1/process-message-notifications
--        • name **carzon_process_message_notifications_secret**
--          value: same string as Edge secret **CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET**
--
--   Example (run in SQL Editor; replace placeholders, never commit real values):
--     select vault.create_secret(
--       '<FULL_FUNCTION_URL>',
--       'carzon_process_message_notifications_url',
--       'Carzon: POST target for process-message-notifications'
--     );
--     select vault.create_secret(
--       '<INTERNAL_SECRET_MATCHING_EDGE_ENV>',
--       'carzon_process_message_notifications_secret',
--       'Carzon: x-carzon-internal-secret header value'
--     );
--
-- Until both secrets exist, the worker function raises WARNING and skips HTTP (no crash).
--
-- Disable schedule: see docs/ops_message_notifications.md

------------------------------------------------------------------------------
-- Extensions (hosted Supabase: safe if already enabled)
------------------------------------------------------------------------------

create extension if not exists pg_net;
create extension if not exists pg_cron;

-- Decrypted secrets view (hosted Supabase: usually present; `CASCADE` pulls deps on fresh stacks).
create extension if not exists supabase_vault cascade;

------------------------------------------------------------------------------
-- Worker: read URL + secret from Vault; POST with x-carzon-internal-secret
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
    'Phase 3E: invoked by pg_cron each minute; POSTs to process-message-notifications using Vault-backed URL and x-carzon-internal-secret. Not for PostgREST/clients.';

revoke all on function public.carzon_invoke_process_message_notifications_worker() from public;
revoke all on function public.carzon_invoke_process_message_notifications_worker() from anon;
revoke all on function public.carzon_invoke_process_message_notifications_worker()
    from authenticated;

------------------------------------------------------------------------------
-- pg_cron: every minute (MVP message queue latency)
------------------------------------------------------------------------------

do $cron$
declare
    jid bigint;
begin
    select j.jobid into jid
      from cron.job j
     where j.jobname = 'carzon_process_message_notifications_1m'
     limit 1;

    if jid is not null then
        perform cron.unschedule(jid);
    end if;
end
$cron$;

select cron.schedule(
    'carzon_process_message_notifications_1m',
    '* * * * *',
    $$select public.carzon_invoke_process_message_notifications_worker();$$
);
