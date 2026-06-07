# Auth Site URL and Redirect URL — configuration checklist

Use before public release to verify Supabase Dashboard Auth URL settings align with the mobile app deep-link implementation.

**Companion device QA:** [`auth_deeplink_qa.md`](auth_deeplink_qa.md)

**Status:** Backend hardening closed (2026-06). This checklist is the next release gate.

---

## Owner inputs required (confirm before dashboard edits)

The repo does **not** define a final production marketing/web domain. Owner must supply:

| Field | Owner value | Notes |
|-------|-------------|-------|
| **Production Site URL** | `<OWNER_HTTPS_SITE_URL>` | Real **HTTPS** fallback for email links (not `http://localhost:3000`) |
| **Supabase project** | Hosted Carzon project ref | Same project the release build targets |
| **Release build env** | `.env.client` used at compile time | Must match dashboard redirect allow-list |

Do not invent URLs in this doc — replace placeholders with owner-confirmed values.

---

## Known app values (from repo)

| Setting | Value | Source |
|---------|-------|--------|
| Custom scheme | `carzon` | `AuthDeepLinkService.kCustomScheme` |
| Auth callback host | `auth-callback` | Android manifest, iOS Info.plist |
| Full mobile redirect | `carzon://auth-callback` | Docs + platform config |
| Optional env override | `SUPABASE_PASSWORD_RESET_REDIRECT_URL` | `lib/core/config/env.dart`, `.env.client.example` |
| Password reset route | `/reset-password` | `AppRoutes.resetPassword` |
| Deep-link listener | `AuthDeepLinkService` → `getSessionFromUrl` | `lib/core/services/auth_deep_link_service.dart` |

**Not implemented:** Universal Links / App Links (no associated domains in iOS plist; Android `autoVerify="false"`). MVP uses **custom scheme only**.

---

## Supabase Dashboard — Auth → URL Configuration

Path: **Supabase Dashboard → Authentication → URL Configuration**

### 1. Site URL

- [ ] Set **Site URL** to `<OWNER_HTTPS_SITE_URL>` (owner-confirmed HTTPS domain).
- [ ] **Not** `http://localhost:3000` or other dev placeholder for production/public testers.
- [ ] Purpose: fallback when email links cannot open the app; also used when app env omits `SUPABASE_PASSWORD_RESET_REDIRECT_URL`.

**Risk if wrong:** reset/confirmation emails open localhost or broken web page on devices without the app.

### 2. Redirect URLs (allow-list)

Minimum for mobile MVP:

- [ ] `carzon://auth-callback` is listed exactly (scheme + host).

Optional (only if owner uses them):

- [ ] `http://localhost:3000/**` or local dev URLs — **dev only**; remove or avoid for production-only projects
- [ ] `<OWNER_HTTPS_SITE_URL>/auth/callback` or similar — **only if** a web callback page exists (repo has no Flutter web auth callback route today)

### 3. Email templates (sanity)

Path: **Authentication → Email Templates**

- [ ] Password recovery template uses Supabase action link placeholder (default is fine).
- [ ] Sign-up confirmation template reviewed if **email confirmation is enabled** on the project.
- [ ] Template wording is acceptable for release locale.

**Note:** Password reset requests pass `redirectTo: Env.passwordResetRedirectUrl` when set in the release build. Sign-up does **not** pass `emailRedirectTo` in code — confirmation links may follow **Site URL** unless Supabase project/template settings redirect to an allow-listed URL. Test sign-up confirmation if enabled.

---

## Release build — client env alignment

In `.env.client` for the release binary (via `--dart-define-from-file=.env.client`):

- [ ] `SUPABASE_URL` = hosted project API URL
- [ ] `SUPABASE_ANON_KEY` = matching anon key
- [ ] `SUPABASE_PASSWORD_RESET_REDIRECT_URL=carzon://auth-callback` **recommended** for mobile release builds

If `SUPABASE_PASSWORD_RESET_REDIRECT_URL` is **empty**, Supabase uses **Site URL** for password-reset emails instead of the app deep link.

---

## Platform registration (code — verify unchanged)

### Android

- [ ] `AndroidManifest.xml`: intent-filter `scheme=carzon`, `host=auth-callback`, `launchMode=singleTop`

### iOS

- [ ] `Info.plist`: `CFBundleURLSchemes` includes `carzon`

---

## Quick dashboard verification record

Owner fills after review:

```
Date: ___________
Reviewer: ___________
Site URL set to: ___________
Redirect URLs include carzon://auth-callback: [ ] Yes
localhost still in Redirect URLs: [ ] Yes (dev) / [ ] No (prod)
SUPABASE_PASSWORD_RESET_REDIRECT_URL in release .env.client: ___________
Email confirmation enabled on project: [ ] Yes / [ ] No
```

---

## Next step after dashboard PASS

Run device QA: [`auth_deeplink_qa.md`](auth_deeplink_qa.md) — especially password reset (warm/cold start) and sign-up confirmation if enabled.
