import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/filter_alerts_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_filter_alert_notifications_enabled.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockFilterAlertsRepository extends Mock
    implements FilterAlertsRepository {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockPushNotificationRegistrationService extends Mock
    implements PushNotificationRegistrationService {}

FilterAlertSettings _emptyFilterAlertRow() {
  return FilterAlertSettings(
    userId: 'u-test',
    criteria: null,
    notificationsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

NotificationPreferences _defaultPrefs() {
  return NotificationPreferences(
    userId: 'u-test',
    globalEnabled: false,
    messagesEnabled: true,
    filterAlertsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

/// DI bundle for listing feed widget tests mounting [BrowseCatalogFilterAlertsCubit].
void primeListingBrowseFilterAlertsDeps(
  GetIt sl, {
  required MockFilterAlertsRepository filterRepo,
  required MockNotificationsRepository notificationsRepo,
  required MockPushNotificationRegistrationService pushRegistration,
}) {
  dotenv.testLoad(
    fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
  );

  when(
    () => filterRepo.loadMine(),
  ).thenAnswer((_) async => Success(_emptyFilterAlertRow()));
  when(
    () => filterRepo.saveCriteria(
      any(),
      notificationsEnabled: any(named: 'notificationsEnabled'),
    ),
  ).thenAnswer((inv) async {
    final criteria = inv.positionalArguments.first as ListingDiscoveryCriteria;
    final notificationsEnabled =
        inv.namedArguments[#notificationsEnabled] as bool;
    return Success(
      FilterAlertSettings(
        userId: 'u-test',
        criteria: criteria,
        notificationsEnabled: notificationsEnabled,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
  });
  when(() => filterRepo.setNotificationsEnabled(any())).thenAnswer((inv) async {
    final enabled = inv.positionalArguments.first as bool;
    final row = FilterAlertSettings(
      userId: 'u-test',
      criteria: null,
      notificationsEnabled: enabled,
      createdAt: DateTime.utc(2026, 1, 1),
      updatedAt: DateTime.utc(2026, 1, 2),
    );
    return Success(row);
  });
  // Default clear behavior mirrors the production
  // `upsertClearsCriteria` semantics: drops criteria AND flips the
  // delivery flag off in one round-trip. Individual tests can override.
  when(() => filterRepo.clearPersistedCriteria()).thenAnswer((_) async {
    return Success(
      FilterAlertSettings(
        userId: 'u-test',
        criteria: null,
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
  });

  when(
    () => notificationsRepo.getMyPreferences(),
  ).thenAnswer((_) async => Success(_defaultPrefs()));
  when(
    () => notificationsRepo.updateMyPreferences(
      globalEnabled: any(named: 'globalEnabled'),
      messagesEnabled: any(named: 'messagesEnabled'),
      filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
    ),
  ).thenAnswer((inv) async {
    return Success(
      NotificationPreferences(
        userId: 'u-test',
        globalEnabled: inv.namedArguments[#globalEnabled] as bool,
        messagesEnabled: inv.namedArguments[#messagesEnabled] as bool,
        filterAlertsEnabled: inv.namedArguments[#filterAlertsEnabled] as bool,
        createdAt: DateTime.utc(2026, 1, 1),
        updatedAt: DateTime.utc(2026, 1, 2),
      ),
    );
  });

  when(
    () => pushRegistration.requestOsNotificationPermission(),
  ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
  when(
    () => pushRegistration.syncTokenWithBackendIfEligible(),
  ).thenAnswer((_) async {});

  sl.registerLazySingleton<FilterAlertsRepository>(() => filterRepo);
  sl.registerLazySingleton<NotificationsRepository>(() => notificationsRepo);
  sl.registerLazySingleton<PushNotificationRegistrationService>(
    () => pushRegistration,
  );
  sl.registerFactory(() => GetFilterAlertSettings(sl()));
  sl.registerFactory(() => SaveFilterAlertCriteria(sl()));
  sl.registerFactory(() => ClearFilterAlertCriteria(sl()));
  sl.registerFactory(() => SetFilterAlertNotificationsEnabled(sl()));
  sl.registerLazySingleton(
    () => FilterAlertDeliveryOrchestrator(
      notificationsRepository: sl(),
      pushRegistration: sl(),
      setNotificationsEnabled: sl(),
    ),
  );

  sl.registerLazySingleton<BrowseCatalogFilterAlertsCubit>(
    () => BrowseCatalogFilterAlertsCubit(
      getSettings: sl(),
      saveCriteria: sl(),
      clearCriteria: sl(),
      notificationsRepository: sl(),
      deliveryOrchestrator: sl(),
    ),
  );
}
