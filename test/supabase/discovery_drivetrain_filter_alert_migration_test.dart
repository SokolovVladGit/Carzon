import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260803120000_discovery_drivetrain_filter_alert.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260803120000_discovery_drivetrain_filter_alert.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('replaces listing_matches_saved_discovery_criteria', () {
      expect(
        lower,
        contains(
          'create or replace function public.listing_matches_saved_discovery_criteria',
        ),
      );
    });

    test('matches drivetrain JSON key against drivetrain column', () {
      expect(lower, contains("p_criteria->>'drivetrain'"));
      expect(lower, contains('p_listing.drivetrain'));
    });

    test('preserves fuelType and transmissionType matcher branches', () {
      expect(lower, contains("p_criteria->>'fueltype'"));
      expect(lower, contains("p_criteria->>'transmissiontype'"));
    });

    test('adds active feed partial index on drivetrain', () {
      expect(
        lower,
        contains('listings_feed_active_region_drivetrain_created_idx'),
      );
    });
  });
}
