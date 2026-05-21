import '../../../../core/config/env.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../notifications/domain/entities/notification_preferences.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../../notifications/services/push_messaging_permission_status.dart';
import '../../../notifications/services/push_notification_registration_service.dart';
import '../entities/filter_alert_settings.dart';
import '../usecases/set_filter_alert_notifications_enabled.dart';

/// Server-side delivery path for saved filter alerts (OS prompt, prefs row, FAS toggle, token).
///
/// Shared by account settings UI and browse catalog UX so enable/disable stay aligned.
class FilterAlertDeliveryOrchestrator {
  FilterAlertDeliveryOrchestrator({
    required NotificationsRepository notificationsRepository,
    required PushNotificationRegistrationService pushRegistration,
    required SetFilterAlertNotificationsEnabled setNotificationsEnabled,
  }) : _notificationsRepository = notificationsRepository,
       _pushRegistration = pushRegistration,
       _setNotificationsEnabled = setNotificationsEnabled;

  final NotificationsRepository _notificationsRepository;
  final PushNotificationRegistrationService _pushRegistration;
  final SetFilterAlertNotificationsEnabled _setNotificationsEnabled;

  Future<Result<FilterAlertSettings>> enableDeliveries(
    FilterAlertSettings rowMustHaveCriteria,
  ) async {
    if (rowMustHaveCriteria.criteria == null) {
      return const FailureResult(
        UnknownFailure('filter_alert_delivery_no_criteria'),
      );
    }
    if (!Env.pushNotificationsEnabled) {
      return const FailureResult(
        UnknownFailure('filter_alert_delivery_push_disabled'),
      );
    }
    final requested = await _pushRegistration.requestOsNotificationPermission();
    if (!requested.allowsTokenRegistration) {
      return const FailureResult(
        UnknownFailure('filter_alert_delivery_permission_denied'),
      );
    }

    NotificationPreferences prefs;
    final prefsLoad = await _notificationsRepository.getMyPreferences();
    switch (prefsLoad) {
      case FailureResult():
        return const FailureResult(
          UnknownFailure('filter_alert_delivery_prefs_load_failed'),
        );
      case Success(:final value):
        prefs = value;
    }

    final prefUp = await _notificationsRepository.updateMyPreferences(
      globalEnabled: true,
      messagesEnabled: prefs.messagesEnabled,
      filterAlertsEnabled: true,
    );
    switch (prefUp) {
      case FailureResult():
        return const FailureResult(
          UnknownFailure('filter_alert_delivery_prefs_save_failed'),
        );
      case Success():
        break;
    }

    final toggle = await _setNotificationsEnabled(true);
    switch (toggle) {
      case FailureResult(:final failure):
        return FailureResult(failure);
      case Success(:final value):
        await _pushRegistration.syncTokenWithBackendIfEligible();
        return Success(value);
    }
  }

  Future<Result<FilterAlertSettings>> disableDeliveriesFlagOnly() {
    return _setNotificationsEnabled(false);
  }
}
