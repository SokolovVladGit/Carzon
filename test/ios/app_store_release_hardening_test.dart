import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  final project = File(
    'ios/Runner.xcodeproj/project.pbxproj',
  ).readAsStringSync();
  final info = File('ios/Runner/Info.plist').readAsStringSync();
  final ru = File('ios/Runner/ru.lproj/InfoPlist.strings').readAsStringSync();
  final ro = File('ios/Runner/ro.lproj/InfoPlist.strings').readAsStringSync();

  test('Runner is iPhone-only in every app build configuration', () {
    expect(
      RegExp(r'TARGETED_DEVICE_FAMILY = 1;').allMatches(project),
      hasLength(3),
    );
    expect(project, isNot(contains('TARGETED_DEVICE_FAMILY = "1,2"')));
  });

  test('used photo and camera permission copy is localized', () {
    expect(info, contains('<key>NSPhotoLibraryUsageDescription</key>'));
    expect(info, contains('<key>NSCameraUsageDescription</key>'));
    expect(
      info,
      contains(
        'Carzon uses the camera so you can take a photo to send in chat.',
      ),
    );
    expect(info, isNot(contains('NSMicrophoneUsageDescription')));
    expect(info, isNot(contains('NSLocationWhenInUseUsageDescription')));
    expect(ru, contains('NSPhotoLibraryUsageDescription'));
    expect(ro, contains('NSPhotoLibraryUsageDescription'));
    expect(
      ru,
      contains(
        'Carzon использует камеру, чтобы вы могли сделать фотографию и отправить её в чате.',
      ),
    );
    expect(
      ro,
      contains(
        'Carzon folosește camera pentru a putea face o fotografie și a o trimite în chat.',
      ),
    );
    expect(project, contains('InfoPlist.strings'));
    expect(project, contains('ru.lproj'));
    expect(project, contains('ro.lproj'));
  });

  test('encryption declaration and supported localizations are explicit', () {
    expect(
      info,
      contains('<key>ITSAppUsesNonExemptEncryption</key>\n\t<false/>'),
    );
    expect(info, contains('<string>ru</string>'));
    expect(info, contains('<string>ro</string>'));
  });

  test('Runner privacy-manifest determination is documented', () {
    expect(File('ios/Runner/PrivacyInfo.xcprivacy').existsSync(), isFalse);
    final review = File(
      'docs/ios_privacy_manifest_review.md',
    ).readAsStringSync();
    expect(
      review,
      contains('No `ios/Runner/PrivacyInfo.xcprivacy` is required'),
    );
    expect(review, contains('release archive'));
    expect(review, contains('App Store Connect'));
  });
}
