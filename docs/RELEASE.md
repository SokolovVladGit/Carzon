# Carzon release / staging verification

## 1. Purpose

This checklist verifies **alignment between the Flutter app binary and the target Supabase project** (staging or production): migrations, RPCs, RLS-backed tables, storage buckets, and grants. Passing CI and static SQL tests in the repo does **not** prove a hosted Supabase instance is ready.

Ship the matching client **only after** the backend for that environment exposes the APIs and assets the binary calls.

---

## 2. Required environment variables

| Variable | Required | Notes |
|---------|----------|--------|
| `SUPABASE_URL` | Yes | Project API URL. |
| `SUPABASE_ANON_KEY` | Yes | Public anon key (client-safe). |
| `SUPABASE_PASSWORD_RESET_REDIRECT_URL` | No | Deep-link target for recovery emails (e.g. custom scheme); if unset, Supabase uses project Site URL. |
| `CARZON_REPORT_EMAIL` | No | If unset, in-app listing report mailto is hidden. |

**Security**

- **`service_role` keys must never** appear in Flutter env, Dart code, or committed `.env`.
- `.env` is loaded as part of client configuration; bundle **only** client-safe values (URL + anon key + optional redirects/report email).

See also: `lib/core/config/env.dart` (`Env.requiredKeys`).

---

## 3. Migration order on the Supabase project

Apply **all** files under `supabase/migrations/` to the target project **in timestamp order**. Partial application causes runtime PostgREST/RPC failures.

Rough **dependency chain** (each step maps to migrations in-repo; filenames use `YYYYMMDDHHMMSS_*.sql`):

1. Core schema: **`listings`**, indexes, public read policies.  
   - Starts: `20260423120000_create_listings.sql`
2. **Favorites** table + RLS.  
   - `20260423140000_create_favorites.sql`
3. **Listings** owner read/update paths, **`market_region`**, **`listing-images`** bucket + ownership policies.  
   - Including `20260424140000_listing_images_storage.sql`
4. **RPC-only listing mutations**: `create_listing`, status, legacy update/delete/cover helpers.  
   - Including `20260503120000_create_listing_rpc.sql` (drops naive insert policy — listings writes stay RPC-controlled)
5. **`create_listing_v2`** foundation, **`listing_images`**, **`replace_listing_images`**, **`update_listing_details_v2`** evolution.  
   - `20260504180000_create_listing_v2_foundation.sql`, `20260506140000_update_listing_details_v2_rpc.sql`
6. **Messaging Phase 1A** (`conversations`, `messages`, participant RLS, `get_or_create_conversation`, `send_message`).  
   - `20260510120000_messaging_phase1a.sql`
7. **Listing body type** (columns + RPC extensions).  
   - `20260511120000_listings_body_type.sql`
8. **Seller profiles**, storage **`seller-avatars`**, **`get_seller_public_profile`**, **`ensure_seller_profile`**, etc.  
   - **`20260515120000_seller_profiles_foundation.sql`**
9. Seller **display name** self-edit RPCs (return shape evolves).  
   - **`20260516120000_seller_display_name_self_edit.sql`**
10. Seller **avatar** RPCs (**`update_my_seller_avatar`**, **`clear_my_seller_avatar`**, extended **`get_my_seller_profile`**).  
    - **`20260517120000_seller_avatar_self_edit.sql`**
11. **Unread / read receipts**: **`user_conversation_state`**, **`mark_conversation_read`**, **`get_unread_conversation_count`**.  
    - **`20260518100000_user_conversation_state.sql`**
12. **Inbox**: **`list_inbox_conversations`**. Depends on Phase 1A + unread migration.  
    - **`20260520120000_list_inbox_conversations_rpc.sql`**
13. **Listing specs + description** (`fuel_type`, `engine_*`, `drivetrain`, `registration`, `description`; extended **`create_listing_v2`** / **`update_listing_details_v2`** signatures).  
    - **`20260521120000_listing_specs_description.sql`**
14. **Filter-alert settings foundation** (**no notification delivery**, no push/realtime/background jobs yet): **`filter_alert_settings`** — one row per user (`user_id` PK), nullable JSONB **`criteria`**, **`notifications_enabled`** default false for future infra. Client uses this only from Account → «Оповещения по фильтру».  
    - **`20260523120000_filter_alert_settings.sql`**

Local **last-applied listing filters** persist on-device (`ListingDiscoveryCriteria` JSON); previewing an alert filter in the listings feed uses **`ListingsFeedLaunch`** so **explicit snapshot > local persisted > default feed**.

Repo **static SQL tests** validate migration text only — they **do not** enforce hosted RLS/parity.

