import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Romanian buyer VIN ARB block avoids forbidden verification claims', () {
    final raw = File('lib/l10n/app_ro.arb').readAsStringSync();
    final start = raw.indexOf('"listingBuyerVinReportTitle"');
    expect(start, greaterThan(-1));
    final tail = raw.substring(start).toLowerCase();
    const forbidden = [
      'vin verificat',
      'verificat oficial',
      'oficial confirmat',
      'istoric verificat',
      'fără accident',
      'fara accident',
      'istorie curată',
      'istorie curata',
      'complet verificat',
      'juridic curat',
      'kilometraj confirmat',
      'fără restricții',
      'fara restrictii',
      'mașină sigură',
      'masina sigura',
    ];
    for (final phrase in forbidden) {
      expect(tail.contains(phrase), isFalse, reason: phrase);
    }
  });
}
