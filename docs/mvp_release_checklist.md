# Carzon MVP Release Checklist

A concise, actionable list of everything that must be verified or
configured **outside of `flutter run`** before cutting a staging or
beta release. Work through it top-to-bottom; each item is either a
one-command check or a manual dashboard/device step.

This document is the source of truth for release prep. If something
is missing here, the release is not ready.

**Supabase ↔ client alignment:** Before staging/prod cuts, also follow [`docs/RELEASE.md`](RELEASE.md) for migration apply order, RPC/backend parity with the app binary, storage bucket verification (`listing-images`, `seller-avatars`), and suggested read-only SQL/RPC smoke checks in the Supabase SQL Editor.

## A. Code verification

- [ ] `flutter analyze` reports no issues.
- [ ] `flutter test` — all tests pass.
- [ ] `git status` — no uncommitted app/test changes.
- [ ] No unmerged / unreviewed migrations in `supabase/migrations/`.
- [ ] No uncommitted edits to RLS policies or SECURITY DEFINER RPCs.

## B. Environment variables

Copy `.env.example` to `.env` and fill in real values. Never commit
the populated `.env`.

**Required** (the app fails fast on startup if either is missing):

- `SUPABASE_URL` — the project's API URL.
- `SUPABASE_ANON_KEY` — the project's public anon key.

**Optional but recommended for release**:

- `SUPABASE_PASSWORD_RESET_REDIRECT_URL=carzon://auth-callback` —
  deep-link target for password-reset and email-confirmation emails.
  When absent, Supabase falls back to the project's Site URL.
- `CARZON_REPORT_EMAIL=<real reports inbox>` — destination for the
  in-app "Report listing" mailto action on listing details. When
  absent, the Report action is hidden. Never use the
  `reports@example.com` placeholder in production.

## C. Supabase dashboard setup

Work through the Supabase dashboard for the release project (staging
or production). Apply migrations via the normal workflow —
`supabase db push` or the SQL editor, in chronological order from
`supabase/migrations/`. Do **not** manually edit RLS policies or
grants in the dashboard; all schema/security changes belong in
migrations.

- [ ] **Auth → URL Configuration → Redirect URLs**: add
      `carzon://auth-callback`. Without this, password-reset and
      email-confirmation links will not open the app.
- [ ] **Auth → URL Configuration → Site URL**: set to the
      production/staging web URL so confirmation and reset emails
      carry a sane fallback when native deep links fail.
- [ ] **Auth → Email Templates**: sanity-check the sign-up
      confirmation and password-reset templates for wording and for
      the correct action link placeholder.
- [ ] **Database → Migrations**: confirm all
      `supabase/migrations/*.sql` files from this repo are applied
      and no extra ad-hoc migrations exist in the project.
- [ ] **Storage → Buckets**: confirm the `listing-images` bucket
      exists after migrations. Its public read is intentional for
      MVP (cover images are served by `Image.network`). Writes are
      scoped per-owner by the storage policies — do not widen them.
- [ ] **API → Project Settings**: confirm the anon key in the
      dashboard matches the value in `.env`.

## D. Local / demo data

- `supabase/seed.sql` is synthetic and for local or demo use only.
- Seeded listings have `seller_id = null`; they appear in the public
  feed but are **not editable through the mobile app**.
- Owner flows (create / edit / status change / delete) must be
  exercised with a real authenticated user creating real listings.
- Do **not** import `seed.sql` into production unless the team
  explicitly wants demo listings in the live environment.

## E. Mobile deep-link sanity check

The MVP uses the `carzon://` custom URL scheme registered in
`AndroidManifest.xml` (intent-filter) and iOS `Info.plist`
(`CFBundleURLTypes`).

- [ ] Android physical device: run
      `adb shell am start -a android.intent.action.VIEW -d "carzon://auth-callback"`
      and confirm the installed debug app launches.
- [ ] iOS physical device: tap a `carzon://auth-callback` link from
      Notes or Mail and confirm the app opens.
- [ ] End-to-end: request a password reset, open the email on the
      device, and confirm the app returns to the reset-password
      screen automatically.

Note: custom schemes are MVP-level. Universal Links (iOS) and App
Links (Android) with domain verification are future hardening and
explicitly out of scope for this release.

## F. Core manual smoke test

Run on a real device against the release project before each build.

- [ ] Sign up with a fresh email; observe the "confirm your email"
      UI if confirmation is required.
- [ ] Email confirmation link opens the app and clears the
      `needsEmailConfirmation` state.
