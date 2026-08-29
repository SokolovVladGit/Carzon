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
| `SUPABASE_PASSWORD_RESET_REDIRECT_URL` | **Release: yes** | Approved recovery deep link (`carzon://auth-callback`) or production HTTPS fallback. |
| `CARZON_PRIVACY_POLICY_URL` | Canonical default provided | `https://carzon-legal.netlify.app/privacy/`; public, client-safe, overridable. |
| `CARZON_TERMS_OF_SERVICE_URL` | Canonical default provided | `https://carzon-legal.netlify.app/terms/`; public, client-safe, overridable. |
| `CARZON_SUPPORT_URL` | Canonical default provided | `https://carzon-legal.netlify.app/support/`; public, client-safe, overridable. |
| `CARZON_PRIVACY_CHOICES_URL` | Canonical default provided | `https://carzon-legal.netlify.app/privacy-choices/`; public, client-safe, overridable. |
| `CARZON_SUPPORT_EMAIL` | Canonical default provided | `carzonsupport@gmail.com`; public contact shown before login, client-safe, overridable. |
| `CARZON_REPORT_EMAIL` | No | Legacy secondary moderation inbox only. Native listing reporting uses `report_listing` and does not depend on email. |
| `CARZON_LISTING_SHARE_BASE_URL` | **Optional for MVP** | Leave unset until CARZON has an owner-controlled public listing page or universal-link surface. Sharing is hidden when unset. If supplied, it must be a production HTTPS base; never use the legal Netlify host. |
| `PUSH_NOTIFICATIONS_ENABLED` | **Release: yes (explicit true/false)** | Default **off**. Enables **Phase 2** Firebase client bootstrap + **`register_push_token`**. **Live push** still requires hosted pipelines: **messages** — migration **`20260528120000_...`**, Edge **`process-message-notifications`**, FCM secrets, **`20260529120000_...`** cron/Vault (§2b). **Filter alerts** — **`20260601120000_...`**, Edge **`process-filter-alert-notifications`**, same FCM setup, second cron/Vault (see **`ops_message_notifications.md`**). |

**Security**

- **`service_role` keys must never** appear in Flutter config, Dart code, or committed env templates.
- Client config is compile-time via `--dart-define-from-file=.env.client` (see `.env.client.example`). Bundle **only** client-safe values (URL + anon key + optional redirects/report email + optional push flag). **No** `.env` Flutter asset.

See also: `lib/core/config/env.dart` (`Env.requiredKeys`). Optional push flag: `Env.pushNotificationsEnabled`.

Release-mode startup also applies `Env.releaseConfigurationIssues()`. It
rejects invalid or placeholder legal/support URLs and support email, an invalid
password-reset redirect, an invalid configured listing share URL, an
unspecified push flag, and a configured placeholder legacy report email.
Canonical legal/support defaults are production values and are not secrets.

Owner-supplied values still required before archive:

- `SUPABASE_PASSWORD_RESET_REDIRECT_URL` (`carzon://auth-callback` or the
  approved production HTTPS fallback);
- explicit `PUSH_NOTIFICATIONS_ENABLED=true|false` after the release decision;
- optional real `CARZON_REPORT_EMAIL` only if the secondary email route is used.

For the first App Store release, leave `CARZON_LISTING_SHARE_BASE_URL` unset.
The listing Share action remains hidden until an owner-controlled listing page
or universal-link surface exists. Do not point it at
`https://carzon-legal.netlify.app`; that site contains legal/support pages only.

Also confirm that the hosted `admin@carzon.com` support bootstrap account exists
and is operator-controlled. This internal account identifier is separate from
the public App Store Support URL and `carzonsupport@gmail.com` contact inbox.

**Local IDE / terminal:** Copy `.env.client.example` → `.env.client`, fill client-safe values only. In Cursor/VS Code use launch config **Carzon Debug** (see `.vscode/launch.json`). Terminal: `flutter run --dart-define-from-file=.env.client` or `./tools/run_dev.sh`.

---

