import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('edit listing VIN report ARB block avoids forbidden verification claims', () {
    final raw = File('lib/l10n/app_ru.arb').readAsStringSync();
    final start = raw.indexOf('"editListingVinReportSectionTitle"');
    expect(start, greaterThan(-1));
    final tail = raw.substring(start);
    const forbidden = [
      'VIN проверен',
      'официально подтверждён',
      'история проверена',
      'проверено по базе',
      'без ДТП',
      'чистая история',
    ];
    for (final phrase in forbidden) {
      expect(tail.contains(phrase), isFalse, reason: phrase);
    }
  });
}
