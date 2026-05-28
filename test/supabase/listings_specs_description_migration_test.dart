import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for listing vehicle specs + description migration.
void main() {
  group('20260521120000_listing_specs_description.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260521120000_listing_specs_description.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('adds nullable listing columns', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('fuel_type'), isTrue);
      expect(lower.contains('engine_displacement_liters'), isTrue);
      expect(lower.contains('engine_power_hp'), isTrue);
      expect(lower.contains('drivetrain'), isTrue);
      expect(lower.contains('registration'), isTrue);
      expect(lower.contains('description'), isTrue);
    });

    test('extends create_listing_v2 and update_listing_details_v2', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('p_description'), isTrue);
      expect(lower.contains('p_fuel_type'), isTrue);
      expect(lower.contains('p_registration'), isTrue);
      expect(
        lower.contains('drop function if exists public.create_listing_v2'),
        isTrue,
      );
      expect(
        lower.contains(
          'drop function if exists public.update_listing_details_v2',
        ),
        isTrue,
      );
    });

    test('authenticated execute grants; revokes anon/public', () {
      expect(
        sql,
        contains('grant execute on function public.create_listing_v2('),
      );
      expect(
        sql,
        contains('grant execute on function public.update_listing_details_v2('),
      );
      expect(sql.toLowerCase(), contains('revoke all'));
    });
  });
}
