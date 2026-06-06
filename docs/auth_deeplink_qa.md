# Auth Deep-Link And Password Reset QA Checklist

Use this checklist before release for Supabase Auth, password recovery, and
custom-scheme deep links.

Use test accounts only. Do not paste access tokens, refresh tokens, reset links,
JWTs, or full callback URLs into issue reports or screenshots.

## Setup

- Use a build pointed at the intended Supabase project.
- Confirm the app has the custom scheme registered:
  - Android: `carzon://auth-callback`
  - iOS: `carzon://auth-callback`
- Confirm `SUPABASE_PASSWORD_RESET_REDIRECT_URL` matches the app callback URL
  expected for the environment.
- Confirm Supabase Dashboard Auth URL settings include the same redirect URL.

## Fresh Install / Startup

1. Install the app fresh.
2. Launch without signing in.

Expected:

- App starts without crashing.
- Listings feed opens.
- Protected pages show local signed-out states with `AuthRequiredPrompt`.
- No router-level auth redirect occurs.

## Sign Up

1. Open sign-up.
2. Submit valid email and password.

Expected:

- If email confirmation is enabled, app shows check-email copy.
- If session is issued immediately, app signs in and opens the feed.
- Duplicate fast taps do not create overlapping submissions.

## Sign In

1. Open sign-in.
2. Submit valid credentials.

Expected:

- App signs in and opens the feed.
- Profile/menu reflects authenticated state.
- Duplicate fast taps do not create overlapping submissions.

## Wrong Password

1. Open sign-in.
2. Submit valid email with wrong password.

Expected:

- Localized invalid-credentials or generic sign-in error is shown.
- App remains recoverable.
- No raw Supabase error, token, or URL is visible.

## Password Reset Email Request

1. Open forgot-password screen.
2. Submit the test account email.

Expected:

- App shows neutral success copy after request succeeds.
- Copy does not reveal whether the account exists.
- Duplicate fast taps do not send overlapping requests.

Repeat with invalid network/offline mode.

Expected:

- Localized recoverable failure is shown.
- User can retry.

## Open Password Reset Link

### App Installed, Warm App

1. Request a password reset email.
2. Keep the app running.
3. Open the email reset link.

Expected:

- App handles the `carzon://auth-callback` link.
- Reset password screen becomes available only after Supabase emits recovery state.
- Submitting matching valid passwords updates password.

### Cold Start

1. Kill the app.
2. Open the reset link from email.

Expected:

- App starts without crashing.
- Recovery session is handled.
- Reset password form is available only when recovery state exists.

### Already Running On Another Screen

1. Open app on feed/profile/menu.
2. Open reset link.

Expected:

- Auth recovery state is processed.
- App remains stable.
- If reset route is opened manually without recovery state, it shows the no-session instruction.

## Expired Reset Link

1. Open an already used or expired reset link.

Expected:

- App does not crash.
- Reset form is not exposed unless Supabase emits recovery state.
- User sees recoverable no-session/sign-in path.
- No token or raw callback URL is shown.

## Malformed / Unknown Deep Link

1. Open `carzon://unknown`.
2. Open `carzon://auth-callback` with missing/invalid auth parameters.
3. Open an unrelated HTTPS link.

Expected:

- Unknown custom-scheme links are ignored.
- Malformed auth callback does not crash.
- No raw URL or token appears in UI.

## Sign Out

1. Sign in.
2. Open profile or menu.
3. Sign out.

Expected:

- Auth state becomes signed out.
- Profile/menu reflect signed-out state.
- Protected pages show local `AuthRequiredPrompt`.
- Password recovery latch is cleared if it was active.

## Protected Route While Signed Out

Open each protected route while signed out:

- Create listing
- Edit listing
- My listings
- Favorites
- Messages
- Notification settings
- Profile account sections

Expected:

- Route renders its local signed-out/empty auth state.
- No global redirect is introduced.
- Back/fallback navigation still works.

## Platform Link Configuration

### Android

Verify manually:

- Manifest contains scheme `carzon` and host `auth-callback`.
- Reset email link opens the app.
- Unknown `carzon://unknown` does not crash the app.

### iOS

Verify manually:

- `CFBundleURLSchemes` contains `carzon`.
- Reset email link opens the app.
- Unknown `carzon://unknown` does not crash the app.

## Supabase Dashboard Redirect URLs

Verify manually in Supabase Dashboard:

- Site URL is correct for the environment.
- Redirect allow-list includes `carzon://auth-callback`.
- Any web fallback URL, if used, is environment-specific.
- Production and staging URLs are not mixed.

## Pass Criteria

- Startup with no session is stable.
- Password reset request succeeds with neutral copy.
- Duplicate auth submissions are guarded.
- Valid reset links establish recovery state.
- Expired/malformed links do not crash.
- Protected routes keep local signed-out UI.
- No tokens, reset links, JWTs, or raw callback URLs are exposed to users/log reports.

## Fail Criteria

- App crashes on reset link or malformed link.
- Reset form is usable without recovery state.
- Password reset request reveals whether an account exists.
- Duplicate taps send overlapping auth/reset requests.
- Protected pages redirect globally instead of showing local signed-out states.
- Tokens or full callback URLs are logged in user-visible reports.
