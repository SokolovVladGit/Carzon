import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

const _keys = [
  'createListingSmartFillLoading',
  'createListingSmartFillSeveralVersions',
  'createListingSmartFillAskBody',
  'createListingSmartFillAskFuel',
  'createListingSmartFillAskTransmission',
  'createListingSmartFillDontKnow',
  'createListingSmartFillNoData',
  'createListingSmartFillFailed',
];

void main() {
  test('RU/RO Smart Fill keys exist and are localized', () {
    final ruArb =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync())
            as Map<String, dynamic>;
    final roArb =
        jsonDecode(File('lib/l10n/app_ro.arb').readAsStringSync())
            as Map<String, dynamic>;
    final ru = ruStrings();
    final ro = roStrings();

    for (final key in _keys) {
      expect(ruArb[key], isA<String>());
      expect(roArb[key], isA<String>());
      expect((ruArb[key] as String).trim(), isNotEmpty);
      expect((roArb[key] as String).trim(), isNotEmpty);
    }

    expect(ru.createListingSmartFillDontKnow, isNot('I don\'t know'));
    expect(ro.createListingSmartFillDontKnow, isNot('I don\'t know'));
    expect(
      ru.createListingSmartFillDontKnow,
      isNot(ro.createListingSmartFillDontKnow),
    );
    expect(ru.createListingSmartFillAskBody, contains('кузов'));
    expect(ro.createListingSmartFillAskFuel, contains('combustibil'));
    expect(ru.createListingSmartFillAskTransmission, contains('коробка'));
    expect(ro.createListingSmartFillAskTransmission, contains('cutie'));
    expect(
      ru.createListingSmartFillFailed,
      isNot(ru.createListingVinResolverFailed),
    );
  });
}
