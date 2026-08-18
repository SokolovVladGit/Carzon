import 'dart:async';

import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/notifications/domain/entities/push_token_platform.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
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
  int initCalls = 0;
  int permissionRequestCalls = 0;
  bool initResult = true;
  PushMessagingPermissionStatus permissionStatus =
      PushMessagingPermissionStatus.authorized;
  PushMessagingPermissionStatus permissionAfterRequest =
      PushMessagingPermissionStatus.authorized;
  String? token = 'fake-token';
  Future<String?>? pendingToken;
  Completer<void>? tokenReadStarted;
  final StreamController<String> _refresh = StreamController.broadcast();

  @override
  Future<bool> initializeFirebase() async {
    initCalls++;
    return initResult;
  }

  @override
  Future<PushMessagingPermissionStatus> getPermissionStatus() async {
    return permissionStatus;
  }

  @override
  Future<PushMessagingPermissionStatus> requestPermission() async {
    permissionRequestCalls++;
    permissionStatus = permissionAfterRequest;
    return permissionStatus;
  }

  @override
  Future<String?> getFcmToken() async {
    tokenReadStarted?.complete();
    final pending = pendingToken;
    if (pending != null) return pending;
    return token;
  }

  @override
  Stream<String> watchTokenRefresh() => _refresh.stream;

  @override
  Future<void> deleteFcmToken() async {}

  void emitRefresh(String t) => _refresh.add(t);

  Future<void> close() async => _refresh.close();
}

class _FakeAuthGate implements PushAuthGate {
  _FakeAuthGate({this.signedIn = false});

  bool signedIn;

  @override
  bool get hasAuthenticatedUser => signedIn;
}

