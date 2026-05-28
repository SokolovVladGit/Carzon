import 'package:flutter_test/flutter_test.dart';

import 'package:carzon/features/notifications/domain/entities/push_token_platform.dart';

void main() {
  group('pushTokenPlatformToWire / pushTokenPlatformFromWire', () {
    test('round-trips core platforms', () {
      expect(pushTokenPlatformToWire(PushTokenPlatform.android), 'android');
      expect(pushTokenPlatformToWire(PushTokenPlatform.ios), 'ios');
      expect(pushTokenPlatformToWire(PushTokenPlatform.web), 'web');
      expect(pushTokenPlatformToWire(PushTokenPlatform.unknown), 'unknown');
      expect(pushTokenPlatformFromWire('android'), PushTokenPlatform.android);
      expect(pushTokenPlatformFromWire('IOS'), PushTokenPlatform.ios);
      expect(pushTokenPlatformFromWire(' Web '), PushTokenPlatform.web);
      expect(pushTokenPlatformFromWire(null), PushTokenPlatform.unknown);
      expect(pushTokenPlatformFromWire(''), PushTokenPlatform.unknown);
      expect(pushTokenPlatformFromWire('desktop'), PushTokenPlatform.unknown);
    });
  });
}
