import '../../../../core/utils/result.dart';
import '../entities/notification_preferences.dart';
import '../entities/push_token_platform.dart';

/// Reads/writes Phase 1 notification preferences + push token registry via RPCs only.
abstract interface class NotificationsRepository {
  Future<Result<NotificationPreferences>> getMyPreferences();

  Future<Result<NotificationPreferences>> updateMyPreferences({
    required bool globalEnabled,
    required bool messagesEnabled,
    required bool filterAlertsEnabled,
  });

  /// Registers or refreshes a device token for the signed-in user (no FCM plugin yet).
  Future<Result<void>> registerPushToken({
    required String token,
    required PushTokenPlatform platform,
    String? appVersion,
    String? deviceId,
    String? locale,
  });

  Future<Result<void>> deactivatePushToken(String token);

  Future<Result<void>> deactivateMyPushTokens();
}