- [ ] Sign in with correct credentials; sign out.
- [ ] Forgot password: submit a request; the page shows the neutral
      "If an account exists…" confirmation.
- [ ] Password reset link opens the reset screen; setting a new
      password works and returns the user to a signed-in state.
- [ ] Create listing: fill required fields, submit **without** a
      cover image — listing appears on the feed.
- [ ] Create listing: repeat **with** a cover image — cover renders
      on the details page.
- [ ] Edit listing: change details (price, city, market region,
      contact); save succeeds and the changes show on details.
- [ ] Edit listing: replace cover image; previous object is cleaned
      up best-effort in storage.
- [ ] Edit listing: remove cover image; the placeholder reappears.
- [ ] Owner actions from My Listings: hide, reactivate, mark sold,
      archive, permanent delete. Each surfaces through the
      appropriate RPC and reflects immediately.
- [ ] Public feed shows only `status = active` listings, even for a
      signed-in owner.
- [ ] Region filter: Transnistria / Moldova / Both each return
      plausible results from the seed or live data.
- [ ] Search, make filter, year filter, and type filter still work.
- [ ] Favorites: toggle a favorite while signed in; it appears in
      `/favorites` and persists across app restart.
- [ ] Contact reveal: phone hidden behind "Show phone number" by
      default, Telegram and WhatsApp actions available independently.
- [ ] Tapping the phone opens the dialer; Telegram opens
      `https://t.me/<handle>`; WhatsApp opens `https://wa.me/<digits>`.
- [ ] Report listing: visible only when `CARZON_REPORT_EMAIL` is
      set; tapping opens the mail app with a pre-filled report.
- [ ] Legal page reachable from Sign In, Sign Up, and Profile.

## G. Store / build readiness

- [ ] App name, icon, and splash screen match the release brand.
- [ ] Android release signing configured; `build/app/outputs/bundle/`
      produces a signed `.aab`.
- [ ] iOS signing and provisioning configured; an archive uploads
      cleanly to App Store Connect / TestFlight.
- [ ] `pubspec.yaml` version and build number bumped.
- [ ] Privacy policy and Terms copy reviewed by a human before
      public release. The `/legal` page is the source of truth in
      the app.
- [ ] Screenshots, short description, and full description prepared
      for each target store locale.
- [ ] Release build installed and smoke-tested on at least one real
      iOS device and one real Android device (not only simulators).

## H. Known MVP limitations

Ship with these clearly communicated, not hidden:

- No in-app payments, escrow, or transaction protection. Deals
  happen off-platform.
- No vehicle inspection, history report, or authenticity guarantee.
- No admin moderation dashboard yet. Reports arrive via the
  `CARZON_REPORT_EMAIL` inbox and are triaged manually.
- **Messaging (implemented MVP):** In-app **text** messaging with
  **inbox** and **conversation thread**. **Unread** state is backed by
  **`user_conversation_state`** and RPCs **`mark_conversation_read`**,
  **`get_unread_conversation_count`**, and **`list_inbox_conversations`**;
  the UI shows unread on **inbox rows**, **Profile → Activity →
  Messages**, and the **listings masthead avatar** (dot). **Mark-read**
  runs when appropriate on the thread; there is no separate
  delivery/read-receipt UI beyond unread indicators. The client **polls**
  for thread updates (timer-based), **not** Supabase **Realtime**.
- **Messaging (deferred):** **Push notifications**, **message
  attachments**, Realtime subscriptions, and richer delivery/read-receipt
  UX beyond the unread foundation above.
- Buyer-seller contact **also** includes **phone / Telegram / WhatsApp**
  from listing details, launched **externally** (alongside in-app chat
  when the listing has a seller and the viewer is not the seller).
- Active listings and their cover images are publicly readable by
  design (public feed + public `listing-images` bucket).
- Seller contact details are publicly readable on active listings
  by design; the app surfaces a notice and a phone-reveal step but
  does not attempt strong anti-scraping.
- Deep links use the `carzon://` custom scheme only; no domain
  verification via Universal Links / App Links yet.
- **Listing photos (MVP):** **Multi-photo** listings are implemented —
  **create** and **edit** support gallery upload/replacement; **listing
  details** displays multiple images. Files use the **`listing-images`**
  bucket (parity with `docs/RELEASE.md`). **Deferred:** advanced media
  (e.g. video, 360°) and non-essential gallery polish beyond this — not
  launch blockers.
- No reports table, admin tools, or dealer profiles. Each is a known
  future feature, not a blocker.
