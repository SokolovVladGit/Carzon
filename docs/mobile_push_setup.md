# Mobile push setup (Flutter client)

Use this checklist before real-device FCM/APNs testing. Backend queue/Edge/cron
setup is documented separately in [`ops_message_notifications.md`](ops_message_notifications.md).

## Build flag

Set in `.env.client` (copy from `.env.client.example`):

```bash
PUSH_NOTIFICATIONS_ENABLED=true
```

Run/build with compile-time defines:

```bash
flutter run --dart-define-from-file=.env.client
flutter build apk --dart-define-from-file=.env.client
flutter build ios --dart-define-from-file=.env.client
```

Default when unset: **off** (no Firebase bootstrap, no token registration).

## Android

1. **Firebase Console** — register an Android app with package name **`com.example.carzon`**
   (must match `applicationId` in `android/app/build.gradle.kts`).
2. Download **`google-services.json`** and place at:
   **`android/app/google-services.json`**
3. Gradle applies **`com.google.gms.google-services`** only when that file exists
   (`android/app/build.gradle.kts`).
4. **Android 13+** — `POST_NOTIFICATIONS` is declared in `AndroidManifest.xml`;
   the app requests permission only when the user toggles push in notification settings.
5. FCM default channel id: **`carzon_messages`** (manifest meta-data; foreground
   channels also created in Dart).

## iOS

1. **Firebase Console** — register an iOS app with bundle id **`com.carzon.app`**
   (must match `PRODUCT_BUNDLE_IDENTIFIER` in Xcode).
2. Download **`GoogleService-Info.plist`** and place at:
   **`ios/Runner/GoogleService-Info.plist`**
   (already referenced in the Xcode project).
3. **Apple Developer / Xcode**
   - Enable **Push Notifications** capability for the Runner target (entitlements
     files: `Runner.entitlements` = development for Debug,
     `RunnerRelease.entitlements` = production for Release/Profile).
   - Upload an **APNs authentication key** (or certificates) in Firebase Console
     → Project settings → Cloud Messaging → Apple app configuration.
4. **Signing** — use a provisioning profile that includes push for the target
   build configuration (development for Debug, distribution for TestFlight/App Store).
5. `AppDelegate` extends `FlutterAppDelegate`; Firebase is initialized from Dart
   (`Firebase.initializeApp()` in `lib/app/bootstrap.dart`) using the plist.

## Backend (not in the mobile app)

- Supabase Edge workers + FCM **service account** secrets live in Supabase only.
- Never put `FCM_*` server keys, `SUPABASE_SERVICE_ROLE_KEY`, or
  `CARZON_PROCESS_*_SECRET` in `.env.client` or Flutter code.

## Real-device QA

See [`notifications_qa.md`](notifications_qa.md).
