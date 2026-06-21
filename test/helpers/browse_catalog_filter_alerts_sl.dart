import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/saved_searches_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/create_saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/delete_saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/list_saved_searches.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_saved_search_alerts_enabled.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

class MockSavedSearchesRepository extends Mock
    implements SavedSearchesRepository {}

class MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class MockPushNotificationRegistrationService extends Mock
    implements PushNotificationRegistrationService {}

NotificationPreferences _defaultPrefs() {
  return NotificationPreferences(
    userId: 'u-test',
    globalEnabled: false,
    messagesEnabled: true,
    filterAlertsEnabled: false,
    priceDropsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

SavedSearch testSavedSearch({
  String id = 'ss-1',
  String name = 'Test search',
  required ListingDiscoveryCriteria criteria,
  bool alertsEnabled = false,
}) {
  return SavedSearch(
    id: id,
    name: name,
    criteria: criteria,
    alertsEnabled: alertsEnabled,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );
}

/// Unit/widget-test cubit wired to mocked saved-search dependencies.
BrowseCatalogFilterAlertsCubit buildTestBrowseCatalogFilterAlertsCubit({
  required SavedSearchesRepository savedSearchesRepo,
  required NotificationsRepository notificationsRepo,
  required FilterAlertDeliveryOrchestrator deliveryOrchestrator,
}) {
  return BrowseCatalogFilterAlertsCubit(
    listSavedSearches: ListSavedSearches(savedSearchesRepo),
    createSavedSearch: CreateSavedSearch(savedSearchesRepo),
    deleteSavedSearch: DeleteSavedSearch(savedSearchesRepo),
    notificationsRepository: notificationsRepo,
    deliveryOrchestrator: deliveryOrchestrator,
  );
}

/// DI bundle for listing feed widget tests mounting [BrowseCatalogFilterAlertsCubit].
void primeListingBrowseFilterAlertsDeps(
  GetIt sl, {
  required MockSavedSearchesRepository savedSearchesRepo,
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
    () => savedSearchesRepo.list(),
  ).thenAnswer((_) async => const Success([]));
  when(
    () => savedSearchesRepo.create(
      name: any(named: 'name'),
      criteria: any(named: 'criteria'),
      alertsEnabled: any(named: 'alertsEnabled'),
    ),
  ).thenAnswer((inv) async {
    final criteria = inv.namedArguments[#criteria] as ListingDiscoveryCriteria;
    final alertsEnabled = inv.namedArguments[#alertsEnabled] as bool;
    final name = inv.namedArguments[#name] as String;
    return Success(
      testSavedSearch(
        criteria: criteria,
        name: name,
        alertsEnabled: alertsEnabled,
      ),
    );
  });
  when(() => savedSearchesRepo.setAlertsEnabled(any(), any())).thenAnswer((
    inv,
  ) async {
    final id = inv.positionalArguments.first as String;
    final enabled = inv.positionalArguments[1] as bool;
    return Success(
      testSavedSearch(
        id: id,
        criteria: const ListingDiscoveryCriteria(make: 'Toyota'),
        alertsEnabled: enabled,
      ),
    );
  });
  when(() => savedSearchesRepo.delete(any())).thenAnswer((_) async {
    return const Success(null);
  });

  when(
    () => notificationsRepo.getMyPreferences(),
  ).thenAnswer((_) async => Success(_defaultPrefs()));
  when(
    () => notificationsRepo.updateMyPreferences(
      globalEnabled: any(named: 'globalEnabled'),
      messagesEnabled: any(named: 'messagesEnabled'),
      filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
      priceDropsEnabled: any(named: 'priceDropsEnabled'),
    ),
  ).thenAnswer((inv) async {
    return Success(
      NotificationPreferences(
        userId: 'u-test',
        globalEnabled: inv.namedArguments[#globalEnabled] as bool,
        messagesEnabled: inv.namedArguments[#messagesEnabled] as bool,
        filterAlertsEnabled: inv.namedArguments[#filterAlertsEnabled] as bool,
    priceDropsEnabled: false,
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

  sl.registerLazySingleton<SavedSearchesRepository>(() => savedSearchesRepo);
  sl.registerLazySingleton<NotificationsRepository>(() => notificationsRepo);
  sl.registerLazySingleton<PushNotificationRegistrationService>(
    () => pushRegistration,
  );
  sl.registerFactory(() => ListSavedSearches(sl()));
  sl.registerFactory(() => CreateSavedSearch(sl()));
  sl.registerFactory(() => DeleteSavedSearch(sl()));
  sl.registerFactory(() => SetSavedSearchAlertsEnabled(sl()));
  sl.registerLazySingleton(
    () => FilterAlertDeliveryOrchestrator(
      notificationsRepository: sl(),
      pushRegistration: sl(),
      setAlertsEnabled: sl(),
    ),
  );

  sl.registerLazySingleton<BrowseCatalogFilterAlertsCubit>(
    () => BrowseCatalogFilterAlertsCubit(
      listSavedSearches: sl(),
      createSavedSearch: sl(),
      deleteSavedSearch: sl(),
      notificationsRepository: sl(),
      deliveryOrchestrator: sl(),
    ),
  );
}
