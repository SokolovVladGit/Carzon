import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseRecallDataRemoteDataSource (static)', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/vehicle_recall_data/data/datasources/supabase_recall_data_remote_data_source.dart',
      ).readAsStringSync();
    });

    test('calls get_listing_recalls_for_buyer RPC only', () {
      expect(source, contains('get_listing_recalls_for_buyer'));
      expect(source, contains('p_listing_id'));
    });

    test('does not pass make/model/year or VIN params from Flutter', () {
      expect(source, isNot(contains('p_make')));
      expect(source, isNot(contains('p_model')));
      expect(source, isNot(contains('p_year')));
      expect(source, isNot(contains('p_vin')));
      expect(source, isNot(contains('vin_hash')));
    });

    test('does not read tables or unrelated RPCs directly', () {
      expect(source, isNot(contains('_supabase.client.from')));
      expect(source, isNot(contains('listing_vehicle_identity')));
      expect(source, isNot(contains('get_listing_model_data_for_buyer')));
      expect(source, isNot(contains('get_listing_vin_report_for_buyer')));
    });

    test('parses RPC payload via BuyerListingRecallSourceResult.fromRpcData', () {
      expect(source, contains('BuyerListingRecallSourceResult.fromRpcData'));
    });

    test('does not call external NHTSA HTTP', () {
      expect(source.toLowerCase(), isNot(contains('api.nhtsa.gov')));
      expect(source.toLowerCase(), isNot(contains('recallsbyvehicle')));
    });
  });
}