## 2a. Notifications Phase 2 — Firebase / FCM **client** (no delivery)

**Shipped in app code (not automatic end-to-end push):**

- Dependencies: **`firebase_core`**, **`firebase_messaging`** (see `pubspec.yaml`).
- Env: **`PUSH_NOTIFICATIONS_ENABLED`** (default **false**); see `.env.client.example`.
- Services: **`PushNotificationRegistrationService`**, **`FirebasePushMessagingClient`**, **`PushAuthGate`** — **no** direct `SupabaseClient` calls except via **`NotificationsRepository`** RPCs.
- Bootstrap: starts FCM listener when the flag is on; **does not** show the OS permission dialog on cold start; syncs token when the user is signed in and permission was already **authorized** or **provisional** (iOS).
- Sign-out: **`SignOut`** pre-hook calls **`deactivate_my_push_tokens`** while the session is still valid, then best-effort **`deleteToken`** on the client.

**Implemented in repo (staging/prod parity required for live delivery):**

- **Messages:** Phase 3A/3E queue, Edge worker, prefs **`global_enabled` + `messages_enabled`**, Flutter tap + foreground generic copy, notification settings — **real-device smoke pending** (§2b, **`ops_message_notifications.md`**).
- **Filter alerts:** Phase 4A backend (match/enqueue/dedup, separate claim RPC, Edge **`process-filter-alert-notifications`**, cron/Vault) and **Phase 4B** Flutter (filter + notification settings switches, permission on explicit action, tap to listing detail, foreground generic copy) — **real-device smoke pending**.

**Correct product status:** *Message and filter alert notifications are implemented and hosted schedulers are verified; real-device FCM/APNs smoke is pending before declaring notifications live.*

**External setup before real device token registration**

1. Apply Supabase migrations in order through **`20260527120000_notification_preferences_and_push_tokens.sql`** (and the two grant/revoke migrations before it — see §3).
2. Create a **Firebase** project; enable **Cloud Messaging**; add apps for Android / iOS.
3. **Android:** download **`google-services.json`** into **`android/app/`** (do not commit placeholders). The Gradle plugin **`com.google.gms.google-services`** is applied **only** when this file **exists**, so builds without Firebase still succeed.
4. **iOS:** add **`GoogleService-Info.plist`** via Xcode ; enable **Push Notifications** capability and APNs (development/prod) per Apple + Firebase docs — not verified by CI.
5. Set **`PUSH_NOTIFICATIONS_ENABLED=true`** in `.env.client` and pass **`--dart-define-from-file=.env.client`** for dev builds that should register tokens (requires Firebase plist/json). See **[`mobile_push_setup.md`](mobile_push_setup.md)** for platform checklist.

**Manual SQL reminder:** Token RPCs require **`authenticated`** — confirm `register_push_token` / `deactivate_my_push_tokens` exist on the target project (§5).

---

## 2b. Notifications Phase 3A — **message** push (queue + Edge Function)

**Scope:** inbound **chat** notifications only (`event_type = message_created`). **No** filter-alert matching or sends. Payload is **generic** (Russian title/body + FCM **data** keys: `type`, `conversation_id`, `message_id`, `listing_id` as strings); **no** full message body, **no** email.

**Database (migration `20260528120000_message_notification_delivery_pipeline.sql`):**

- Tables **`public.notification_delivery_events`**, **`public.notification_delivery_attempts`** — **RLS on**, **no** `GRANT` to **`anon` / `authenticated`** (internal; **`service_role`** / Edge only).
- **`enqueue_message_notification_event`**: `AFTER INSERT` on **`public.messages`**; resolves recipient as the **other** participant (buyer ↔ seller); **`ON CONFLICT DO NOTHING`** dedupes per message/recipient.
- **`claim_notification_events_for_processing(integer)`**: atomically claims **`pending`** rows with **`FOR UPDATE SKIP LOCKED`** — **`GRANT EXECUTE … TO service_role`** only.

**Edge Function:** `supabase/functions/process-message-notifications/index.ts`

