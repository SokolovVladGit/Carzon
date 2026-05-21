import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260629120000_vin_report_v2b_nhtsa_expanded_summary.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260629120000_vin_report_v2b_nhtsa_expanded_summary.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('extends NHTSA normalized_summary with snake_case catalog fields', () {
      expect(lower, contains("'manufacturer'"));
      expect(lower, contains("'plant_country'"));
      expect(lower, contains("'vehicle_type'"));
      expect(lower, contains("'drive_type'"));
      expect(lower, contains("'gross_vehicle_weight_rating'"));
      expect(lower, contains("'catalog_decode_caution'"));
    });

    test('does not expose vin, hash, or raw payloads in source results', () {
      expect(sql.toLowerCase(), isNot(contains('grant select on')));
      expect(sql.toLowerCase(), isNot(contains('to authenticated')));
      expect(sql.toLowerCase(), isNot(contains('to anon')));
      expect(sql, contains('to service_role'));
      expect(lower, isNot(contains('decodeerrorcode')));
      expect(lower, isNot(contains('decode_error_code')));
      expect(lower, isNot(contains('raw_payload')));
    });

    test('keeps public_summary and basic_decode for nhtsa_vpic', () {
      expect(lower, contains("'public_summary'"));
      expect(lower, contains("'basic_decode'"));
      expect(lower, contains("'nhtsa_vpic'"));
    });
  });
}
