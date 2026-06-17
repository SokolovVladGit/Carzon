import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260712120000_discovery_fuel_transmission_filter_alert.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260712120000_discovery_fuel_transmission_filter_alert.sql',
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

    test('matches fuelType JSON key against fuel_type column', () {
      expect(lower, contains("p_criteria->>'fueltype'"));
      expect(lower, contains('p_listing.fuel_type'));
    });

    test('matches transmissionType JSON key against transmission_type column', () {
      expect(lower, contains("p_criteria->>'transmissiontype'"));
      expect(lower, contains('p_listing.transmission_type'));
    });

    test('priceCurrencyFilter assignment closes lower(trim(coalesce(...)))', () {
      final line = sql
          .split('\n')
          .map((l) => l.trim())
          .firstWhere(
            (l) =>
                l.startsWith('v_pcf := lower(trim(both from coalesce(') &&
                l.contains("p_criteria->>'priceCurrencyFilter'"),
          );
      expect(
        line,
        "v_pcf := lower(trim(both from coalesce(p_criteria->>'priceCurrencyFilter', '')));",
        reason:
            'must close coalesce, trim, and lower — missing ) causes SQL 42601',
      );
    });

    test('lower(trim(coalesce assignments have balanced parentheses', () {
      final assignmentLines = sql
          .split('\n')
          .map((l) => l.trim())
          .where(
            (l) =>
                l.contains(':=') &&
                l.contains('lower(trim(both from coalesce('),
          );
      expect(assignmentLines, isNotEmpty);
      for (final line in assignmentLines) {
        final opens = '('.allMatches(line).length;
        final closes = ')'.allMatches(line).length;
        expect(
          opens,
          closes,
          reason: 'unbalanced parens on: $line',
        );
        expect(line.endsWith(');'), isTrue, reason: 'bad terminator: $line');
      }
    });
  });
}
