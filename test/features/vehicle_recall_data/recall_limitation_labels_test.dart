import 'package:carzon/features/vehicle_recall_data/presentation/utils/recall_limitation_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();
  final ro = roStrings();

  const knownCodes = [
    'us_market_data_only',
    'model_level_not_exact_vehicle',
    'not_vin_verified_recall_status',
    'may_differ_by_trim_engine_market',
    'verify_with_official_dealer_or_nhtsa',
    'multiple_campaigns_listed',
    'source_data_unavailable',
  ];

  test('all known codes map to localized strings in RU', () {
    for (final code in knownCodes) {
      final bullets = localizedRecallLimitationBullets(ru, [code]);
      expect(bullets, isNotEmpty);
      expect(bullets.any((b) => b.contains(code)), isFalse);
    }
  });

  test('unknown code maps to generic localized string', () {
    final bullets = localizedRecallLimitationBullets(ru, [
      'totally_unknown_code',
    ]);
    expect(bullets, contains(ru.listingRecallLimitationGeneric));
    expect(bullets.any((b) => b.contains('totally_unknown_code')), isFalse);
  });

  test('empty codes use conservative defaults', () {
    final bullets = localizedRecallLimitationBullets(ru, const []);
    expect(bullets.length, greaterThanOrEqualTo(4));
    expect(bullets, contains(ru.listingRecallLimitationUsMarketDataOnly));
    expect(
      bullets,
      contains(ru.listingRecallLimitationModelLevelNotExactVehicle),
    );
    expect(
      bullets,
      contains(ru.listingRecallLimitationNotVinVerifiedRecallStatus),
    );
  });

  test('RO localization accessors exist for limitation labels', () {
    expect(ro.listingRecallLimitationUsMarketDataOnly, isNotEmpty);
    expect(ro.listingRecallLimitationGeneric, isNotEmpty);
  });
}
