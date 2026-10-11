import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const iosClientId =
      '68189143516-ahrske7madnpca3jrqtl87sfl3npp2j2.apps.googleusercontent.com';
  const webClientId =
      '68189143516-o1l6ks0phe0fg6n429023b6k8pbugese.apps.googleusercontent.com';
  const googleScheme =
      'com.googleusercontent.apps.68189143516-ahrske7madnpca3jrqtl87sfl3npp2j2';

  late String plist;

  setUpAll(() {
    plist = File('ios/Runner/Info.plist').readAsStringSync();
  });

  test('Info.plist keeps carzon and the reversed iOS OAuth scheme', () {
    expect(
      googleScheme,
      'com.googleusercontent.apps.${iosClientId.split('.apps.googleusercontent.com').first}',
    );
    expect(googleScheme.contains(webClientId.split('.').first), isFalse);

    final schemes = RegExp(
      r'<key>CFBundleURLSchemes</key>\s*<array>\s*<string>([^<]+)</string>',
    ).allMatches(plist).map((match) => match.group(1)).toList();
    expect(schemes, <String>['carzon', googleScheme]);
    expect(plist.contains(webClientId), isFalse);
    expect(plist.contains('CFBundleURLTypes'), isTrue);
  });
}
