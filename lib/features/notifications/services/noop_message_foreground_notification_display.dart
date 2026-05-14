import 'message_foreground_notification_display.dart';

/// Used when push is disabled: [initialize] / [showMessageForegroundNotification] are no-ops.
class NoopMessageForegroundNotificationDisplay
    implements MessageForegroundNotificationDisplay {
  const NoopMessageForegroundNotificationDisplay();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> showMessageForegroundNotification(String _) async {}

  @override
  Future<void> showFilterAlertForegroundNotification(String _) async {}
}
