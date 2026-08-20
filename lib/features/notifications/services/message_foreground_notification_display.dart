/// Shows a privacy-safe local notification for an incoming message while the
/// app is foregrounded. No-op on unsupported platforms (e.g. tests).
abstract interface class MessageForegroundNotificationDisplay {
  /// Returns whether local foreground presentation is currently available.
  Future<bool> initialize();

  Future<void> showMessageForegroundNotification(String conversationId);

  /// Filter-alert foreground FCM (same privacy rules as Edge: generic copy only).
  Future<void> showFilterAlertForegroundNotification(String listingId);

  /// Price-drop foreground FCM (generic copy only; no price in notification).
  Future<void> showPriceDropForegroundNotification(String listingId);
}
