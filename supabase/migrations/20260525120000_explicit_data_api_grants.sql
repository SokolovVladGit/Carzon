-- Carzon — explicit Data API / PostgREST privileges (future-proof baseline).
--
-- Supabase is aligning public schema exposure with explicit PostgreSQL GRANTs for
-- the Data API (PostgREST / generated clients). On fresh projects, new public
-- tables and functions may no longer inherit broad default privileges; missing
-- GRANT fails before Row Level Security policies are evaluated.
--
-- Row Level Security remains the row-level gate; GRANT is the object-level gate.
-- This migration only adds idempotent privileges. It does not change schemas,
-- RLS policies, SECURITY DEFINER bodies, or storage configuration.
--
-- Flutter uses the anon + authenticated keys only (never service_role in-app).

-- ---------------------------------------------------------------------------
-- public tables (aligned with existing RLS — least practical privilege)
-- ---------------------------------------------------------------------------

-- Marketplace feed + details: active listings visible to anon; owners see all statuses when authenticated.
grant select on table public.listings to anon, authenticated;

-- Gallery rows tied to listings readable when parent listing is visible (RLS).
grant select on table public.listing_images to anon, authenticated;

-- Favorites toggling: insert/delete/select own rows only (RLS).
grant select, insert, delete on table public.favorites to authenticated;

-- Messaging: participant read on conversations/messages; writes stay RPC-only (RLS).
grant select on table public.conversations to authenticated;
grant select on table public.messages to authenticated;

-- Unread summaries: clients use RPCs; direct SELECT matches prior migration for diagnostics/tools.
grant select on table public.user_conversation_state to authenticated;

-- Own profile row for account surfaces; public identity via get_seller_public_profile RPC (RLS).
grant select on table public.seller_profiles to authenticated;

-- Alert settings (already granted in 20260523120000 — repeat stays idempotent).
grant select, insert, update, delete on table public.filter_alert_settings to authenticated;

-- ---------------------------------------------------------------------------
-- RPCs / functions callable from Flutter PostgREST (repeat GRANTs = idempotent)
-- ---------------------------------------------------------------------------

grant execute on function public.create_listing(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean, text
) to authenticated;

grant execute on function public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text
) to authenticated;

grant execute on function public.update_listing_details(
    uuid, text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean
) to authenticated;

grant execute on function public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text
) to authenticated;

grant execute on function public.replace_listing_images(uuid, text[], text[]) to authenticated;

grant execute on function public.update_listing_cover_image(uuid, text) to authenticated;

grant execute on function public.set_listing_status(uuid, text) to authenticated;

grant execute on function public.delete_listing(uuid) to authenticated;

grant execute on function public.get_or_create_conversation(uuid) to authenticated;

grant execute on function public.send_message(uuid, text) to authenticated;

grant execute on function public.list_inbox_conversations() to authenticated;

grant execute on function public.mark_conversation_read(uuid) to authenticated;

grant execute on function public.get_unread_conversation_count() to authenticated;

grant execute on function public.get_seller_public_profile(uuid) to anon;

grant execute on function public.get_seller_public_profile(uuid) to authenticated;

grant execute on function public.get_my_seller_profile() to authenticated;

grant execute on function public.update_my_seller_display_name(text) to authenticated;

grant execute on function public.update_my_seller_avatar(text, text) to authenticated;

grant execute on function public.clear_my_seller_avatar() to authenticated;

-- Invoked by message insert trigger; granted for parity with Phase 1A migration.
grant execute on function public.touch_conversation_from_message() to authenticated;
