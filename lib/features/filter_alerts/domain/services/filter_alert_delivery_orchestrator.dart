import '../../../../core/config/env.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../notifications/domain/entities/notification_preferences.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../../notifications/services/push_messaging_permission_status.dart';
import '../../../notifications/services/push_notification_registration_service.dart';
import '../entities/saved_search.dart';
import '../usecases/set_saved_search_alerts_enabled.dart';

/// Server-side delivery path for saved-search alerts (OS prompt, prefs, per-row toggle, token).
class FilterAlertDeliveryOrchestrator {
  FilterAlertDeliveryOrchestrator({
    required NotificationsRepository notificationsRepository,
    required PushNotificationRegistrationService pushRegistration,
    required SetSavedSearchAlertsEnabled setAlertsEnabled,
  }) : _notificationsRepository = notificationsRepository,
       _pushRegistration = pushRegistration,
       _setAlertsEnabled = setAlertsEnabled;

  final NotificationsRepository _notificationsRepository;
  final PushNotificationRegistrationService _pushRegistration;
  final SetSavedSearchAlertsEnabled _setAlertsEnabled;

  Future<Result<SavedSearch>> enableDeliveries(SavedSearch savedSearch) async {
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

    final toggle = await _setAlertsEnabled(savedSearch.id, true);
    switch (toggle) {
      case FailureResult(:final failure):
        return FailureResult(failure);
      case Success(:final value):
        await _pushRegistration.syncTokenWithBackendIfEligible();
        return Success(value);
    }
  }

  Future<Result<SavedSearch>> disableDeliveries(SavedSearch savedSearch) {
    return _setAlertsEnabled(savedSearch.id, false);
  }
}
