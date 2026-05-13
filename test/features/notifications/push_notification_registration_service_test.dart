import 'dart:async';

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
  String? token = 'fake-token';
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
    permissionStatus = PushMessagingPermissionStatus.authorized;
    return permissionStatus;
  }

  @override
  Future<String?> getFcmToken() async => token;

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
    sut = PushNotificationRegistrationService(
      messagingClient: client,
      notificationsRepository: repo,
      authGate: authGate,
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
    when(() => repo.deactivateMyPushTokens()).thenAnswer(
      (_) async => const Success<void>(null),
    );
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

  test('when push disabled via env, start does not initialize Firebase', () async {
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
  });

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

  test('sync registers when push enabled, signed in, permission ok, token set', () async {
    await sut.syncTokenWithBackendIfEligible();
    verify(
      () => repo.registerPushToken(
        token: 'fake-token',
        platform: any(named: 'platform'),
        appVersion: null,
        deviceId: null,
        locale: null,
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
        locale: null,
      ),
    ).called(1);
  });

  test('beforeSignOut calls deactivateMyPushTokens when signed in', () async {
    await sut.beforeSignOut();
    verify(() => repo.deactivateMyPushTokens()).called(1);
  });
}
