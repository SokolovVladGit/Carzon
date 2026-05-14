import 'package:carzon/features/notifications/services/noop_push_messaging_client.dart';
import 'package:carzon/features/notifications/services/push_messaging_permission_status.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NoopPushMessagingClient', () {
    late NoopPushMessagingClient sut;

    setUp(() {
      sut = NoopPushMessagingClient();
    });

    test('initializeFirebase returns false', () async {
      expect(await sut.initializeFirebase(), isFalse);
    });

    test('permission APIs return notDetermined', () async {
      expect(
        await sut.getPermissionStatus(),
        PushMessagingPermissionStatus.notDetermined,
      );
      expect(
        await sut.requestPermission(),
        PushMessagingPermissionStatus.notDetermined,
      );
    });

    test('getFcmToken returns null', () async {
      expect(await sut.getFcmToken(), isNull);
    });

    test('watchTokenRefresh emits nothing', () async {
      expect(await sut.watchTokenRefresh().length, 0);
    });

    test('deleteFcmToken completes', () async {
      await expectLater(sut.deleteFcmToken(), completes);
    });
  });
}
