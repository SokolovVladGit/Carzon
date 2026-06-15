import 'package:carzon/features/vehicle_model_data/domain/entities/buyer_listing_model_data_source_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuyerListingModelDataSourceResult.tryParse', () {
    test('parses full EPA row', () {
      final row = BuyerListingModelDataSourceResult.tryParse({
        'source_id': 'epa_fueleconomy',
        'status': 'succeeded',
        'confidence': 'official',
        'normalized_summary': {
          'combined_mpg': 32,
          'combined_l_per_100km': 7.4,
          'market': 'US',
        },
        'limitation_codes': ['us_market_data_only', 'not_recall_data'],
        'match_quality': 'exact_make_model_year',
        'source_label': 'EPA · FuelEconomy.gov',
        'provider_version': 'fueleconomy_ws_v1',
        'fetched_at': '2026-06-15T12:00:00Z',
        'ttl_until': '2026-09-15T12:00:00Z',
        'updated_at': '2026-06-15T12:00:01Z',
      });

      expect(row, isNotNull);
      expect(row!.sourceId, 'epa_fueleconomy');
      expect(row.status, 'succeeded');
      expect(row.normalizedSummary?['combined_mpg'], 32);
      expect(row.limitationCodes, contains('not_recall_data'));
      expect(row.fetchedAt, isNotNull);
      expect(row.ttlUntil, isNotNull);
    });

    test('parses partial/missing fields safely', () {
      final row = BuyerListingModelDataSourceResult.tryParse({
        'source_id': 'epa_fueleconomy',
        'status': 'partial',
        'normalized_summary': {},
        'limitation_codes': null,
      });

      expect(row, isNotNull);
      expect(row!.normalizedSummary, isEmpty);
      expect(row.limitationCodes, isEmpty);
      expect(row.sourceLabel, isNull);
    });

    test('parses limitation codes with null entries', () {
      final row = BuyerListingModelDataSourceResult.tryParse({
        'source_id': 'epa_fueleconomy',
        'limitation_codes': ['us_market_data_only', null, '  '],
      });

      expect(row?.limitationCodes, ['us_market_data_only']);
    });

    test('returns null when source_id missing', () {
      expect(
        BuyerListingModelDataSourceResult.tryParse({'status': 'partial'}),
        isNull,
      );
    });
  });
}
