import 'dart:async';

import 'push_messaging_permission_status.dart';

/// Testable abstraction over Firebase Cloud Messaging (no Supabase).
///
/// Implementations must never show UI or call `NotificationsRepository`.
abstract interface class PushMessagingClient {
  /// Initializes the native Firebase app if needed. Returns `false` when
  /// platform Firebase config is missing or initialization fails.
  Future<bool> initializeFirebase();

  /// Current authorization — does **not** prompt the user.
  Future<PushMessagingPermissionStatus> getPermissionStatus();

  /// Requests OS notification permission (may show a system dialog).
  /// Call only from explicit user-driven flows (not from app startup).
  Future<PushMessagingPermissionStatus> requestPermission();

  /// Resolves the FCM registration token, or `null` if unavailable.
  Future<String?> getFcmToken();

  /// FCM token rotation stream (only meaningful after Firebase init).
  Stream<String> watchTokenRefresh();

  /// Clears the FCM token on the device (best-effort after sign-out).
  Future<void> deleteFcmToken();
}
