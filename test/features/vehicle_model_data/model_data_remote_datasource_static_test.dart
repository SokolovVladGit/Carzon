import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseModelDataRemoteDataSource (static)', () {
    late String source;

    setUpAll(() {
      source = File(
        'lib/features/vehicle_model_data/data/datasources/supabase_model_data_remote_datasource.dart',
      ).readAsStringSync();
    });

    test('calls get_listing_model_data_for_buyer RPC only', () {
      expect(source, contains('get_listing_model_data_for_buyer'));
      expect(source, contains('p_listing_id'));
    });

    test('does not read tables or VIN-related RPCs directly', () {
      expect(source, isNot(contains('_supabase.client.from')));
      expect(source, isNot(contains('listing_vehicle_identity')));
      expect(source, isNot(contains('get_listing_vin_report_for_buyer')));
    });

    test('parses rows via BuyerListingModelDataSourceResult.tryParse', () {
      expect(source, contains('BuyerListingModelDataSourceResult.tryParse'));
    });
  });
}
