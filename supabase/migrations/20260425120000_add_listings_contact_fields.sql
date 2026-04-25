-- Carzon — seller contact fields on listings (MVP).
--
-- Scope: listing-level contact for the MVP marketplace loop.
-- Intentionally out of scope:
--   * profiles table / seller profile page
--   * in-app chat / messaging tables
--   * edit-listing UI (contact fields are captured at create time and
--     cannot currently be updated by the owner — the existing RLS has
--     no listings UPDATE policy and this migration does NOT add one)
--
-- Product decision driving this shape:
--   * Phone is required in the Flutter form, but the DB column is
--     nullable so existing rows and seed data can be backfilled safely.
--   * Telegram username is optional.
--   * WhatsApp is a boolean opt-in bound to the same contact_phone.
--
-- Security:
--   * Existing RLS policies are untouched. Contact fields ride along
--     with `listings_public_read_active` and `listings_select_own`,
--     which is the desired behavior: active listings publish the
--     contact; hidden/sold/archived listings keep it owner-only.
--   * No UPDATE or DELETE policies are added.

alter table public.listings
    add column if not exists contact_phone     text,
    add column if not exists telegram_username text,
    add column if not exists whatsapp_enabled  boolean not null default false;

-- Light CHECK constraints — permissive on purpose; strict normalization
-- is the Flutter form's responsibility.
alter table public.listings
    drop constraint if exists listings_contact_phone_chk;
alter table public.listings
    add constraint listings_contact_phone_chk check (
        contact_phone is null
        or length(regexp_replace(contact_phone, '[^0-9]', '', 'g')) >= 7
    );

alter table public.listings
    drop constraint if exists listings_telegram_username_chk;
alter table public.listings
    add constraint listings_telegram_username_chk check (
        telegram_username is null
        or telegram_username ~ '^@?[A-Za-z0-9_]{5,32}$'
    );
