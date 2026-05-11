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

- **Stage 1 / Foundation** — largely implemented.
- **Focus now:** release hardening, hosted parity, manual smoke QA — **not** feature expansion.

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
- [x] Profile alert row with **local-only** notification switch (no backend delivery)
- [x] Release docs: [RELEASE.md](RELEASE.md), [mvp_release_checklist.md](mvp_release_checklist.md)

---

## 4. Recently completed fixes / audits

- **Feed → listing details Hero** — cold flicker addressed: first-image continuity, stable `PageView`, Hero-bound path skips `AnimatedOpacity`, `gaplessPlayback` on Hero-bound images.
- **Listing details dark mode** — removed forced-light scaffold/panels; theme-aware surfaces (see listing details page).
- **Supabase hosted parity** — live verification: tables/RLS, storage buckets/policies, RPCs/grants/signatures, `filter_alert_settings`; Auth redirect allow-list includes **`carzon://auth-callback`** (with env-driven `SUPABASE_PASSWORD_RESET_REDIRECT_URL` pattern).
- **`listings.updated_at`** — drift closed: fixed on hosted DB; repo migration **`20260524120000_listings_updated_at.sql`**; release docs updated.
- **Layout / listing details** — small-phone + keyboard + sticky-footer hardening on high-traffic surfaces; fullscreen details gallery (**swipe / pinch-zoom / dismiss**).
- **Create/edit gallery uploads** — best-effort **partial-batch** Storage cleanup when a later photo fails mid-sequence; RPC failure-after-upload cleanup unchanged.
- **User-facing errors** — continued emphasis on **`l10n` / failure-kind** surfaces rather than raw wire text.

---

## 5. Current release blockers / remaining before launch

- [ ] Replace Supabase Auth **Site URL** (`localhost` unacceptable for public release) with a real **HTTPS** fallback/domain per [mvp_release_checklist.md](mvp_release_checklist.md) / [RELEASE.md](RELEASE.md).
- [ ] **Manual smoke QA** against the **target** Supabase project:
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
  - Filter alert save / reset
  - Profile alert switch remains **local-only** (no expectation of push)
- [ ] Dark mode quick pass (beyond listing details if needed)
- [ ] Small phone / keyboard / sticky footer QA
- [ ] Image upload failure / slow network QA
- [ ] Ensure **no raw** backend / PostgREST errors shown to users

---

## 6. Known limitations accepted for MVP

- No **real push** notifications
- No **real filter-alert delivery** (criteria stored; matching/delivery deferred)
- No **Realtime** messaging subscriptions
- No **chat attachments** (do not reuse public listing/avatar buckets)
- No payments / escrow
- No dealer cabinets
- No ratings / reviews / “verified” as enforceable claims
- No VIN / history / price intelligence
- No web client
- No admin moderation console (reports via mailto where configured)
- **Public** listing + avatar media scrapable by design
- Seed/demo listings may use **`seller_id = null`** (not editable as owner in app)

---

## 7. Deferred Stage 2 candidates

*(Future — only after Foundation stable and product decision.)*

- Real filter-alert **backend matching** + delivery strategy
- Push notification strategy
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
- Flutter must **not** write **`notifications_enabled = true`** until backend matching + push exists (today writes keep it **false**).
- Public seller profile must **not** expose private email.
- Future private chat media → **dedicated** private bucket — **not** `listing-images` / `seller-avatars`.

---

## 10. Suggested next task order

1. Manual smoke QA on **target** Supabase project  
2. Auth / password-reset deep link smoke (`carzon://auth-callback` + dashboard allow-list)  
3. Dark mode / small phone / keyboard QA  
4. Image upload failure / slow network QA  
5. Copy / error-state audit — no raw backend errors to users  
6. Final pass: [mvp_release_checklist.md](mvp_release_checklist.md) + [RELEASE.md](RELEASE.md)  
7. Only then — Stage 2 planning (explicit product decision)
