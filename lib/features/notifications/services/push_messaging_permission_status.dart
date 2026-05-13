/// OS notification permission as exposed by the push client abstraction
/// (maps from `firebase_messaging` settings without leaking that type).
enum PushMessagingPermissionStatus {
  denied,
  notDetermined,
  authorized,
  provisional,
}

/// Whether an FCM token may be registered with the backend (Phase 2 rules).
extension PushMessagingPermissionStatusX on PushMessagingPermissionStatus {
  bool get allowsTokenRegistration =>
      this == PushMessagingPermissionStatus.authorized ||
      this == PushMessagingPermissionStatus.provisional;
}