**Recently critical filenames (explicit)**

- `20260515120000_seller_profiles_foundation.sql`
- `20260516120000_seller_display_name_self_edit.sql`
- `20260517120000_seller_avatar_self_edit.sql`
- `20260518100000_user_conversation_state.sql`
- `20260520120000_list_inbox_conversations_rpc.sql`
- `20260521120000_listing_specs_description.sql`
- `20260523120000_filter_alert_settings.sql`

**Important**

- Migrations targeting staging/prod must be **applied before** releasing an app build that relies on those RPCs/columns/buckets.
- Repo **static migration tests** assert SQL file contents; they **do not** connect to the hosted Supabase project.

---

## 4. Required Storage buckets

| Bucket ID | Visibility | Owner write scope | MVP note |
|-----------|-------------|-------------------|----------|
| `listing-images` | Public read (`anon` + `authenticated`) | Paths constrained to **`listings/<auth.uid()>/**`** per policies in `20260424140000_listing_images_storage.sql` | Listing photos intended for **`Image.network`**. |
| `seller-avatars` | Public read | Paths constrained to **`avatars/<auth.uid()>/**`** per `20260515120000_seller_profiles_foundation.sql` | Profile photos separate from listings. |

**Product rule**

- **Chat attachments are not implemented.** Do **not** store chat media in `listing-images` or `seller-avatars` buckets (migration comments anticipate a future dedicated private bucket).

---

## 5. RPC / function verification checklist

Confirm each exists (`Database → Extensions / Functions` or SQL below), **`EXECUTE`** granted appropriately (typically **`authenticated`**, not **`anon`** for mutators), and behavior matches migrations.

### Listings / images / status

- [ ] `create_listing_v2` — extended signature must match latest migration (listing specs/description).
- [ ] `update_listing_details_v2` — same (trailing optional params).
- [ ] `update_listing_cover_image`
- [ ] `replace_listing_images`
- [ ] `set_listing_status`
- [ ] `delete_listing`

### Messaging / unread

- [ ] `get_or_create_conversation`
- [ ] `send_message`
- [ ] `mark_conversation_read`
- [ ] `get_unread_conversation_count`
- [ ] `list_inbox_conversations`

### Seller (public vs self)

- [ ] `get_seller_public_profile` — gated summary; **no email** returned (see migration comments).
- [ ] `get_my_seller_profile`
- [ ] `update_my_seller_display_name`
- [ ] `update_my_seller_avatar`
- [ ] `clear_my_seller_avatar`

**Security review (manual)**

- Mutators require **`authenticated`** paths; callers unauthenticated receive errors from **`auth.uid()`** checks inside bodies.
- **Listings**: RPCs enforce **seller ownership** / active listing rules as defined per migration (not summarized here — verify in migration body before prod).
- **Messaging**: Participant-only logic; unread RPC respects buyer/seller and excludes self-sent messages per SQL.
- **`SECURITY DEFINER`** functions should use **`SET search_path = public, pg_temp`** (or at least **`public`** as documented); review any new migrations for regressions.

---

## 6. Staging smoke tests (manual QA)

### Auth

- [ ] Sign up
- [ ] Sign in / sign out
- [ ] Password recovery (if **`SUPABASE_PASSWORD_RESET_REDIRECT_URL`** + Auth redirect URLs configured)

### Listings

- [ ] Browse feed
- [ ] Create listing **with specs**: fuel, displacement, power, drivetrain, registration, multi-line description
- [ ] Open details → verify specs + separate **«Описание»** when non-empty
- [ ] Edit same fields; save via existing edit flow (RPC path)
- [ ] Upload / replace listing images (`listing-images`)
- [ ] Change status / delete from **My Listings**

### Favorites

- [ ] Favorite and unfavorite
- [ ] Confirm rows are scoped to signed-in user (no cross-user visibility via app)

### Seller profile / avatar

- [ ] Edit public display name
- [ ] Upload avatar; remove avatar
- [ ] Avatar visible: Profile private header (**`PublicSellerIdentityCubit`** path), Menu identity card, listings masthead account button; public seller card/profile reflects URL
- [ ] Confirm **email is not exposed** on public seller surfaces (`get_seller_public_profile`)

### Messaging / unread (**two accounts**)

- [ ] Buyer starts chat from **active** listing (seller ≠ buyer)
- [ ] Seller sees thread; unread row styling in inbox if applicable
- [ ] Masthead avatar **dot** (if unread count known &gt; 0); Profile Activity **numeric badge** when &gt; 0
- [ ] Opening thread triggers read path; unread clears after sync / navigation as designed
- [ ] Seller **cannot** start chat on **own** listing

