/// Client-reported platform for FCM/APNs registration (Phase 1 wire values only).
enum PushTokenPlatform { android, ios, web, unknown }

String pushTokenPlatformToWire(PushTokenPlatform p) {
  switch (p) {
    case PushTokenPlatform.android:
      return 'android';
    case PushTokenPlatform.ios:
      return 'ios';
    case PushTokenPlatform.web:
      return 'web';
    case PushTokenPlatform.unknown:
      return 'unknown';
  }
}

PushTokenPlatform pushTokenPlatformFromWire(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'android':
      return PushTokenPlatform.android;
    case 'ios':
      return PushTokenPlatform.ios;
    case 'web':
      return PushTokenPlatform.web;
    case 'unknown':
    case '':
    case null:
    default:
      return PushTokenPlatform.unknown;
  }
}
