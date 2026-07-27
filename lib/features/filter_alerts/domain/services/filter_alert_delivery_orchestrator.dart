import '../../../../core/config/env.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/errors/failures.dart';
import '../../../notifications/domain/entities/notification_preferences.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../../notifications/services/push_messaging_permission_status.dart';
import '../../../notifications/services/push_notification_registration_service.dart';
import '../entities/saved_search.dart';
import '../usecases/set_saved_search_alerts_enabled.dart';

const filterAlertDeliverySessionStale = 'filter_alert_delivery_session_stale';

/// Captures the authenticated session that initiated a delivery operation.
final class FilterAlertDeliverySessionGuard {
  const FilterAlertDeliverySessionGuard({
    required this.expectedUserId,
    required this.isSessionCurrent,
  });

  final String expectedUserId;
  final bool Function() isSessionCurrent;
}

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

  Future<Result<SavedSearch>> enableDeliveries(
    SavedSearch savedSearch, {
    FilterAlertDeliverySessionGuard? sessionGuard,
  }) async {
    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    if (!Env.pushNotificationsEnabled) {
      return const FailureResult(
        UnknownFailure('filter_alert_delivery_push_disabled'),
      );
    }
    final perm = await _pushRegistration.resolvePermissionForPreferenceEnable();
    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    if (perm.blocksPreferenceEnable) {
      return const FailureResult(
        UnknownFailure('filter_alert_delivery_permission_denied'),
      );
    }

    NotificationPreferences prefs;
    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    final prefsLoad = await _notificationsRepository.getMyPreferences();
    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    switch (prefsLoad) {
      case FailureResult():
        return const FailureResult(
          UnknownFailure('filter_alert_delivery_prefs_load_failed'),
        );
      case Success(:final value):
        prefs = value;
    }

    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    final prefUp = await _notificationsRepository.updateMyPreferences(
      globalEnabled: true,
      messagesEnabled: prefs.messagesEnabled,
      filterAlertsEnabled: true,
      priceDropsEnabled: prefs.priceDropsEnabled,
    );
    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    switch (prefUp) {
      case FailureResult():
        return const FailureResult(
          UnknownFailure('filter_alert_delivery_prefs_save_failed'),
        );
      case Success():
        break;
    }

    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    final toggle = await _setAlertsEnabled(savedSearch.id, true);
    if (!_isCurrent(sessionGuard)) return _staleSessionResult();
    switch (toggle) {
      case FailureResult(:final failure):
        return FailureResult(failure);
      case Success(:final value):
        if (!_isCurrent(sessionGuard)) return _staleSessionResult();
        if (sessionGuard == null) {
          await _pushRegistration.syncTokenWithBackendIfEligible();
        } else {
          await _pushRegistration.syncTokenWithBackendIfEligible(
            isSessionCurrent: sessionGuard.isSessionCurrent,
          );
        }
        if (!_isCurrent(sessionGuard)) return _staleSessionResult();
        return Success(value);
    }
  }

  Future<Result<SavedSearch>> disableDeliveries(SavedSearch savedSearch) {
    return _setAlertsEnabled(savedSearch.id, false);
  }

  bool _isCurrent(FilterAlertDeliverySessionGuard? guard) {
    return guard?.isSessionCurrent() ?? true;
  }

  FailureResult<SavedSearch> _staleSessionResult() {
    return const FailureResult(UnknownFailure(filterAlertDeliverySessionStale));
  }
}
