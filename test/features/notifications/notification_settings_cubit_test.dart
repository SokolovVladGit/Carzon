import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/entities/push_token_platform.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/notifications/presentation/cubit/notification_settings_cubit.dart';
import 'package:carzon/features/notifications/services/push_auth_gate.dart';
import 'package:carzon/features/notifications/services/push_messaging_client.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:carzon/features/notifications/services/push_notification_registration_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _FakePushMessagingClient implements PushMessagingClient {
  int permissionRequestCalls = 0;
  int getPermissionStatusCalls = 0;
  PushMessagingPermissionStatus permissionStatus =
      PushMessagingPermissionStatus.authorized;
  PushMessagingPermissionStatus permissionAfterRequest =
      PushMessagingPermissionStatus.authorized;
  final StreamController<String> _refresh = StreamController.broadcast();

  @override
  Future<bool> initializeFirebase() async => true;

  @override
  Future<PushMessagingPermissionStatus> getPermissionStatus() async {
    getPermissionStatusCalls++;
    return permissionStatus;
  }

  @override
  Future<PushMessagingPermissionStatus> requestPermission() async {
    permissionRequestCalls++;
    permissionStatus = permissionAfterRequest;
    return permissionAfterRequest;
  }

  @override
  Future<String?> getFcmToken() async => 'test-fcm-token';

  @override
  Stream<String> watchTokenRefresh() => _refresh.stream;

  @override
  Future<void> deleteFcmToken() async {}

  Future<void> close() async => _refresh.close();
}

class _FakeAuthGate implements PushAuthGate {
  const _FakeAuthGate();

  @override
  bool get hasAuthenticatedUser => true;
}

NotificationPreferences _prefs({
  bool global = false,
  bool messages = false,
  bool filterAlerts = false,
}) {
  return NotificationPreferences(
    userId: 'u1',
    globalEnabled: global,
    messagesEnabled: messages,
    filterAlertsEnabled: filterAlerts,
    createdAt: DateTime.utc(2024, 1, 1),
    updatedAt: DateTime.utc(2024, 1, 2),
  );
}

