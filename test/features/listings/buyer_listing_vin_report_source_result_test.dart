import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuyerListingVinReportSourceResult', () {
    test('tryParse maps RPC row and tolerates odd values', () {
      final r = BuyerListingVinReportSourceResult.tryParse({
        'source_id': ' nhtsa_vpic ',
        'status': 'odd',
        'visibility': 'public_summary',
        'normalized_summary': {'year': '2020'},
        'limitation_codes': ['a', null],
        'requires_user_consent': false,
      });
      expect(r, isNotNull);
      expect(r!.sourceId, 'nhtsa_vpic');
      expect(r.normalizedSummary?['year'], '2020');
    });

    test('tryParse preserves expanded NHTSA summary keys', () {
      final r = BuyerListingVinReportSourceResult.tryParse({
        'source_id': 'nhtsa_vpic',
        'normalized_summary': {
          'make': 'BMW',
          'trim': 'xDrive',
          'plant_country': 'Germany',
          'drive_type': 'AWD',
        },
      });
      expect(r, isNotNull);
      expect(r!.normalizedSummary?['trim'], 'xDrive');
      expect(r.normalizedSummary?['plant_country'], 'Germany');
    });

    test('tryParse returns null when source_id missing', () {
      expect(BuyerListingVinReportSourceResult.tryParse({}), isNull);
    });
  });
}
