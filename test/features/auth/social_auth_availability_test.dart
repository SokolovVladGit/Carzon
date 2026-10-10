import 'package:carzon/features/auth/domain/social/social_auth_availability.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUp(() {
    dotenv.testLoad(fileInput: '');
  });

  tearDown(() {
    dotenv.testLoad(fileInput: '');
  });

  test('iOS hides Google when client IDs are missing and shows Apple', () {
    final availability = SocialAuthAvailability.fromEnv(
      platform: TargetPlatform.iOS,
    );
    expect(availability.googleEnabled, isFalse);
    expect(availability.appleEnabled, isTrue);
    expect(availability.hasAny, isTrue);
  });

  test('iOS shows Google when both client IDs are configured', () {
    dotenv.testLoad(
      fileInput: '''
GOOGLE_WEB_CLIENT_ID=web.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=ios.apps.googleusercontent.com
''',
    );
    final availability = SocialAuthAvailability.fromEnv(
      platform: TargetPlatform.iOS,
    );
    expect(availability.googleEnabled, isTrue);
    expect(availability.appleEnabled, isTrue);
  });

  test('Android hides Google until Android OAuth is explicitly enabled', () {
    dotenv.testLoad(
      fileInput: '''
GOOGLE_WEB_CLIENT_ID=web.apps.googleusercontent.com
GOOGLE_IOS_CLIENT_ID=ios.apps.googleusercontent.com
''',
    );
    final availability = SocialAuthAvailability.fromEnv(
      platform: TargetPlatform.android,
    );
    expect(availability.googleEnabled, isFalse);
    expect(availability.appleEnabled, isFalse);
    expect(availability.hasAny, isFalse);
  });
}