void main() {
  late _FakePushMessagingClient client;
  late _MockNotificationsRepository repo;
  late _FakeAuthGate authGate;
  late PushNotificationRegistrationService sut;
  AppLocalePreference localePreference = AppLocalePreference.ru;
  String? authenticatedUserId = 'user-a';

  setUp(() {
    dotenv.testLoad(
      fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
    );
    client = _FakePushMessagingClient();
    repo = _MockNotificationsRepository();
    authGate = _FakeAuthGate(signedIn: true);
    authenticatedUserId = 'user-a';
    localePreference = AppLocalePreference.ru;
    sut = PushNotificationRegistrationService(
      messagingClient: client,
      notificationsRepository: repo,
      authGate: authGate,
      readAuthenticatedUserId: () => authenticatedUserId,
      readLocalePreference: () => localePreference,
    );

    registerFallbackValue(PushTokenPlatform.android);
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
    await sut.dispose();
    await client.close();
    dotenv.testLoad(fileInput: '');
  });

  test('sync skips registration when Firebase init fails', () async {
    client.initResult = false;
    await sut.syncTokenWithBackendIfEligible();
    verifyNever(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    );
  });

  test('start does not call requestPermission', () async {
    await sut.start();
    expect(client.permissionRequestCalls, 0);
  });

  test(
    'when push disabled via env, start does not initialize Firebase',
    () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
      );
      await sut.start();
      expect(client.initCalls, 0);
      verifyNever(
        () => repo.registerPushToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
          deviceId: any(named: 'deviceId'),
          locale: any(named: 'locale'),
        ),
      );
    },
  );

  test(
    'requestOsNotificationPermission is a no-op when push disabled',
    () async {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
      );
      final status = await sut.requestOsNotificationPermission();
      expect(status, PushMessagingPermissionStatus.notDetermined);
      expect(client.permissionRequestCalls, 0);
    },
  );

  test('sync skips registration when not authenticated', () async {
    authGate.signedIn = false;
    await sut.syncTokenWithBackendIfEligible();
    expect(client.initCalls, greaterThan(0));
    verifyNever(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    );
  });

  test('sync skips registration when permission is not determined', () async {
    client.permissionStatus = PushMessagingPermissionStatus.notDetermined;
    await sut.syncTokenWithBackendIfEligible();
    verifyNever(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    );
  });

  test('sync skips registration when FCM token is empty', () async {
    client.token = '  ';
    await sut.syncTokenWithBackendIfEligible();
    verifyNever(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    );
  });

  test(
    'sync skips backend upsert when FCM token is null (e.g. APNs not ready)',
    () async {
      client.token = null;
      await sut.syncTokenWithBackendIfEligible();
      verifyNever(
        () => repo.registerPushToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
          deviceId: any(named: 'deviceId'),
          locale: any(named: 'locale'),
        ),
      );
    },
  );

  test(
    'sync registers when push enabled, signed in, permission ok, token set',
    () async {
      await sut.syncTokenWithBackendIfEligible();
      verify(
        () => repo.registerPushToken(
          token: 'fake-token',
          platform: any(named: 'platform'),
          appVersion: null,
          deviceId: null,
          locale: 'ru',
        ),
      ).called(1);
    },
  );

  test(
    'guard stops registration when session changes during token read',
    () async {
      final tokenRead = Completer<String?>();
      final tokenStarted = Completer<void>();
      client.pendingToken = tokenRead.future;
      client.tokenReadStarted = tokenStarted;
      var sessionCurrent = true;

      final sync = sut.syncTokenWithBackendIfEligible(
        isSessionCurrent: () => sessionCurrent,
      );
      await tokenStarted.future;
      sessionCurrent = false;
      tokenRead.complete('user-a-token');
      await sync;

      verifyNever(
        () => repo.registerPushToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
          deviceId: any(named: 'deviceId'),
          locale: any(named: 'locale'),
        ),
      );
    },
  );

  test('account switch reconciles an in-flight A registration for B', () async {
    final firstRegistrationStarted = Completer<void>();
    final releaseFirstRegistration = Completer<void>();
    final registrationUsers = <String?>[];
    when(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {
      registrationUsers.add(authenticatedUserId);
      if (registrationUsers.length == 1) {
        firstRegistrationStarted.complete();
        await releaseFirstRegistration.future;
      }
      return const Success<void>(null);
    });

    final userASync = sut.syncTokenWithBackendIfEligible();
    await firstRegistrationStarted.future;

    authenticatedUserId = 'user-b';
    sut.handleAuthStateChanged(authenticatedUserId);
    final userBSync = sut.syncTokenWithBackendIfEligible();
    releaseFirstRegistration.complete();

    await Future.wait([userASync, userBSync]);
    expect(registrationUsers, ['user-a', 'user-b']);
  });

  test('sign-out cleanup runs after an in-flight registration', () async {
    final registrationStarted = Completer<void>();
    final releaseRegistration = Completer<void>();
    final operations = <String>[];
    when(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {
      operations.add('register');
      registrationStarted.complete();
      await releaseRegistration.future;
      operations.add('register-complete');
      return const Success<void>(null);
    });
    when(() => repo.deactivateMyPushTokens()).thenAnswer((_) async {
      operations.add('deactivate');
      return const Success<void>(null);
    });

    final sync = sut.syncTokenWithBackendIfEligible();
    await registrationStarted.future;
    final signOut = sut.beforeSignOut();
    await Future<void>.delayed(Duration.zero);
    expect(operations, ['register']);

    releaseRegistration.complete();
    await Future.wait([sync, signOut]);
    expect(operations, ['register', 'register-complete', 'deactivate']);
  });

  test('concurrent sync calls share one backend registration', () async {
    final gate = Completer<void>();
    when(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((_) async {
      await gate.future;
      return const Success<void>(null);
    });

    final first = sut.syncTokenWithBackendIfEligible();
    await Future<void>.value();
    final second = sut.syncTokenWithBackendIfEligible();
    gate.complete();

    await first;
    await second;

    verify(
      () => repo.registerPushToken(
        token: 'fake-token',
        platform: any(named: 'platform'),
        appVersion: null,
        deviceId: null,
        locale: 'ru',
      ),
    ).called(1);
  });

  test(
    'concurrent direct token refresh for same token registers once',
    () async {
      await sut.start();
      clearInteractions(repo);

      final gate = Completer<void>();
      when(
        () => repo.registerPushToken(
          token: any(named: 'token'),
          platform: any(named: 'platform'),
          appVersion: any(named: 'appVersion'),
          deviceId: any(named: 'deviceId'),
          locale: any(named: 'locale'),
        ),
      ).thenAnswer((_) async {
        await gate.future;
        return const Success<void>(null);
      });

      client.emitRefresh('refresh-token');
      client.emitRefresh('refresh-token');
      await Future<void>.delayed(Duration.zero);
      gate.complete();
      await Future<void>.delayed(Duration.zero);

      verify(
        () => repo.registerPushToken(
          token: 'refresh-token',
          platform: any(named: 'platform'),
          appVersion: null,
          deviceId: null,
          locale: 'ru',
        ),
      ).called(1);
    },
  );

  test('sync passes ro locale when app preference is Romanian', () async {
    localePreference = AppLocalePreference.ro;
    await sut.syncTokenWithBackendIfEligible();
    verify(
      () => repo.registerPushToken(
        token: 'fake-token',
        platform: any(named: 'platform'),
        appVersion: null,
        deviceId: null,
        locale: 'ro',
      ),
    ).called(1);
  });

  test('provisional permission still registers', () async {
    client.permissionStatus = PushMessagingPermissionStatus.provisional;
    await sut.syncTokenWithBackendIfEligible();
    verify(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    ).called(1);
  });

  test('token refresh registers when still eligible', () async {
    await sut.start();
    clearInteractions(repo);
    client.emitRefresh('next-token');
    await Future<void>.delayed(Duration.zero);
    verify(
      () => repo.registerPushToken(
        token: 'next-token',
        platform: any(named: 'platform'),
        appVersion: null,
        deviceId: null,
        locale: 'ru',
      ),
    ).called(1);
  });

  test('token refresh queued during A to B switch finishes for B', () async {
    await sut.start();
    clearInteractions(repo);

    final firstRegistrationStarted = Completer<void>();
    final releaseFirstRegistration = Completer<void>();
    final registrations = <(String?, String)>[];
    when(
      () => repo.registerPushToken(
        token: any(named: 'token'),
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    ).thenAnswer((invocation) async {
      registrations.add((
        authenticatedUserId,
        invocation.namedArguments[#token] as String,
      ));
      if (registrations.length == 1) {
        firstRegistrationStarted.complete();
        await releaseFirstRegistration.future;
      }
      return const Success<void>(null);
    });

    client.emitRefresh('user-a-refresh');
    await firstRegistrationStarted.future;
    authenticatedUserId = 'user-b';
    sut.handleAuthStateChanged(authenticatedUserId);
    client.emitRefresh('user-b-refresh');
    releaseFirstRegistration.complete();
    await untilCalled(
      () => repo.registerPushToken(
        token: 'user-b-refresh',
        platform: any(named: 'platform'),
        appVersion: any(named: 'appVersion'),
        deviceId: any(named: 'deviceId'),
        locale: any(named: 'locale'),
      ),
    );

    expect(registrations, [
      ('user-a', 'user-a-refresh'),
      ('user-b', 'user-b-refresh'),
    ]);
  });

  test(
    'resolvePermissionForPreferenceEnable returns denied without prompting',
    () async {
      client.permissionStatus = PushMessagingPermissionStatus.denied;
      final status = await sut.resolvePermissionForPreferenceEnable();
      expect(status, PushMessagingPermissionStatus.denied);
      expect(client.permissionRequestCalls, 0);
    },
  );

  test(
    'resolvePermissionForPreferenceEnable prompts when notDetermined then returns status',
    () async {
      client.permissionStatus = PushMessagingPermissionStatus.notDetermined;
      client.permissionAfterRequest =
          PushMessagingPermissionStatus.notDetermined;
      final status = await sut.resolvePermissionForPreferenceEnable();
      expect(status, PushMessagingPermissionStatus.notDetermined);
      expect(client.permissionRequestCalls, 1);
    },
  );

  test('beforeSignOut calls deactivateMyPushTokens when signed in', () async {
    await sut.beforeSignOut();
    verify(() => repo.deactivateMyPushTokens()).called(1);
  });
}
