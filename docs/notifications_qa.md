# Notifications QA Checklist

Use this checklist before release for Firebase Messaging, local notifications,
push registration, and notification tap routing.

Use test accounts and test listings/conversations only. Do not include seller
contact data, tokens, JWTs, or private message text in screenshots or reports.

## Setup

- Build with push enabled for the target environment.
- Confirm Firebase config is present for the platform under test.
- Use one signed-in test account with:
  - at least one listing detail notification payload available for testing,
  - one message thread notification payload if message pushes are enabled,
  - notification settings accessible from profile.
- Have network controls available for offline/slow-network testing.

## Android

### Fresh Install Permission Flow

1. Install the app fresh on Android 13+.
2. Sign in.
3. Open notification settings.
4. Toggle `Push on this device`.

Expected:

- Permission is requested only after the user toggles push.
- Denying permission does not crash.
- Allowing permission enables push preferences and attempts token registration.

### Permission Denied

1. Deny notification permission.
2. Return to notification settings.
3. Toggle push again.

Expected:

- Recoverable localized error is shown.
- Backend token registration is not expected.
- User can retry after enabling permission in system settings.

### Permission Allowed

1. Allow notification permission.
2. Toggle push on.

Expected:

- Settings remain enabled after reload.
- No duplicate registration is visible from repeated fast taps.

## iOS

### Fresh Install Permission Flow

1. Install the app fresh.
2. Sign in.
3. Open notification settings.
4. Toggle `Push on this device`.

Expected:

- Permission is requested only after the user toggles push.
- Denying permission does not crash.
- Allowing permission enables push preferences.
- If APNs/FCM token is not ready immediately, app remains usable and can retry later.

### Permission Denied

1. Deny notification permission.
2. Return to notification settings.
3. Toggle push again.

Expected:

- Recoverable localized error is shown.
- No raw Firebase/APNs error is shown to the user.

## Token Registration

### Success

1. Sign in.
2. Allow permission.
3. Toggle push on.

Expected:

- App registers the FCM token once for the signed-in user.
- Repeated fast toggles do not create duplicate concurrent registration attempts.
- User-facing UI remains localized.

### Failure / Offline Mode

1. Turn on airplane mode or block network.
2. Toggle push on.

Expected:

- App does not crash.
- A recoverable localized save/error state is shown.
- No FCM token, Supabase JWT, user id, or raw backend payload is shown.
- Retrying after network recovery works.

### Null / Delayed Token

1. On iOS, test shortly after fresh install when APNs token may not be ready.
2. Toggle push on.

Expected:

- App does not crash.
- Registration is skipped until a token is available.
- Later token refresh should register when signed in and permission is allowed.

## Foreground Notifications

1. Keep app open in foreground.
2. Send a message notification.
3. Send a filter-alert notification.

Expected:

- App shows local notification with generic public copy.
- No private message body, seller contact data, storage paths, or raw ids are visible in notification title/body.
- Unknown or malformed payloads are ignored.

## Notification Taps

### Background Tap

1. Put app in background.
2. Send a valid message notification.
3. Tap notification.

Expected:

- App opens the message thread when authenticated.
- If signed out, navigation waits until sign-in/auth is restored.

Repeat with a valid filter-alert/listing notification.

### Terminated App Tap

1. Kill the app.
2. Send a valid message notification.
3. Tap notification.

Expected:

- App starts and routes to the target message thread when authenticated.
- No crash if payload is missing or malformed.

Repeat with a valid filter-alert/listing notification.

### Invalid / Missing Payload

1. Send notification with missing `type`.
2. Send notification with unknown `type`.
3. Send notification with malformed `conversation_id` or `listing_id`.

Expected:

- App ignores unknown/malformed payloads.
- No navigation crash.
- No raw payload content is shown to the user.

## Sign-Out Behavior

1. Enable push while signed in.
2. Sign out.

Expected:

- Server token deactivation is attempted before local auth is cleared.
- Local FCM token delete is attempted.
- Signed-out notification settings screen shows the sign-in prompt.
- Signed-out users do not register a token.

## Reinstall / Token Refresh

1. Enable push.
2. Reinstall app or trigger token refresh if test tooling allows.
3. Sign in and allow notifications.

Expected:

- New token registers when eligible.
- Duplicate simultaneous refresh/sync events do not cause duplicate registration attempts.

## Pass Criteria

- Push permission remains user-triggered.
- Denied permission and null token paths are recoverable.
- Signed-out users do not register tokens.
- Duplicate registration attempts are guarded.
- Foreground notifications use public copy only.
- Malformed or unknown payloads are ignored safely.
- Valid message/listing notification taps route correctly.

## Fail Criteria

- Permission prompt appears before user opt-in.
- App crashes on permission denial, null token, or malformed payload.
- Signed-out user registers a token.
- Fast repeated toggles trigger duplicate concurrent backend writes.
- Notification title/body exposes private message text, seller contact data, token, JWT, storage path, or raw backend error.
- Tap routing crashes or opens an invalid route.
