import 'package:carzon/features/vehicle_model_data/presentation/utils/model_passport_limitation_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();
  final ro = roStrings();

  const knownCodes = [
    'us_market_data_only',
    'may_differ_by_trim_engine_market',
    'model_level_not_exact_vehicle',
    'source_data_unavailable',
    'open_data_unverified',
    'not_vehicle_history',
    'not_recall_data',
    'multiple_configurations_possible',
    'basic_catalog_reference_only',
  ];

  test('all known codes map to localized strings in RU', () {
    for (final code in knownCodes) {
      final bullets = localizedModelPassportLimitationBullets(ru, [code]);
      expect(bullets, hasLength(1));
      expect(bullets.single, isNotEmpty);
      expect(bullets.single.contains(code), isFalse);
    }
  });

  test('unknown code maps to generic localized string', () {
    final bullets = localizedModelPassportLimitationBullets(ru, [
      'totally_unknown_code',
    ]);
    expect(bullets, contains(ru.listingModelPassportLimitationGeneric));
    expect(bullets.any((b) => b.contains('totally_unknown_code')), isFalse);
  });

  test('empty codes use conservative defaults', () {
    final bullets = localizedModelPassportLimitationBullets(ru, const []);
    expect(bullets.length, greaterThanOrEqualTo(4));
    expect(bullets, contains(ru.listingModelPassportLimitationUsMarketOnly));
    expect(bullets, contains(ru.listingModelPassportLimitationNotHistory));
    expect(bullets, contains(ru.listingModelPassportLimitationNotRecall));
  });

  test('RO localization accessors exist for limitation labels', () {
    expect(ro.listingModelPassportLimitationUsMarketOnly, isNotEmpty);
    expect(ro.listingModelPassportLimitationGeneric, isNotEmpty);
  });
}