### Navigation / UX (sanity)

- [ ] Profile: **no** bottom capsule nav; back works
- [ ] Menu: **bottom nav** remains
- [ ] Create listing / thread: no bottom nav where expected
- [ ] Quick **dark mode** pass

---

## 7. Suggested SQL / read-only smoke checks

Run in Supabase **SQL Editor** — no secrets. Adjust schema if non-`public`.

**Functions exist**

```sql
SELECT p.proname
FROM pg_proc p
JOIN pg_namespace n ON n.oid = p.pronamespace
WHERE n.nspname = 'public'
  AND p.proname IN (
    'create_listing_v2',
    'update_listing_details_v2',
    'update_listing_cover_image',
    'replace_listing_images',
    'set_listing_status',
    'delete_listing',
    'get_or_create_conversation',
    'send_message',
    'mark_conversation_read',
    'get_unread_conversation_count',
    'list_inbox_conversations',
    'get_seller_public_profile',
    'get_my_seller_profile',
    'update_my_seller_display_name',
    'update_my_seller_avatar',
    'clear_my_seller_avatar'
  )
ORDER BY p.proname;
```

**Buckets**

```sql
SELECT id, name, public
FROM storage.buckets
WHERE id IN ('listing-images', 'seller-avatars')
ORDER BY id;
```

**Selected listing columns**

```sql
SELECT column_name
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'listings'
  AND column_name IN (
    'fuel_type',
    'engine_displacement_liters',
    'engine_power_hp',
    'drivetrain',
    'registration',
    'description'
  )
ORDER BY column_name;
```

**RLS enabled (spot-check)**

```sql
SELECT tablename, rowsecurity
FROM pg_tables
WHERE schemaname = 'public'
  AND tablename IN (
    'listings',
    'favorites',
    'listing_images',
    'conversations',
    'messages',
    'user_conversation_state',
    'seller_profiles'
  )
ORDER BY tablename;
```

---

## 8. Recommended deployment order

1. Apply **full** migration chain to **staging** Supabase.
2. Confirm **storage** buckets/policies (dashboard + SQL above).
3. Run **§7** checks + skim critical RPC **`GRANT EXECUTE`** in migrations.
4. Install app build wired to **staging** (`SUPABASE_URL` / anon key).
5. Run **§6** manual QA; fix gaps on backend before promoting.
6. Apply the **same** migration set to **production** during a planned window.
7. Repeat §7 subset + minimal prod sanity (auth ping, single listing read).
8. Roll out production client binaries / stores.
9. Monitor Supabase logs, PostgREST 4xx/5xx spikes, Storage errors.

---

## 9. Rollback notes

- **Client released before migrations**: prioritize **bringing production DB/storage in line** (forward-fix). Flutter cannot recover missing RPC signatures on its own.
- **RPC signatures changed with `DROP FUNCTION`/`CREATE` in migrations**: rolling back DB code is **risky with live data**; prefer forward migrations plus coordinated client versioning.
- **Do not blindly revert** migrations in environments with persistent user/content data unless a DBA-signed plan covers data loss/compatibility.
- **Orphan Storage objects**: failed uploads or partial flows may leave files under seller/listing prefixes; periodic cleanup operations may be needed later — not a blocker for aligning RPC/schema.

---

## 10. Known MVP limitations

- Messaging has **no Realtime channel** wired in the MVP client (`Timer`-based polling in thread where implemented).
- **No push notifications.**
- **No message attachments** (no reuse of listing/avatar buckets for chat media).
- **No** in-app moderation / admin console in this codebase scope.
- **No** functioning seller ratings/reviews UI wired to persisted reviews (trust fields may exist as placeholders).
- **`listing-images`** and **`seller-avatars`** are **public-readable by design**; URLs may be scraped.
- Repo **tests** hitting static SQL fragments **≠** migrated Supabase project.

---

## 11. Pre-release checklist

- [ ] Staging/production Supabase has **every** migration from `supabase/migrations/` applied **in order**
- [ ] Buckets **`listing-images`** and **`seller-avatars`** exist with expected policies
- [ ] §5 RPC/function list verified (existence + `authenticated`/`anon` grants per migration intent)
- [ ] Listing columns for **specs + description** present on **`public.listings`**
- [ ] Messaging tables **`user_conversation_state`**, **`conversations`**, **`messages`** + unread/inbox RPCs present
- [ ] Flutter `.env` contains **only** `SUPABASE_URL`, **`SUPABASE_ANON_KEY`**, optional client-safe overrides — **no service role key**
- [ ] §6 staging QA passed for the build about to ship
- [ ] Rollback/mitigation understood (§9); team knows who applies emergency DB fixes
