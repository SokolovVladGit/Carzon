-- Revoke client-callable EXECUTE on trigger-only helpers.
--
-- PostgREST exposes every function granted to `anon` / `authenticated` as a
-- potential RPC. Trigger helpers must not be invokable that way; they run
-- when the database fires the trigger (e.g. after INSERT under a SECURITY
-- DEFINER writer such as `send_message`), not from the Flutter client.
--
-- `public.touch_conversation_from_message` was historically granted to
-- `authenticated` in messaging Phase 1A and restated in
-- `20260525120000_explicit_data_api_grants.sql`; this migration removes that
-- exposure while leaving the trigger intact.

revoke execute on function public.touch_conversation_from_message() from authenticated;

-- Idempotent: Phase 1A already revoked these; repeat so this file is self-describing.
revoke execute on function public.touch_conversation_from_message() from anon;
revoke all on function public.touch_conversation_from_message() from public;