- **Supabase JWT:** This function is **not** called with a user JWT. Repo **`supabase/config.toml`** sets **`[functions.process-message-notifications] verify_jwt = false`** so the Edge runtime does not require **`Authorization: Bearer …`** before your code runs. **Security** remains **`x-carzon-internal-secret`** (must match **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`**). If deploy does not pick up config, use **`supabase functions deploy process-message-notifications --no-verify-jwt`**.
- **Invoke:** `POST` with header **`x-carzon-internal-secret`** equal to secret **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`** (set in the function’s environment). No **`Authorization`** JWT header is required when **`verify_jwt`** is off for this function. Returns **401** if the internal secret is missing or wrong; **503** if FCM env not configured (does **not** drain the queue in that case).
- **Secrets (never commit):** set in the Edge Function dashboard / deploy env — **not** in Vault:
  - **`SUPABASE_URL`**, **`SUPABASE_SERVICE_ROLE_KEY`**
  - **`CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET`**
  - **FCM:** either **`FCM_SERVICE_ACCOUNT_JSON`** (full service account JSON), **or** **`FCM_PROJECT_ID`** + **`FCM_CLIENT_EMAIL`** + **`FCM_PRIVATE_KEY`** (PEM newlines often escaped as `\n` in the dashboard).
- **Phase 3E (pg_cron):** additional secrets live in **Supabase Vault** (see **`ops_message_notifications.md`**) — **`carzon_process_message_notifications_url`** and **`carzon_process_message_notifications_secret`**. These are **not** Edge env vars; copy the **same** internal secret string into Vault as required there.
- **Processing:** claims batch (default 25); for each event checks **`notification_preferences`** (**`global_enabled`** and **`messages_enabled`** both true); loads active **`user_push_tokens`**; sends FCM HTTP v1 per token; inserts **`notification_delivery_attempts`** rows; **deactivates** tokens on likely permanent FCM errors; marks event **`sent`**, **`skipped`**, **`failed`**, or requeues **`pending`** with **`next_attempt_at`** backoff (cap **8** attempts via **`MAX_SEND_ATTEMPTS`** in code).
- **Operations:** recurring invoke is configured in migration **`20260529120000_schedule_process_message_notifications_cron.sql`** using **pg_cron** + **pg_net** + **Supabase Vault** (URL and **`x-carzon-internal-secret`** value — **never** committed). See **[`ops_message_notifications.md`](ops_message_notifications.md)** for Vault setup, disabling the schedule, manual **`curl`**, and queue inspection. Manual **`curl`** remains supported for debugging.

**Flutter:** optional **`MessageNotificationPushDataKeys`** (`lib/features/messaging/domain/message_notification_push_constants.dart`). **Filter-alert** data keys and tap routing: **`FilterAlertNotificationTapPayload`** / **`AppRoutes.listingDetailsPath`** (see `lib/features/notifications/services/`).

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
15. **`listings.updated_at`** — column + backfill + `NOT NULL` default `now()` + **`listings_set_updated_at`** trigger (`public.set_listings_updated_at()`). Ensures new environments match hosted parity (older chains lacked this column).  
    - **`20260524120000_listings_updated_at.sql`**
16. **Explicit Data API / PostgREST `GRANT`s** — idempotent table + `GRANT EXECUTE` on Flutter-called RPCs so **fresh Supabase projects** keep working as Supabase tightens default privileges on new `public` objects (**RLS remains separate** and mandatory).  
    - **`20260525120000_explicit_data_api_grants.sql`**
17. **Revoke `EXECUTE` on internal trigger helpers** — e.g. `touch_conversation_from_message()` must not be PostgREST-callable; triggers still run under definer/owner context.  
    - **`20260526120000_revoke_internal_trigger_function_execute.sql`**
18. **Notifications Phase 1 (schema only)** — `notification_preferences` + `user_push_tokens` + RPCs (`get_my_notification_preferences`, `update_my_notification_preferences`, `register_push_token`, `deactivate_push_token`, `deactivate_my_push_tokens`). **Phase 2 (Flutter):** optional FCM token registration when **`PUSH_NOTIFICATIONS_ENABLED`** and Firebase platform config exist. Preference defaults in DB remain **false** until product enables them.  
    - **`20260527120000_notification_preferences_and_push_tokens.sql`**
19. **Notifications Phase 3A (message push — DB queue)** — **`notification_delivery_events`** + **`notification_delivery_attempts`**, enqueue trigger on **`messages`**, **`claim_notification_events_for_processing`** ( **`service_role` only**). **Does not** send FCM from Postgres; Edge Function **`process-message-notifications`** required for delivery. **Filter alerts not included.**  
    - **`20260528120000_message_notification_delivery_pipeline.sql`**
20. **Notifications Phase 3E (scheduled Edge invoke)** — **`pg_cron`** job each minute calls **`pg_net`** `POST` to **`process-message-notifications`**, with URL and **`x-carzon-internal-secret`** read from **Supabase Vault** (ops must create secrets; nothing sensitive in SQL).  
    - **`20260529120000_schedule_process_message_notifications_cron.sql`** — runbook **`ops_message_notifications.md`**.

Local **last-applied listing filters** persist on-device (`ListingDiscoveryCriteria` JSON); previewing an alert filter in the listings feed uses **`ListingsFeedLaunch`** so **explicit snapshot > local persisted > default feed**.

**Policy (Supabase Data API exposure):** Every migration that introduces a **`public`** table or a PostgREST-reachable function must include matching **`GRANT`** / **`GRANT EXECUTE`** for the intended roles in that migration or in a clearly paired follow-up migration (see `test/supabase/explicit_data_api_grants_migration_test.dart`). Missing **`GRANT`** fails before RLS is evaluated. **Trigger/maintenance helpers** must not keep **`EXECUTE`** for **`anon` / `authenticated`** if the Flutter app does not call them as RPCs — use a forward-only **`REVOKE`** (see `20260526120000_revoke_internal_trigger_function_execute.sql`). **`service_role`** is not used in Flutter; do not ship the service key in the client. Repo **static SQL tests** do **not** connect to Postgres or prove hosted grants/RLS — verify the target Supabase project after migrations are applied.

**Recently critical filenames (explicit)**

- `20260515120000_seller_profiles_foundation.sql`
- `20260516120000_seller_display_name_self_edit.sql`
- `20260517120000_seller_avatar_self_edit.sql`
- `20260518100000_user_conversation_state.sql`
- `20260520120000_list_inbox_conversations_rpc.sql`
- `20260521120000_listing_specs_description.sql`
- `20260523120000_filter_alert_settings.sql`
- `20260524120000_listings_updated_at.sql`
- `20260525120000_explicit_data_api_grants.sql`
- `20260526120000_revoke_internal_trigger_function_execute.sql`
- `20260527120000_notification_preferences_and_push_tokens.sql`
- `20260528120000_message_notification_delivery_pipeline.sql`
- `20260529120000_schedule_process_message_notifications_cron.sql`

**June 2026 migrations (repo — full inventory through contact hardening)**

Later migrations add **filter-alert notification queue/cron**, **VIN decode/report phases** (`20260616120000` … `20260629120000`), and **public contact projection hardening** (`20260630120000`). **Hosted Carzon (2026-06):** contact hardening closed; parity **45/45 at that baseline** (metadata reconciliation).

**Hosted baseline (verified 27 July 2026):** all **71/71** migrations in that
baseline are applied through
**`20260823120000_retain_pseudonymized_moderation_reports.sql`**. Hosted
moderation-retention verification passed: all four report foreign keys use
`ON DELETE SET NULL`, original-evidence snapshot columns and the immutability
trigger exist, and the affected functions have the expected security/search
path configuration. The Phase 1 release now additionally requires manual
application of
**`20260826120000_app_store_content_moderation_foundation.sql`** before its
client is shipped; see **`docs/ops_content_moderation.md`**. This document does
not claim hosted parity after new local migrations. Fuel Prices operations
remain documented in **`docs/ops_fuel_price_jobs.md`**.

> **Stale doc warning:** Counts of **45/45**, **65**, or **68** describe
> historical hosted baselines, not the current 71/71 state.

**Authoritative pre-release verification** (re-run after any hosted SQL change):

| Helper | Purpose |
|--------|---------|
| `supabase/maintenance/check_hosted_migration_parity.sql` | Repo vs `schema_migrations` metadata (update helper when adding migrations) |
| `supabase/maintenance/check_hosted_runtime_contracts.sql` | App-critical tables/RPCs exist |
| `supabase/maintenance/check_contact_hardening.sql` | Contact column grants + RPC metadata |

Runbooks: `docs/hosted_migration_parity_verification.md`, `docs/hosted_migration_metadata_reconciliation.md` (if parity STOP + runtime PASS), **`docs/ops_fuel_price_jobs.md`** (Fuel Prices worker).

**Verified hosted baseline range:** `20260423120000_create_listings.sql` …
`20260823120000_retain_pseudonymized_moderation_reports.sql` (**71** migrations
at verification time). Newer repository migrations are not covered by that
27 July 2026 parity result.

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

### Notifications (Phase 1 — preferences / tokens; Phase 3A — internal queue)

- [ ] `get_my_notification_preferences`
- [ ] `update_my_notification_preferences` — **authenticated**; does **not** send push.
- [ ] `register_push_token` — **authenticated**; used by Flutter FCM client (Phase 2+).
- [ ] `deactivate_push_token`
- [ ] `deactivate_my_push_tokens`
- [ ] **Internal (not PostgREST for anon/authenticated):** tables **`notification_delivery_events`**, **`notification_delivery_attempts`**; RPC **`claim_notification_events_for_processing`** — **`service_role` / Edge only** (after **`20260528120000_message_notification_delivery_pipeline.sql`**).

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

- [ ] Auth dashboard (**URL Configuration**): **`carzon://auth-callback`** is listed under **Redirect URLs** (password reset + email confirmation must open the app).
- [ ] Auth dashboard: **Site URL** is **not** the default **`http://localhost:3000`** (or other dev placeholder) before any **production / public-facing** rollout — use a **real HTTPS** marketing or fallback site so email links degrade safely if the custom scheme fails.
- [ ] Sign up
- [ ] Sign in / sign out
- [ ] Password recovery ( **`SUPABASE_PASSWORD_RESET_REDIRECT_URL`** + dashboard redirect URLs aligned with **`carzon://auth-callback`** )

### Listings

- [ ] Browse feed
- [ ] Open **listing details** → back navigation; immersive **fullscreen gallery** (swipe between photos, pinch-zoom, dismiss/close).
- [ ] Create listing **with specs**: fuel, displacement, power, drivetrain, registration, multi-line description
- [ ] Open details → verify specs + separate **«Описание»** when non-empty
- [ ] Edit same fields; save via existing edit flow (RPC path)
- [ ] Upload / replace listing images (`listing-images`)
- [ ] Change status / delete from **My Listings**

### Favorites

- [ ] Favorite and unfavorite (**feed / card / details**); confirm **animated/premium toggle** UX (no default loading spinner replacing the chip on happy paths).
- [ ] Confirm rows are scoped to signed-in user (no cross-user visibility via app)

### Filters & alert (Stage 1)

- [ ] **Browse** filters: apply, reset, on-device persistence of last-applied criteria.
- [ ] **Filter alert** (**one criteria per user** via `filter_alert_settings`; **no** saved-searches / multi-saved-filters UI): save and reset; **`notifications_enabled`** remains **false** at the API until real notification delivery exists (Flutter writes keep it **false**).

### Seller profile / avatar

- [ ] Edit public display name
- [ ] Upload avatar; remove avatar
- [ ] Avatar visible: Profile private header (**`PublicSellerIdentityCubit`** path), Menu identity card, listings masthead account button; public seller card/profile reflects URL
- [ ] Confirm **email is not exposed** on public seller surfaces (`get_seller_public_profile`)

### Messaging / unread (**two accounts**)

- [ ] Threads use **polling** (timer-based) MVP updates — **not** Supabase Realtime. **Optional (Phase 3A):** **message** FCM only when Edge + FCM + prefs/tokens + scheduling are configured — **not** filter alerts.
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
- [ ] **Small phone + keyboard**: create/edit listings, browse **filters**, auth forms, messaging composer, listing details bottom actions — no overflow hiding primary buttons; sticky footers usable.

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
    'get_my_notification_preferences',
    'update_my_notification_preferences',
    'register_push_token',
    'deactivate_push_token',
    'deactivate_my_push_tokens',
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
    'updated_at',
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
    'seller_profiles',
    'filter_alert_settings',
    'notification_preferences',
    'user_push_tokens'
  )
