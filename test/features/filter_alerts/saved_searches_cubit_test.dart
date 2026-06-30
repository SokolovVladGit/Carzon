import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/saved_searches_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/delete_saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/list_saved_searches.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_saved_search_alerts_enabled.dart';
import 'package:carzon/features/filter_alerts/presentation/cubit/saved_searches_cubit.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/entities/push_token_platform.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/browse_catalog_filter_alerts_sl.dart';

class _MockSavedSearchesRepository extends Mock
    implements SavedSearchesRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockPushRegistration extends Mock
    implements PushNotificationRegistrationService {}

class _MockDeliveryOrchestrator extends Mock
    implements FilterAlertDeliveryOrchestrator {}

SavedSearch _audiRow({bool alertsEnabled = false}) {
  return testSavedSearch(
    id: 'ss-audi',
    name: 'Audi search',
    criteria: const ListingDiscoveryCriteria(make: 'Audi'),
    alertsEnabled: alertsEnabled,
  );
}

void main() {
  late _MockSavedSearchesRepository savedSearchesRepo;
  late _MockNotificationsRepository notifRepo;
  late _MockPushRegistration pushReg;
  late _MockDeliveryOrchestrator orchestrator;

  SavedSearchesCubit buildCubit() {
    return SavedSearchesCubit(
      listSavedSearches: ListSavedSearches(savedSearchesRepo),
      deleteSavedSearch: DeleteSavedSearch(savedSearchesRepo),
      deliveryOrchestrator: FilterAlertDeliveryOrchestrator(
        notificationsRepository: notifRepo,
        pushRegistration: pushReg,
        setAlertsEnabled: SetSavedSearchAlertsEnabled(savedSearchesRepo),
      ),
    );
  }

  SavedSearchesCubit buildCubitWithMockOrchestrator() {
    return SavedSearchesCubit(
      listSavedSearches: ListSavedSearches(savedSearchesRepo),
      deleteSavedSearch: DeleteSavedSearch(savedSearchesRepo),
      deliveryOrchestrator: orchestrator,
    );
  }

  setUp(() {
    savedSearchesRepo = _MockSavedSearchesRepository();
    notifRepo = _MockNotificationsRepository();
    pushReg = _MockPushRegistration();
    orchestrator = _MockDeliveryOrchestrator();
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    when(
      () => notifRepo.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        priceDropsEnabled: any(named: 'priceDropsEnabled'),
      ),
    ).thenAnswer((inv) async {
      return Success(
        NotificationPreferences(
          userId: 'u1',
          globalEnabled: inv.namedArguments[#globalEnabled] as bool,
          messagesEnabled: inv.namedArguments[#messagesEnabled] as bool,
          filterAlertsEnabled: inv.namedArguments[#filterAlertsEnabled] as bool,
          priceDropsEnabled: inv.namedArguments[#priceDropsEnabled] as bool,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      );
    });
    when(() => notifRepo.getMyPreferences()).thenAnswer(
      (_) async => Success(
        NotificationPreferences(
          userId: 'u1',
          globalEnabled: false,
          messagesEnabled: true,
          filterAlertsEnabled: false,
    priceDropsEnabled: false,
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ),
    );
    when(
      () => pushReg.resolvePermissionForPreferenceEnable(),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => pushReg.requestOsNotificationPermission(),
    ).thenAnswer((_) async => PushMessagingPermissionStatus.authorized);
    when(
      () => pushReg.syncTokenWithBackendIfEligible(),
    ).thenAnswer((_) async {});
  });

  setUpAll(() {
    registerFallbackValue(const ListingDiscoveryCriteria());
    registerFallbackValue(PushTokenPlatform.android);
    registerFallbackValue(
      testSavedSearch(criteria: const ListingDiscoveryCriteria()),
    );
  });

  blocTest<SavedSearchesCubit, SavedSearchesState>(
    'enable when OS permission denied keeps server flags unchanged',
    setUp: () {
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([_audiRow()]));
      when(
        () => pushReg.resolvePermissionForPreferenceEnable(),
      ).thenAnswer((_) async => PushMessagingPermissionStatus.denied);
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.setAlertsEnabled('ss-audi', true);
    },
    verify: (c) {
      expect(c.state.userNotice, SavedSearchesUserNotice.osPermissionDenied);
      verifyNever(
        () => notifRepo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
          priceDropsEnabled: any(named: 'priceDropsEnabled'),
        ),
      );
      verifyNever(() => savedSearchesRepo.setAlertsEnabled(any(), any()));
    },
  );

  blocTest<SavedSearchesCubit, SavedSearchesState>(
    'enable when permission stays notDetermined still saves prefs and row flag',
    setUp: () {
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([_audiRow()]));
      when(
        () => pushReg.resolvePermissionForPreferenceEnable(),
      ).thenAnswer((_) async => PushMessagingPermissionStatus.notDetermined);
      when(
        () => savedSearchesRepo.setAlertsEnabled('ss-audi', true),
      ).thenAnswer((_) async => Success(_audiRow(alertsEnabled: true)));
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.setAlertsEnabled('ss-audi', true);
    },
    verify: (_) {
      verify(
        () => notifRepo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: true,
          priceDropsEnabled: false,
        ),
      ).called(1);
      verify(
        () => savedSearchesRepo.setAlertsEnabled('ss-audi', true),
      ).called(1);
      verify(() => pushReg.syncTokenWithBackendIfEligible()).called(1);
    },
  );

  blocTest<SavedSearchesCubit, SavedSearchesState>(
    'enable success updates prefs, server flag, and syncs token',
    setUp: () {
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([_audiRow()]));
      when(
        () => savedSearchesRepo.setAlertsEnabled('ss-audi', true),
      ).thenAnswer((_) async => Success(_audiRow(alertsEnabled: true)));
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.setAlertsEnabled('ss-audi', true);
    },
    verify: (_) {
      verify(
        () => notifRepo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: true,
          priceDropsEnabled: false,
        ),
      ).called(1);
      verify(
        () => savedSearchesRepo.setAlertsEnabled('ss-audi', true),
      ).called(1);
      verify(() => pushReg.syncTokenWithBackendIfEligible()).called(1);
    },
  );

  blocTest<SavedSearchesCubit, SavedSearchesState>(
    'disable only flips saved search alerts_enabled',
    setUp: () {
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([_audiRow(alertsEnabled: true)]));
      when(
        () => savedSearchesRepo.setAlertsEnabled('ss-audi', false),
      ).thenAnswer((_) async => Success(_audiRow(alertsEnabled: false)));
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.setAlertsEnabled('ss-audi', false);
    },
    verify: (_) {
      verify(
        () => savedSearchesRepo.setAlertsEnabled('ss-audi', false),
      ).called(1);
      verifyNever(
        () => notifRepo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
          priceDropsEnabled: any(named: 'priceDropsEnabled'),
        ),
      );
    },
  );

  blocTest<SavedSearchesCubit, SavedSearchesState>(
    'push disabled build skips permission and repository updates',
    setUp: () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
      );
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([_audiRow()]));
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.setAlertsEnabled('ss-audi', true);
    },
    expect: () => [
      isA<SavedSearchesState>().having(
        (s) => s.status,
        'status',
        SavedSearchesLoadStatus.loading,
      ),
      isA<SavedSearchesState>().having(
        (s) => s.status,
        'status',
        SavedSearchesLoadStatus.loaded,
      ),
      isA<SavedSearchesState>()
          .having((s) => s.status, 'status', SavedSearchesLoadStatus.loaded)
          .having((s) => s.isToggling('ss-audi'), 'toggling', true),
      isA<SavedSearchesState>()
          .having((s) => s.status, 'status', SavedSearchesLoadStatus.loaded)
          .having(
            (s) => s.userNotice,
            'notice',
            SavedSearchesUserNotice.pushUnavailableInBuild,
          ),
    ],
    verify: (_) {
      verifyNever(() => pushReg.requestOsNotificationPermission());
      verifyNever(
        () => notifRepo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
          priceDropsEnabled: any(named: 'priceDropsEnabled'),
        ),
      );
    },
  );

  blocTest<SavedSearchesCubit, SavedSearchesState>(
    'deleteSavedSearch removes row from state on success',
    setUp: () {
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([_audiRow()]));
      when(
        () => savedSearchesRepo.delete('ss-audi'),
      ).thenAnswer((_) async => const Success(null));
    },
    build: buildCubitWithMockOrchestrator,
    act: (c) async {
      await c.refresh();
      await c.deleteSavedSearch('ss-audi');
    },
    verify: (c) {
      verify(() => savedSearchesRepo.delete('ss-audi')).called(1);
      expect(c.state.savedSearches, isEmpty);
    },
  );
}
