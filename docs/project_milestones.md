# Carzon Project Milestones

Living anchor for **what shipped**, **what was fixed recently**, **release gates**, and **what stays out of scope**. Russian-first, Moldova / Transnistria automotive marketplace — [RELEASE.md](RELEASE.md) and [mvp_release_checklist.md](mvp_release_checklist.md) remain the operational release references.

---

## 1. Product direction

- Specialized **automotive** marketplace (structured listings, seller-focused UX), not generic classifieds.
- **Russian-first**, **mobile-first**.
- **Moldova / Transnistria** market positioning (regions, exchange readiness context).
- **Clean premium UX**, **trust-first** framing without overstating guarantees.
- **Structured listings**, **seller usability**, **exchange readiness**.
- **Free at launch**; avoid premature advanced features (payments, dealer tooling, intelligence layers).

---

## 2. Current stage

- **Release candidate / feature scope closed (27 July 2026).**
- **Hosted Supabase parity:** **71/71** local migrations applied. Latest:
  **`20260823120000_retain_pseudonymized_moderation_reports.sql`**.
- **Moderation retention verified on hosted:** all four report foreign keys use
  `ON DELETE SET NULL`; original-evidence snapshots, immutability trigger, and
  expected function security configuration are present.
- **No additional hosted SQL is pending from the current local migration
  chain.**
- **Focus now:** owner-managed branch integration, signed iOS
  release-candidate build, TestFlight upload, and physical-device/manual
  release QA. The application is not yet declared production-ready.
- **Android identity and release signing remain a separate release track if an
  Android release is pursued.**

---

## 3. Completed foundation areas

- [x] Flutter + Supabase app
- [x] Feature-first architecture, **GetIt** DI, **Bloc/Cubit**
- [x] Repository layer + **`Result<T>`**
- [x] Auth flows (sign-in, sign-up, password reset path)
- [x] Listings feed, **listing details**, gallery / multi-image
- [x] Create listing, edit listing, **My listings**
- [x] **Favorites**
- [x] **Messaging MVP** (text, inbox, thread; polling — no Realtime)
- [x] **Unread** state (RPC-backed)
- [x] Seller **public profile**, avatar, trust-light surfaces
- [x] Browse **filters**, **local last-applied** filter persistence
- [x] **Single** filter-alert foundation (`filter_alert_settings`; one row per user)
- [x] **Notifications Phase 1:** DB **`notification_preferences`** + **`user_push_tokens`**, SECURITY DEFINER RPCs, Flutter **`NotificationsRepository`** (RPC-only).
- [x] **Notifications Phase 2 (FCM client prep):** `firebase_core` + `firebase_messaging`, **`PUSH_NOTIFICATIONS_ENABLED`** (default off), **`PushNotificationRegistrationService`** + **`FirebasePushMessagingClient`** (via **`NotificationsRepository`** RPCs only), **no OS permission on cold start**, pre-sign-out token deactivation — **end-to-end delivery** requires Phase 3A/3E + 4A + ops (see below).
- [x] **Notifications Phase 3A + 3E (message push):** queue + **`process-message-notifications`**, pg_cron + Vault — see **RELEASE.md** / **ops_message_notifications.md**. Real-device smoke pending.
- [x] **Notifications Phase 4A (filter alert backend):** matching, enqueue, dedup, **`process-filter-alert-notifications`**, second cron + Vault — migration **`20260601120000_...`**. Real-device smoke pending.
- [x] **Notifications Phase 4B (filter alert client):** filter editor + notification settings toggles, explicit OS permission, `notifications_enabled` persistence, tap + foreground generic copy — real-device smoke pending.
- [x] Release docs: [RELEASE.md](RELEASE.md), [mvp_release_checklist.md](mvp_release_checklist.md)
- [x] **Seller contact exposure hardening** — migration `20260630120000`; hosted SQL metadata PASS; simulator smoke PASS
- [x] **Hosted migration parity** — **71/71** local migrations applied through moderation-report retention (verified 27 July 2026); prior **45/45**, **65**, and **68** references are historical baselines only
- [x] **Fuel Prices v1** — Flutter read-only UI + hosted SQL/Edge/cron/Vault closed; see **`docs/ops_fuel_price_jobs.md`**
- [x] **Hosted runtime contract audit** — all app-critical objects PASS
- [x] **Listings pagination failure UX** — retry footer implemented and tested
- [x] **VIN Phase 1–2** — optional VIN entry, owner/buyer report surfaces (repo + hosted runtime)

