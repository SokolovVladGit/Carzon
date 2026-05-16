import 'package:carzon/features/listings/presentation/utils/buyer_vin_report_limitation_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  test('basic_decode_only expands to full standard limitation set', () {
    final out = localizedBuyerVinReportLimitationBullets(
      l10n,
      const ['basic_decode_only'],
    );
    expect(out, isNotEmpty);
    expect(out, contains(l10n.listingBuyerVinReportLimitationRegistrationMdPmr));
    expect(out, contains(l10n.listingBuyerVinReportLimitationOwner));
    expect(out, contains(l10n.listingBuyerVinReportLimitationLegalEncumbrances));
    for (final raw in [
      'basic_decode_only',
      'not_md_pmr_official_verification',
    ]) {
      expect(out.contains(raw), isFalse);
    }
  });

  test('known not_* codes map without raw tokens', () {
    final out = localizedBuyerVinReportLimitationBullets(
      l10n,
      const [
        'not_mileage_check',
        'not_accident_history',
      ],
    );
    expect(out, contains(l10n.listingBuyerVinReportLimitationMileage));
    expect(out, contains(l10n.listingBuyerVinReportLimitationAccidentHistory));
    expect(out, contains(l10n.listingBuyerVinReportLimitationLegalEncumbrances));
    expect(out.any((s) => s.contains('not_')), isFalse);
  });

  test('unknown code appends generic and hides raw token', () {
    final out = localizedBuyerVinReportLimitationBullets(
      l10n,
      const ['not_mileage_check', 'future_internal_reason'],
    );
    expect(out.last, l10n.listingBuyerVinReportLimitationUnknownFallback);
    expect(out.any((s) => s.contains('future_internal_reason')), isFalse);
  });

  test('empty codes yields empty list', () {
    expect(localizedBuyerVinReportLimitationBullets(l10n, const []), isEmpty);
  });
}