void main() {
  late _MockNotificationsRepository repo;
  late _FakePushMessagingClient client;
  late _FakeAuthGate authGate;
  late PushNotificationRegistrationService pushRegistration;

  void stubRepoSuccess() {
    when(
      () => repo.updateMyPreferences(
        globalEnabled: any(named: 'globalEnabled'),
        messagesEnabled: any(named: 'messagesEnabled'),
        filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
      ),
    ).thenAnswer((inv) async {
      final global = inv.namedArguments[#globalEnabled] as bool;
      final messages = inv.namedArguments[#messagesEnabled] as bool;
      final filterAlerts = inv.namedArguments[#filterAlertsEnabled] as bool;
      return Success(
        _prefs(global: global, messages: messages, filterAlerts: filterAlerts),
      );
    });
  }

  setUp(() {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    repo = _MockNotificationsRepository();
    client = _FakePushMessagingClient();
    authGate = const _FakeAuthGate();
    pushRegistration = PushNotificationRegistrationService(
      messagingClient: client,
      notificationsRepository: repo,
      authGate: authGate,
      readLocalePreference: () => AppLocalePreference.ru,
    );

    registerFallbackValue(PushTokenPlatform.android);
    when(
      () => repo.getMyPreferences(),
    ).thenAnswer((_) async => Success(_prefs()));
    stubRepoSuccess();
    when(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async => const Success<void>(null));
    when(
      () => repo.deactivateMyPushTokens(),
    ).thenAnswer((_) async => const Success<void>(null));
  });

  tearDown(() async {
    await pushRegistration.dispose();
    await client.close();
  });

  NotificationSettingsCubit buildCubit() => NotificationSettingsCubit(
    notificationsRepository: repo,
    pushRegistration: pushRegistration,
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'load reads preferences via repository and reflects permission when push on',
    build: buildCubit,
    act: (c) => c.load(),
    verify: (_) {
      verify(() => repo.getMyPreferences()).called(1);
      expect(client.getPermissionStatusCalls, greaterThan(0));
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'load failure surfaces failure phase without crashing',
    setUp: () {
      when(
        () => repo.getMyPreferences(),
      ).thenAnswer((_) async => FailureResult(const UnknownFailure('x')));
    },
    build: buildCubit,
    act: (c) => c.load(),
    expect: () => [
      isA<NotificationSettingsState>()
          .having(
            (s) => s.phase,
            'phase',
            NotificationSettingsLoadPhase.loading,
          )
          .having((s) => s.preferences, 'prefs', isNull),
      isA<NotificationSettingsState>()
          .having(
            (s) => s.phase,
            'phase',
            NotificationSettingsLoadPhase.failure,
          )
          .having((s) => s.notice, 'notice', NotificationUserNotice.loadFailed),
    ],
  );

  group('push disabled via env', () {
    late PushNotificationRegistrationService regNoPush;

    setUp(() {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
''',
      );
      regNoPush = PushNotificationRegistrationService(
        messagingClient: client,
        notificationsRepository: repo,
        authGate: authGate,
        readLocalePreference: () => AppLocalePreference.ru,
      );
    });

    tearDown(() async {
      await regNoPush.dispose();
    });

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'enabling global does not call permission or update',
      build: () => NotificationSettingsCubit(
        notificationsRepository: repo,
        pushRegistration: regNoPush,
      ),
      seed: () => NotificationSettingsState(
        phase: NotificationSettingsLoadPhase.ready,
        preferences: _prefs(),
      ),
      act: (c) => c.setGlobalEnabled(true),
      expect: () => [
        isA<NotificationSettingsState>().having(
          (s) => s.notice,
          'notice',
          NotificationUserNotice.pushUnavailableInBuild,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repo.updateMyPreferences(
            globalEnabled: any(named: 'globalEnabled'),
            messagesEnabled: any(named: 'messagesEnabled'),
            filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
          ),
        );
        expect(client.permissionRequestCalls, 0);
      },
    );

    blocTest<NotificationSettingsCubit, NotificationSettingsState>(
      'filter alerts enabled does not call repository when push disabled',
      build: () => NotificationSettingsCubit(
        notificationsRepository: repo,
        pushRegistration: regNoPush,
      ),
      seed: () => NotificationSettingsState(
        phase: NotificationSettingsLoadPhase.ready,
        preferences: _prefs(global: true, messages: false, filterAlerts: false),
      ),
      act: (c) => c.setFilterAlertsEnabled(true),
      expect: () => [
        isA<NotificationSettingsState>().having(
          (s) => s.notice,
          'notice',
          NotificationUserNotice.pushUnavailableInBuild,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repo.updateMyPreferences(
            globalEnabled: any(named: 'globalEnabled'),
            messagesEnabled: any(named: 'messagesEnabled'),
            filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
          ),
        );
        expect(client.permissionRequestCalls, 0);
      },
    );
  });

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'turning global on requests permission; denied keeps server prefs unchanged',
    setUp: () {
      client.permissionStatus = PushMessagingPermissionStatus.notDetermined;
      client.permissionAfterRequest = PushMessagingPermissionStatus.denied;
    },
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(),
    ),
    act: (c) => c.setGlobalEnabled(true),
    expect: () => [
      isA<NotificationSettingsState>().having((s) => s.busy, 'busy', true),
      isA<NotificationSettingsState>()
          .having((s) => s.busy, 'busy', false)
          .having(
            (s) => s.notice,
            'notice',
            NotificationUserNotice.osPermissionDenied,
          ),
    ],
    verify: (_) {
      expect(client.permissionRequestCalls, 1);
      verifyNever(
        () => repo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      );
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'turning global on with permission updates prefs with filter_alerts false and registers token',
    setUp: () {
      client.permissionStatus = PushMessagingPermissionStatus.authorized;
      client.permissionAfterRequest = PushMessagingPermissionStatus.authorized;
    },
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(messages: true),
    ),
    act: (c) => c.setGlobalEnabled(true),
    verify: (_) {
      verify(
        () => repo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: false,
        ),
      ).called(1);
      verify(
        () => repo.registerPushToken(
          token: 'test-fcm-token',
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
          deviceId: any(named: 'deviceId'),
          locale: any(named: 'locale'),
        ),
      ).called(1);
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'turning global off disables messages on server and revokes tokens',
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: true, messages: true),
    ),
    act: (c) => c.setGlobalEnabled(false),
    verify: (_) {
      verify(
        () => repo.updateMyPreferences(
          globalEnabled: false,
          messagesEnabled: false,
          filterAlertsEnabled: false,
        ),
      ).called(1);
      verify(() => repo.deactivateMyPushTokens()).called(1);
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'message toggle no-op when global off',
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: false, messages: false),
    ),
    act: (c) => c.setMessagesEnabled(true),
    verify: (_) {
      verifyNever(
        () => repo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      );
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'message toggle on updates with filter_alerts false',
    setUp: () {
      client.permissionStatus = PushMessagingPermissionStatus.authorized;
    },
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: true, messages: false),
    ),
    act: (c) => c.setMessagesEnabled(true),
    verify: (_) {
      verify(
        () => repo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: false,
        ),
      ).called(1);
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'message toggle off does not revoke all tokens',
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: true, messages: true),
    ),
    act: (c) => c.setMessagesEnabled(false),
    verify: (_) {
      verify(
        () => repo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: false,
          filterAlertsEnabled: false,
        ),
      ).called(1);
      verifyNever(() => repo.deactivateMyPushTokens());
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'filter alerts toggle on requests permission and preserves messages flag',
    setUp: () {
      client.permissionStatus = PushMessagingPermissionStatus.notDetermined;
      client.permissionAfterRequest = PushMessagingPermissionStatus.authorized;
    },
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: true, messages: true, filterAlerts: false),
    ),
    act: (c) => c.setFilterAlertsEnabled(true),
    verify: (_) {
      verify(
        () => repo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: true,
        ),
      ).called(1);
      verify(
        () => repo.registerPushToken(
          token: 'test-fcm-token',
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
          deviceId: any(named: 'deviceId'),
          locale: any(named: 'locale'),
        ),
      ).called(1);
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'filter alerts toggle off does not disable messages',
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: true, messages: true, filterAlerts: true),
    ),
    act: (c) => c.setFilterAlertsEnabled(false),
    verify: (_) {
      verify(
        () => repo.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: false,
        ),
      ).called(1);
      verifyNever(() => repo.deactivateMyPushTokens());
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'filter alerts toggle no-op when global off',
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: false, messages: false, filterAlerts: true),
    ),
    act: (c) => c.setFilterAlertsEnabled(true),
    verify: (_) {
      verifyNever(
        () => repo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      );
    },
  );

  blocTest<NotificationSettingsCubit, NotificationSettingsState>(
    'update failure surfaces save notice',
    setUp: () {
      client.permissionStatus = PushMessagingPermissionStatus.authorized;
      when(
        () => repo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      ).thenAnswer((_) async => FailureResult(const UnknownFailure('save')));
    },
    build: buildCubit,
    seed: () => NotificationSettingsState(
      phase: NotificationSettingsLoadPhase.ready,
      preferences: _prefs(global: true, messages: false),
    ),
    act: (c) => c.setMessagesEnabled(true),
    expect: () => [
      isA<NotificationSettingsState>().having((s) => s.busy, 'busy', true),
      isA<NotificationSettingsState>()
          .having((s) => s.busy, 'busy', false)
          .having((s) => s.notice, 'notice', NotificationUserNotice.saveFailed),
    ],
  );
}