ORDER BY tablename;
```

**`filter_alert_settings` columns & notification default**

```sql
SELECT column_name, data_type, column_default, is_nullable
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = 'filter_alert_settings'
ORDER BY ordinal_position;
```

**`filter_alert_settings` RLS policies (spot-check names)**

```sql
SELECT policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename = 'filter_alert_settings'
ORDER BY policyname;
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
- **Message push (Phase 3A):** optional **FCM** for **inbound chat** when Flutter Phase 2 + hosted migration **`20260528120000_...`**, deployed Edge **`process-message-notifications`**, secrets, and scheduling are in place — **generic** notification text only (**no** body in payload). **Filter-alert / saved-search push** not implemented. Without Edge deploy, behavior matches **no push**.
- **Phase 1 DB:** `notification_preferences`, `user_push_tokens`, and RPCs; **Phase 3A DB:** internal queue tables (not client-accessible).
- **No message attachments** (no reuse of listing/avatar buckets for chat media).
- **No** in-app moderation / admin console in this codebase scope.
- **No** functioning seller ratings/reviews UI wired to persisted reviews (trust fields may exist as placeholders).
- Listing **gallery uploads** (`create`/`edit`): **best-effort** Storage cleanup on some failure paths — **not** a transactional guarantee with Postgres RPCs.
- **User-visible errors:** the client should surface **localized** copy (failure kinds / `l10n`); operators should validate common failure flows do **not** show raw PostgREST codes, RPC names, or bucket paths.
- **`listing-images`** and **`seller-avatars`** are **public-readable by design**; URLs may be scraped.
- Repo **tests** hitting static SQL fragments **≠** migrated Supabase project.