---

## 4. Recently completed fixes / audits

- **Hosted backend hardening closure (2026-06)** — contact hardening applied; `check_contact_hardening.sql` PASS; migration parity **45/45 PASS at that time** (metadata reconciliation — prior STOP was drift only); `check_hosted_runtime_contracts.sql` PASS. **Superseded (2026-06-22):** hosted count is now **68** after Fuel Prices v1 (see §4 Fuel Prices bullet).
- **Feed → listing details Hero** — cold flicker addressed: first-image continuity, stable `PageView`, Hero-bound path skips `AnimatedOpacity`, `gaplessPlayback` on Hero-bound images.
- **Listing details dark mode** — removed forced-light scaffold/panels; theme-aware surfaces (see listing details page).
- **Supabase hosted parity** — **closed (27 July 2026):** **71/71** local migrations applied; latest **`20260823120000_retain_pseudonymized_moderation_reports.sql`**. Hosted moderation-retention verification passed (four nullable foreign keys use `ON DELETE SET NULL`; original-evidence snapshots and immutability protection are present with the expected function security settings). No additional SQL remains pending from the current local chain. Re-run maintenance helpers after future hosted changes. Historical **45/45**, **65**, and **68** counts are superseded.
- **Fuel Prices hosted closure (2026-06-22)** — migrations `20260822120000`, `20260822123000`, `20260822130000` applied; Edge **`process-fuel-price-jobs`** v3; cron **`carzon_process_fuel_price_jobs_6h`** (`0 */6 * * *`); no pending Fuel Prices SQL/Edge deploy. Ops follow-up: first automatic cron observation in `cron.job_run_details` (non-blocker).
- **`listings.updated_at`** — drift closed: fixed on hosted DB; repo migration **`20260524120000_listings_updated_at.sql`**; release docs updated.
- **Layout / listing details** — small-phone + keyboard + sticky-footer hardening on high-traffic surfaces; fullscreen details gallery (**swipe / pinch-zoom / dismiss**).
- **Create/edit gallery uploads** — best-effort **partial-batch** Storage cleanup when a later photo fails mid-sequence; RPC failure-after-upload cleanup unchanged.
- **User-facing errors** — continued emphasis on **`l10n` / failure-kind** surfaces rather than raw wire text.
- **Explicit Postgres `GRANT`s for Data API** — forward-only migration **`20260525120000_explicit_data_api_grants.sql`** plus static guard **`test/supabase/explicit_data_api_grants_migration_test.dart`** so new `public` tables/functions stay reachable under tightened Supabase defaults (**RLS unchanged; not proven on hosted DB by static tests alone**).
- **Notifications Phase 3A (message delivery pipeline)** — migration **`20260528120000_...`**, Edge **`process-message-notifications`**, static tests; internal queue tables **not** granted to anon/authenticated. **Phase 4A** adds filter-alert enqueue/claim + second worker ( **`20260601120000_...`** ).

## 5. Current release blockers / remaining before launch

**Closed (2026-06):** ~~contact hardening unapplied~~, ~~hosted migration parity unknown~~, ~~pagination failure UX open~~.

**Still open:**

- [ ] Replace Supabase Auth **Site URL** (`localhost` unacceptable for public release) with a real **HTTPS** fallback/domain per [mvp_release_checklist.md](mvp_release_checklist.md) / [RELEASE.md](RELEASE.md).
- [ ] **Structured manual smoke QA** against the **target** Supabase project:
  - Sign up / sign in
  - Password reset deep link (`carzon://auth-callback`)
  - Browse feed
  - Listing details open / back
  - Create listing with images
  - Edit listing / images
  - My listings ownership flows
  - Favorites
  - Messaging start / thread / unread
  - Filter apply / reset / persistence
- **Filter alert save / reset**; **filter-alert notification toggles** (explicit permission); hosted queue smoke optional via SQL (**`ops_message_notifications.md`**).
- [ ] Dark mode quick pass (beyond listing details if needed)
- [ ] Small phone / keyboard / sticky footer QA
- [ ] Image upload failure / slow network QA
- [ ] Ensure **no raw** backend / PostgREST errors shown to users

