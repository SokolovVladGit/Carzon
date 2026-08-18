import 'dart:async';

import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/saved_searches_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_saved_search_alerts_enabled.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSavedSearchesRepository extends Mock
    implements SavedSearchesRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockPushRegistration extends Mock
    implements PushNotificationRegistrationService {}

void main() {
  late _MockSavedSearchesRepository savedSearches;
  late _MockNotificationsRepository notifications;
  late _MockPushRegistration pushRegistration;
  late FilterAlertDeliveryOrchestrator orchestrator;
  late bool sessionCurrent;

  final row = SavedSearch(
    id: 'search-a',
    name: 'Search A',
    criteria: const ListingDiscoveryCriteria(make: 'Toyota'),
    alertsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
  final enabledRow = SavedSearch(
    id: 'search-a',
    name: 'Search A',
    criteria: const ListingDiscoveryCriteria(make: 'Toyota'),
    alertsEnabled: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
  final prefs = NotificationPreferences(
    userId: 'user-a',
    globalEnabled: false,
    messagesEnabled: true,
    filterAlertsEnabled: false,
    priceDropsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );

  FilterAlertDeliverySessionGuard guard() {
    return FilterAlertDeliverySessionGuard(
      expectedUserId: 'user-a',
      isSessionCurrent: () => sessionCurrent,
    );
  }

  void expectStale(Result<SavedSearch> result) {
    switch (result) {
      case FailureResult(:final failure):
        expect(failure.message, filterAlertDeliverySessionStale);
      case Success():
        fail('Expected a stale-session result');
    }
  }

  void verifyNoUserBoundCalls() {
    verifyNever(() => notifications.getMyPreferences());
    verifyNever(
      () => notifications.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        priceDropsEnabled: any(named: 'priceDropsEnabled'),
      ),
    );
    verifyNever(() => savedSearches.setAlertsEnabled(any(), any()));
    verifyNever(
      () => pushRegistration.syncTokenWithBackendIfEligible(
        isSessionCurrent: any(named: 'isSessionCurrent'),
      ),
    );
  }

  setUp(() {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    savedSearches = _MockSavedSearchesRepository();
    notifications = _MockNotificationsRepository();
    pushRegistration = _MockPushRegistration();
    sessionCurrent = true;
    when(
      () => pushRegistration.captureSessionGuard(
        additionalCheck: any(named: 'additionalCheck'),
      ),
    ).thenAnswer((invocation) {
      final additional =
          invocation.namedArguments[#additionalCheck] as bool Function()?;
      return NotificationSessionGuard(
        expectedUserId: 'user-a',
        generation: 1,
        isCurrent: () => sessionCurrent && (additional?.call() ?? true),
      );
    });
    orchestrator = FilterAlertDeliveryOrchestrator(
      notificationsRepository: notifications,
      pushRegistration: pushRegistration,
      setAlertsEnabled: SetSavedSearchAlertsEnabled(savedSearches),
    );
  });

  test('stops after session changes during permission resolution', () async {
    final permission = Completer<PushMessagingPermissionStatus>();
    when(
      () => pushRegistration.resolvePermissionForPreferenceEnable(
        sessionGuard: any(named: 'sessionGuard'),
      ),
    ).thenAnswer((_) => permission.future);

    final operation = orchestrator.enableDeliveries(row, sessionGuard: guard());
    sessionCurrent = false;
    permission.complete(PushMessagingPermissionStatus.authorized);

    expectStale(await operation);
    verifyNoUserBoundCalls();
  });

  test('stops after preference load before preference mutation', () async {
    final preferenceLoad = Completer<Result<NotificationPreferences>>();
    when(
      () => pushRegistration.resolvePermissionForPreferenceEnable(
        sessionGuard: any(named: 'sessionGuard'),
      ),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => notifications.getMyPreferences(),
    ).thenAnswer((_) => preferenceLoad.future);

    final operation = orchestrator.enableDeliveries(row, sessionGuard: guard());
    await untilCalled(() => notifications.getMyPreferences());
    preferenceLoad.complete(Success(prefs));
    sessionCurrent = false;

    expectStale(await operation);
    verify(() => notifications.getMyPreferences()).called(1);
    verifyNever(
      () => notifications.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        priceDropsEnabled: any(named: 'priceDropsEnabled'),
      ),
    );
    verifyNever(() => savedSearches.setAlertsEnabled(any(), any()));
    verifyNever(
      () => pushRegistration.syncTokenWithBackendIfEligible(
        isSessionCurrent: any(named: 'isSessionCurrent'),
      ),
    );
  });

  test('saved-search management uses central account authority', () async {
    final preferenceLoad = Completer<Result<NotificationPreferences>>();
    when(
      () => pushRegistration.resolvePermissionForPreferenceEnable(
        sessionGuard: any(named: 'sessionGuard'),
      ),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => notifications.getMyPreferences(),
    ).thenAnswer((_) => preferenceLoad.future);

    final operation = orchestrator.enableDeliveries(row);
    await untilCalled(() => notifications.getMyPreferences());
    sessionCurrent = false;
    preferenceLoad.complete(Success(prefs));

    expectStale(await operation);
    verifyNever(
      () => notifications.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        priceDropsEnabled: any(named: 'priceDropsEnabled'),
      ),
    );
    verifyNever(() => savedSearches.setAlertsEnabled(any(), any()));
  });

  test('stops after an already-transmitted preference update', () async {
    final preferenceUpdate = Completer<Result<NotificationPreferences>>();
    when(
      () => pushRegistration.resolvePermissionForPreferenceEnable(
        sessionGuard: any(named: 'sessionGuard'),
      ),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => notifications.getMyPreferences(),
    ).thenAnswer((_) async => Success(prefs));
    when(
      () => notifications.updateMyPreferences(
        globalEnabled: true,
        messagesEnabled: true,
        filterAlertsEnabled: true,
        priceDropsEnabled: false,
      ),
    ).thenAnswer((_) => preferenceUpdate.future);

    final operation = orchestrator.enableDeliveries(row, sessionGuard: guard());
    await untilCalled(
      () => notifications.updateMyPreferences(
        globalEnabled: true,
        messagesEnabled: true,
        filterAlertsEnabled: true,
        priceDropsEnabled: false,
      ),
    );
    sessionCurrent = false;
    preferenceUpdate.complete(Success(prefs));

    expectStale(await operation);
    verifyNever(() => savedSearches.setAlertsEnabled(any(), any()));
    verifyNever(
      () => pushRegistration.syncTokenWithBackendIfEligible(
        isSessionCurrent: any(named: 'isSessionCurrent'),
      ),
    );
  });

  test('current session executes every delivery step once', () async {
    when(
      () => pushRegistration.resolvePermissionForPreferenceEnable(
        sessionGuard: any(named: 'sessionGuard'),
      ),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => notifications.getMyPreferences(),
    ).thenAnswer((_) async => Success(prefs));
    when(
      () => notifications.updateMyPreferences(
        globalEnabled: true,
        messagesEnabled: true,
        filterAlertsEnabled: true,
        priceDropsEnabled: false,
      ),
    ).thenAnswer((_) async => Success(prefs));
    when(
      () => savedSearches.setAlertsEnabled('search-a', true),
    ).thenAnswer((_) async => Success(enabledRow));
    when(
      () => pushRegistration.syncTokenWithBackendIfEligible(
        isSessionCurrent: any(named: 'isSessionCurrent'),
      ),
    ).thenAnswer((_) async {});

    final result = await orchestrator.enableDeliveries(
      row,
      sessionGuard: guard(),
    );

    switch (result) {
      case FailureResult(:final failure):
        fail('Expected success, got ${failure.message}');
      case Success(:final value):
        expect(value, enabledRow);
    }
    verify(
      () => pushRegistration.resolvePermissionForPreferenceEnable(
        sessionGuard: any(named: 'sessionGuard'),
      ),
    ).called(1);
    verify(() => notifications.getMyPreferences()).called(1);
    verify(
      () => notifications.updateMyPreferences(
        globalEnabled: true,
        messagesEnabled: true,
        filterAlertsEnabled: true,
        priceDropsEnabled: false,
      ),
    ).called(1);
    verify(() => savedSearches.setAlertsEnabled('search-a', true)).called(1);
    verify(
      () => pushRegistration.syncTokenWithBackendIfEligible(
        isSessionCurrent: any(named: 'isSessionCurrent'),
      ),
    ).called(1);
  });

  test('current-session preference failure remains meaningful', () async {
    when(
      () => pushRegistration.resolvePermissionForPreferenceEnable(
        sessionGuard: any(named: 'sessionGuard'),
      ),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => notifications.getMyPreferences(),
    ).thenAnswer((_) async => const FailureResult(NetworkFailure('offline')));

    final result = await orchestrator.enableDeliveries(
      row,
      sessionGuard: guard(),
    );

    switch (result) {
      case FailureResult(:final failure):
        expect(failure.message, 'filter_alert_delivery_prefs_load_failed');
      case Success():
        fail('Expected preference-load failure');
    }
    verifyNever(
      () => notifications.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        priceDropsEnabled: any(named: 'priceDropsEnabled'),
      ),
    );
    verifyNever(() => savedSearches.setAlertsEnabled(any(), any()));
    verifyNever(
      () => pushRegistration.syncTokenWithBackendIfEligible(
        isSessionCurrent: any(named: 'isSessionCurrent'),
      ),
    );
  });
}