---

## 11. Pre-release checklist

- [ ] Staging/production Supabase has **every** migration from `supabase/migrations/` applied **in order**
- [ ] Buckets **`listing-images`** and **`seller-avatars`** exist with expected policies
- [ ] §5 RPC/function list verified (existence + `authenticated`/`anon` grants per migration intent)
- [ ] Listing columns for **specs + description** and **`updated_at`** present on **`public.listings`** (see §7 column spot-check)
- [ ] **Notifications:** Phase 1 tables **`notification_preferences`**, **`user_push_tokens`**; Phase 3A internal **`notification_delivery_events`**, **`notification_delivery_attempts`** after **`20260528120000_message_notification_delivery_pipeline.sql`**. **Live message push** additionally requires deployed Edge **`process-message-notifications`** + FCM secrets + ops scheduling — verify RPCs from §5; **filter-alert delivery still absent**
- [ ] `.env.client` (or CI dart-defines) contains **only** client-safe keys — **no service role key**, FCM server keys, or Edge internal secrets
- [ ] Auth → **Redirect URLs** include **`carzon://auth-callback`**; Auth **Site URL** is a **real HTTPS** fallback (see [`mvp_release_checklist.md`](mvp_release_checklist.md) §C — **never** rely on **`localhost`** for production/public rollout)
- [ ] §6 staging QA passed for the build about to ship
- [ ] Rollback/mitigation understood (§9); team knows who applies emergency DB fixes
