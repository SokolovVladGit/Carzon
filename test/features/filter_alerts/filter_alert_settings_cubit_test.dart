import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/filter_alerts_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/set_filter_alert_notifications_enabled.dart';
import 'package:carzon/features/filter_alerts/presentation/cubit/filter_alert_settings_cubit.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/entities/push_token_platform.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFilterAlertsRepository extends Mock
    implements FilterAlertsRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockPushRegistration extends Mock
    implements PushNotificationRegistrationService {}

FilterAlertSettings _settings({
  ListingDiscoveryCriteria? criteria,
  bool notificationsEnabled = false,
}) {
  return FilterAlertSettings(
    userId: 'u1',
    criteria: criteria,
    notificationsEnabled: notificationsEnabled,
    createdAt: DateTime.utc(2026, 5, 1),
    updatedAt: DateTime.utc(2026, 5, 2),
  );
}

void main() {
  late _MockFilterAlertsRepository filterRepo;
  late _MockNotificationsRepository notifRepo;
  late _MockPushRegistration pushReg;

  FilterAlertSettingsCubit buildCubit() {
    return FilterAlertSettingsCubit(
      getSettings: GetFilterAlertSettings(filterRepo),
      saveCriteria: SaveFilterAlertCriteria(filterRepo),
      clearCriteria: ClearFilterAlertCriteria(filterRepo),
      deliveryOrchestrator: FilterAlertDeliveryOrchestrator(
        notificationsRepository: notifRepo,
        pushRegistration: pushReg,
        setNotificationsEnabled: SetFilterAlertNotificationsEnabled(filterRepo),
      ),
    );
  }

  setUp(() {
    filterRepo = _MockFilterAlertsRepository();
    notifRepo = _MockNotificationsRepository();
    pushReg = _MockPushRegistration();
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
      ),
    ).thenAnswer((inv) async {
      return Success(
        NotificationPreferences(
          userId: 'u1',
          globalEnabled: inv.namedArguments[#globalEnabled] as bool,
          messagesEnabled: inv.namedArguments[#messagesEnabled] as bool,
          filterAlertsEnabled: inv.namedArguments[#filterAlertsEnabled] as bool,
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
          createdAt: DateTime.utc(2026, 1, 1),
          updatedAt: DateTime.utc(2026, 1, 2),
        ),
      ),
    );
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
  });

  blocTest<FilterAlertSettingsCubit, FilterAlertSettingsState>(
    'enable without criteria surfaces notice and skips permission',
    setUp: () {
      when(
        () => filterRepo.loadMine(),
      ).thenAnswer((_) async => Success(_settings(criteria: null)));
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.enableFilterAlertNotifications();
    },
    expect: () => [
      isA<FilterAlertSettingsState>().having(
        (s) => s.status,
        'status',
        FilterAlertSettingsLoadStatus.loading,
      ),
      isA<FilterAlertSettingsState>().having(
        (s) => s.status,
        'status',
        FilterAlertSettingsLoadStatus.loaded,
      ),
      isA<FilterAlertSettingsState>().having(
        (s) => s.userNotice,
        'notice',
        FilterAlertSettingsUserNotice.saveFilterBeforeNotifications,
      ),
    ],
    verify: (_) {
      verifyNever(() => pushReg.requestOsNotificationPermission());
      verifyNever(() => filterRepo.setNotificationsEnabled(any()));
    },
  );

  blocTest<FilterAlertSettingsCubit, FilterAlertSettingsState>(
    'enable when OS permission denied keeps server flags unchanged',
    setUp: () {
      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(
          _settings(criteria: const ListingDiscoveryCriteria(make: 'Audi')),
        ),
      );
      when(
        () => pushReg.requestOsNotificationPermission(),
      ).thenAnswer((_) async => PushMessagingPermissionStatus.denied);
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.enableFilterAlertNotifications();
    },
    verify: (c) {
      expect(
        c.state.userNotice,
        FilterAlertSettingsUserNotice.osPermissionDenied,
      );
      verifyNever(
        () => notifRepo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      );
      verifyNever(() => filterRepo.setNotificationsEnabled(any()));
    },
  );

  blocTest<FilterAlertSettingsCubit, FilterAlertSettingsState>(
    'enable success updates prefs, server flag, and syncs token',
    setUp: () {
      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(
          _settings(criteria: const ListingDiscoveryCriteria(make: 'Audi')),
        ),
      );
      when(() => filterRepo.setNotificationsEnabled(true)).thenAnswer(
        (_) async => Success(
          _settings(
            criteria: const ListingDiscoveryCriteria(make: 'Audi'),
            notificationsEnabled: true,
          ),
        ),
      );
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.enableFilterAlertNotifications();
    },
    verify: (_) {
      verify(
        () => notifRepo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: true,
        ),
      ).called(1);
      verify(() => filterRepo.setNotificationsEnabled(true)).called(1);
      verify(() => pushReg.syncTokenWithBackendIfEligible()).called(1);
    },
  );

  blocTest<FilterAlertSettingsCubit, FilterAlertSettingsState>(
    'disable only flips filter_alert_settings.notifications_enabled',
    setUp: () {
      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(
          _settings(
            criteria: const ListingDiscoveryCriteria(make: 'Audi'),
            notificationsEnabled: true,
          ),
        ),
      );
      when(() => filterRepo.setNotificationsEnabled(false)).thenAnswer(
        (_) async => Success(
          _settings(
            criteria: const ListingDiscoveryCriteria(make: 'Audi'),
            notificationsEnabled: false,
          ),
        ),
      );
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.disableFilterAlertNotifications();
    },
    verify: (_) {
      verify(() => filterRepo.setNotificationsEnabled(false)).called(1);
      verifyNever(
        () => notifRepo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      );
    },
  );

  blocTest<FilterAlertSettingsCubit, FilterAlertSettingsState>(
    'push disabled build skips permission and repository updates',
    setUp: () {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
      );
      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(
          _settings(criteria: const ListingDiscoveryCriteria(make: 'Audi')),
        ),
      );
    },
    build: buildCubit,
    act: (c) async {
      await c.refresh();
      await c.enableFilterAlertNotifications();
    },
    expect: () => [
      isA<FilterAlertSettingsState>().having(
        (s) => s.status,
        'status',
        FilterAlertSettingsLoadStatus.loading,
      ),
      isA<FilterAlertSettingsState>()
          .having(
            (s) => s.status,
            'status',
            FilterAlertSettingsLoadStatus.loaded,
          )
          .having((s) => s.busyNotificationToggle, 'toggle', false)
          .having(
            (s) => s.settings?.notificationsEnabled,
            'notificationsEnabled',
            false,
          ),
      isA<FilterAlertSettingsState>()
          .having(
            (s) => s.status,
            'status',
            FilterAlertSettingsLoadStatus.loaded,
          )
          .having((s) => s.busyNotificationToggle, 'toggle', true)
          .having(
            (s) => s.userNotice,
            'notice',
            FilterAlertSettingsUserNotice.none,
          ),
      isA<FilterAlertSettingsState>()
          .having(
            (s) => s.status,
            'status',
            FilterAlertSettingsLoadStatus.loaded,
          )
          .having((s) => s.busyNotificationToggle, 'toggle', false)
          .having(
            (s) => s.userNotice,
            'notice',
            FilterAlertSettingsUserNotice.pushUnavailableInBuild,
          ),
    ],
    verify: (_) {
      verifyNever(() => pushReg.requestOsNotificationPermission());
      verifyNever(
        () => notifRepo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      );
    },
  );
}
