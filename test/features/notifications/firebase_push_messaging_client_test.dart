import 'package:carzon/core/utils/logger.dart';
import 'package:carzon/features/notifications/services/firebase_push_messaging_client.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockFirebaseMessaging extends Mock implements FirebaseMessaging {}

void main() {
  late _MockFirebaseMessaging messaging;
  late AppLogger logger;
  late FirebasePushMessagingClient sut;

  setUp(() {
    messaging = _MockFirebaseMessaging();
    logger = AppLogger('testFirebasePush');
    sut = FirebasePushMessagingClient(messaging: messaging, logger: logger);
  });

  tearDown(() {
    debugDefaultTargetPlatformOverride = null;
  });

  group('getFcmToken', () {
    test(
      'on iOS, when APNs token is null, skips getToken and returns null without throwing',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(() => messaging.getAPNSToken()).thenAnswer((_) async => null);
        when(() => messaging.getToken()).thenAnswer((_) async => 'should-not-run');

        final token = await sut.getFcmToken();

        expect(token, isNull);
        verify(() => messaging.getAPNSToken()).called(1);
        verifyNever(() => messaging.getToken());
      },
    );

    test(
      'on iOS, FirebaseException apns-token-not-set is non-fatal (null, no rethrow)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(() => messaging.getAPNSToken()).thenAnswer((_) async => 'apns-token');
        when(() => messaging.getToken()).thenThrow(
          FirebaseException(
            plugin: 'firebase_messaging',
            code: 'apns-token-not-set',
            message: 'APNS token has not been received on the device yet.',
          ),
        );

        final token = await sut.getFcmToken();

        expect(token, isNull);
        verify(() => messaging.getToken()).called(1);
      },
    );

    test(
      'on iOS, other FirebaseException from getToken is logged path (returns null)',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
        when(() => messaging.getAPNSToken()).thenAnswer((_) async => 'apns');
        when(() => messaging.getToken()).thenThrow(
          FirebaseException(
            plugin: 'firebase_messaging',
            code: 'unknown-error',
            message: 'unexpected',
          ),
        );

        final token = await sut.getFcmToken();

        expect(token, isNull);
        verify(() => messaging.getToken()).called(1);
      },
    );

    test('on Android, does not call getAPNSToken; uses getToken only', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      when(() => messaging.getToken()).thenAnswer((_) async => 'android-fcm');

      final token = await sut.getFcmToken();

      expect(token, 'android-fcm');
      verifyNever(() => messaging.getAPNSToken());
      verify(() => messaging.getToken()).called(1);
    });
  });
}
