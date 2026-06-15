import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_campaign.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_source_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BuyerListingRecallCampaign.tryParse', () {
    test('parses all allowlisted fields', () {
      final campaign = BuyerListingRecallCampaign.tryParse({
        'campaign_number': '20TA01',
        'manufacturer': 'Toyota',
        'component': 'AIR BAGS',
        'summary': 'Sample summary',
        'consequence': 'Sample consequence',
        'remedy': 'Sample remedy',
        'notes': 'Sample notes',
        'report_received_date': '2020-02-01',
        'nhtsa_action_number': 'EA',
        'park_it': false,
        'park_outside': true,
        'over_the_air_update': 'false',
        'model_year': 2020,
        'make': 'TOYOTA',
        'model': 'Camry',
      });

      expect(campaign, isNotNull);
      expect(campaign!.campaignNumber, '20TA01');
      expect(campaign.parkIt, isFalse);
      expect(campaign.parkOutside, isTrue);
      expect(campaign.overTheAirUpdate, isFalse);
      expect(campaign.modelYear, 2020);
    });

    test('handles missing optional fields', () {
      final campaign = BuyerListingRecallCampaign.tryParse({
        'campaign_number': '20TA01',
        'summary': 'Only summary present',
      });

      expect(campaign?.component, isNull);
      expect(campaign?.manufacturer, isNull);
    });

    test('returns null when forbidden internal keys appear', () {
      expect(
        BuyerListingRecallCampaign.tryParse({
          'campaign_number': '20TA01',
          'source_metadata': {'raw': true},
        }),
        isNull,
      );
      expect(
        BuyerListingRecallCampaign.tryParse({
          'campaign_number': '20TA01',
          'vin_hash': 'abc',
        }),
        isNull,
      );
    });

    test('returns null when no displayable fields remain', () {
      expect(BuyerListingRecallCampaign.tryParse({}), isNull);
    });
  });

  group('BuyerListingRecallSourceResult', () {
    test('tryParseRow parses one RPC row with campaigns', () {
      final row = BuyerListingRecallSourceResult.tryParseRow({
        'source_id': 'nhtsa_recalls',
        'status': 'succeeded',
        'normalized_summary': {
          'campaigns': [
            {
              'campaign_number': '20TA01',
              'manufacturer': 'Toyota',
              'summary': 'Campaign one',
            },
            {
              'campaign_number': '20TA02',
              'component': 'FUEL SYSTEM',
            },
          ],
          'campaign_count': 2,
          'market': 'US',
          'match_quality': 'exact_make_model_year',
        },
        'limitation_codes': [
          'model_level_not_exact_vehicle',
          'not_vin_verified_recall_status',
        ],
        'match_quality': 'exact_make_model_year',
        'source_label': 'NHTSA',
        'fetched_at': '2026-06-15T12:00:00Z',
        'source_updated_at': '2020-03-01',
        'ttl_until': '2026-07-15T12:00:00Z',
        'updated_at': '2026-06-15T12:00:01Z',
      });

      expect(row, isNotNull);
      expect(row!.sourceId, 'nhtsa_recalls');
      expect(row.campaigns, hasLength(2));
      expect(row.campaignCount, 2);
      expect(row.market, 'US');
      expect(row.limitationCodes, contains('not_vin_verified_recall_status'));
      expect(row.fetchedAt, isNotNull);
      expect(row.sourceUpdatedAt, isNotNull);
    });

    test('fromRpcData returns empty for empty list', () {
      expect(
        BuyerListingRecallSourceResult.fromRpcData(<dynamic>[]),
        BuyerListingRecallSourceResult.empty,
      );
    });

    test('fromRpcData returns empty for null', () {
      expect(
        BuyerListingRecallSourceResult.fromRpcData(null),
        BuyerListingRecallSourceResult.empty,
      );
    });

    test('fromRpcData parses single-row list', () {
      final result = BuyerListingRecallSourceResult.fromRpcData([
        {
          'source_id': 'nhtsa_recalls',
          'status': 'partial',
          'normalized_summary': {
            'campaigns': [
              {'campaign_number': '20TA01', 'summary': 'One'},
            ],
            'campaign_count': 1,
            'market': 'US',
          },
        },
      ]);

      expect(result.hasCampaigns, isTrue);
      expect(result.campaignCount, 1);
      expect(result.status, 'partial');
    });

    test('ignores forbidden top-level keys', () {
      expect(
        BuyerListingRecallSourceResult.tryParseRow({
          'source_id': 'nhtsa_recalls',
          'cache_key': 'secret',
          'normalized_summary': {
            'campaigns': [
              {'campaign_number': '20TA01', 'summary': 'One'},
            ],
          },
        }),
        isNull,
      );
    });

    test('uses campaigns length when campaign_count missing', () {
      final row = BuyerListingRecallSourceResult.tryParseRow({
        'source_id': 'nhtsa_recalls',
        'normalized_summary': {
          'campaigns': [
            {'campaign_number': 'A', 'summary': 'A'},
            {'campaign_number': 'B', 'summary': 'B'},
          ],
        },
      });

      expect(row?.campaignCount, 2);
    });

    test('filters malformed campaign entries', () {
      final row = BuyerListingRecallSourceResult.tryParseRow({
        'source_id': 'nhtsa_recalls',
        'normalized_summary': {
          'campaigns': [
            {'campaign_number': 'OK', 'summary': 'Valid'},
            {},
            'bad',
            {'source_metadata': 'x', 'campaign_number': 'X'},
          ],
        },
      });

      expect(row?.campaigns, hasLength(1));
      expect(row?.campaigns.single.campaignNumber, 'OK');
    });
  });
}
