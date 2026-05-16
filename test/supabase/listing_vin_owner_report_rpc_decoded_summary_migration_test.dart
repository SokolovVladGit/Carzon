import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static guard for `20260622120000_owner_vin_report_rpc_decoded_summary.sql`.
void main() {
  group('20260622120000_owner_vin_report_rpc_decoded_summary.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260622120000_owner_vin_report_rpc_decoded_summary.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('redefines get_my_listing_vin_report_status with decoded columns', () {
      final lower = sql.toLowerCase();
      expect(lower, contains('drop function if exists'));
      expect(lower, contains('get_my_listing_vin_report_status'));
      expect(lower, contains('decoded_make'));
      expect(lower, contains('decoded_model'));
      expect(lower, contains('decoded_year'));
      expect(lower, contains('decoded_body_type'));
      expect(lower, contains('decoded_fuel_type'));
      expect(lower, contains('report_updated_at'));
    });

    test('select projection excludes vin_hash and full VIN columns', () {
      final lower = sql.toLowerCase();
      expect(lower, isNot(contains('vin_hash')));
      expect(lower, isNot(contains('vin_normalized')));
      expect(lower, isNot(contains('p_vin')));
    });

    test('preserves ownership check on listings.seller_id', () {
      expect(sql, contains('li.seller_id = auth.uid()'));
    });

    test('keeps authenticated-only execute grant', () {
      final lower = sql.toLowerCase();
      expect(
        lower,
        contains(
          'grant execute on function public.get_my_listing_vin_report_status',
        ),
      );
      expect(lower, contains('to authenticated'));
    });

    test('does not grant on internal snapshot table to anon/authenticated', () {
      expect(sql.toLowerCase(), isNot(contains('grant select')));
      expect(sql.toLowerCase(), isNot(contains('listing_vehicle_identity')));
    });
  });
}
