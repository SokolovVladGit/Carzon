import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('buyer VIN report ARB block avoids forbidden verification claims', () {
    final raw = File('lib/l10n/app_ru.arb').readAsStringSync();
    final start = raw.indexOf('"listingBuyerVinReportTitle"');
    expect(start, greaterThan(-1));
    final tail = raw.substring(start);
    const forbidden = [
      'VIN проверен',
      'Официально проверено',
      'официально подтверждён',
      'История проверена',
      'история проверена',
      'проверено по базе',
      'Без ДТП',
      'без ДТП',
      'Чистая история',
      'чистая история',
      'Автомобиль полностью проверен',
      'Юридически чистый',
      'Пробег подтверждён',
      'Ограничений нет',
    ];
    for (final phrase in forbidden) {
      expect(tail.contains(phrase), isFalse, reason: phrase);
    }
    expect(
      tail.contains('listingBuyerVinReportNhtsaCatalogDecodeCaution'),
      isTrue,
    );
    expect(
      tail.contains('listingBuyerVinReportManualSourcesSectionTitle'),
      isTrue,
    );
    expect(tail.contains('listingBuyerVinReportManualMdRcaTitle'), isTrue);
  });
}