---

## 6. Known limitations accepted for MVP

- **Message + filter-alert push:** real-device FCM/APNs smoke (permission, background/quit/foreground, tap routes, generic copy only) after **`PUSH_NOTIFICATIONS_ENABLED=true`** and both Edge workers + schedules live — see **RELEASE.md** / **ops_message_notifications.md**. **Not** declared production-live until smoke passes.
- No **Realtime** messaging subscriptions
- No **chat attachments** (do not reuse public listing/avatar buckets)
- No payments / escrow
- No dealer cabinets
- No ratings / reviews / “verified” as enforceable claims
- **VIN decode/report:** implemented in app + hosted runtime; external provider depth and anti-abuse remain future work — not “no VIN”
- No price intelligence
- No web client
- No admin moderation console (reports via mailto where configured)
- **Public** listing cover/gallery URLs and seller avatars scrapable by design; **direct** contact column SELECT hardened (2026-06); contact via RPC remains anon-callable (product decision)
- Seed/demo listings may use **`seller_id = null`** (not editable as owner in app)

---

## 7. Deferred Stage 2 candidates

*(Future — only after Foundation stable and product decision.)*

- Filter-alert delivery polish / scaling (backend queue exists — Phase 4A)
- Push beyond **message** notifications (**Phase 3B+:** filter alerts, richer routing, foreground display, etc.)
- Stronger seller tools, richer **exchange** flow
- Honest trust signals (without fake badges)
- Compare cars — **only if** simple and justified
- Lightweight utilities after core stability

**Product constraint:** MVP does **not** ship multiple **saved searches / saved filters UI**. Exactly **one** alert-filter foundation (`filter_alert_settings`); no sprawling saved-search product surface.

---

## 8. Deferred Stage 3 / no-go for now

- VIN decode / autofill, vehicle history APIs
- Price intelligence, dealer mode
- Monetization / promotions
- Web client, advanced moderation / admin
- Verification / anti-duplicate at scale
- Insurance / customs / registration utilities

---

## 9. Architecture guardrails

- No Supabase calls **directly from widgets** — datasources/repos only.
- **No service role key** in Flutter; anon + RLS only.
- User-visible strings via **l10n**.
- Repositories return **`Result<T>`** for async boundaries.
- Keep **feature-first** layout; avoid unrelated refactors / broad format churn.
- No heavy dependencies without clear need.
- **No saved searches UI** in MVP.
- Filter-alert **`notifications_enabled`** is user-controlled when push infrastructure is deployed; defaults remain **false** until the user opts in.
- Public seller profile must **not** expose private email.
- Future private chat media → **dedicated** private bucket — **not** `listing-images` / `seller-avatars`.
- **Supabase Data API / PostgREST:** any new **`public`** table or client-called function added in a migration must ship explicit **`GRANT`** / **`GRANT EXECUTE`** (same migration or paired grants migration). **`GRANT`** gates object access; **RLS** gates rows — both are required. Internal trigger helpers must not retain unnecessary **`EXECUTE`** for **`anon` / `authenticated`** — document exemptions in **`test/supabase/explicit_data_api_grants_migration_test.dart`**. **`service_role`** is not bundled in Flutter.

---

## 10. Suggested next task order

1. Auth **Site URL** / production HTTPS config audit — [`docs/auth_site_url_redirect_configuration.md`](auth_site_url_redirect_configuration.md), then [`docs/auth_deeplink_qa.md`](auth_deeplink_qa.md)
2. Structured end-to-end release smoke on target project (device)
3. Auth / password-reset deep link device QA (`docs/auth_deeplink_qa.md`)
4. Media picker / upload device QA (`docs/media_picker_upload_qa.md`)
5. Push device QA **if** `PUSH_NOTIFICATIONS_ENABLED=true` (`docs/notifications_qa.md`)
6. Dark mode / small phone / keyboard regression pass
7. Final pass: [mvp_release_checklist.md](mvp_release_checklist.md) + [RELEASE.md](RELEASE.md)
8. Only then — Stage 2 planning (explicit product decision)
