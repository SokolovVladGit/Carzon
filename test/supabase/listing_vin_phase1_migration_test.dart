import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260616120000_listing_vin_phase1.sql`.
void main() {
  group('20260616120000_listing_vin_phase1.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260616120000_listing_vin_phase1.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'VIN migration must exist');
      sql = f.readAsStringSync();
    });

    test('adds listings.vin_status with CHECK', () {
      expect(sql.toLowerCase(), contains('vin_status'));
      expect(sql.toLowerCase(), contains('listings_vin_status_chk'));
      expect(sql, contains("'not_provided'"));
      expect(sql, contains("'format_valid'"));
    });

    test('does not add a standalone vin column to public.listings', () {
      final listingAlter = RegExp(
        r'alter\s+table\s+public\.listings\b[\s\S]*?;',
        caseSensitive: false,
      );
      final standaloneVinCol = RegExp(
        r'\badd\s+column\b[\s\S]{0,220}?\bvin\b(?![a-z0-9_])',
        caseSensitive: false,
      );
      for (final m in listingAlter.allMatches(sql)) {
        final stmt = m.group(0)!;
        if (!stmt.toLowerCase().contains('add column')) continue;
        expect(
          standaloneVinCol.hasMatch(stmt),
          isFalse,
          reason:
              'public.listings must not gain a plaintext vin column (vin_status only).',
        );
      }
    });

    test('defines listing_vehicle_identity private table', () {
      expect(sql.toLowerCase(), contains('create table'));
      expect(sql.toLowerCase(), contains('listing_vehicle_identity'));
    });

    test('enables RLS on listing_vehicle_identity', () {
      expect(
        sql.toLowerCase(),
        contains(
          'alter table public.listing_vehicle_identity enable row level security',
        ),
      );
    });

    test('revokes anon/authenticated grants on private table', () {
      expect(
        sql.toLowerCase(),
        contains('revoke all on table public.listing_vehicle_identity'),
      );
      expect(sql.toLowerCase(), contains('from anon'));
      expect(sql.toLowerCase(), contains('from authenticated'));
    });

    test('defines get_my_listing_vehicle_identity for authenticated only', () {
      expect(sql.toLowerCase(), contains('get_my_listing_vehicle_identity'));
      expect(
        sql.toLowerCase(),
        contains(
          'grant execute on function public.get_my_listing_vehicle_identity(uuid)',
        ),
      );
    });

    test('extends create_listing_v2 with trailing p_vin', () {
      expect(
        sql.toLowerCase(),
        contains('create function public.create_listing_v2('),
      );
      expect(sql.toLowerCase(), contains('p_vin'));
      expect(
        sql.toLowerCase(),
        contains(
          'grant execute on function public.create_listing_v2(\n'
          '    text, text, text, integer, numeric, integer,\n'
          '    text, text, text, text, text, boolean,\n'
          '    text, text, text[], text[], text,\n'
          '    text, numeric, integer, text, text, text,\n'
          '    text\n'
          ') to authenticated;',
        ),
      );
    });

    test('extends update_listing_details_v2 with trailing p_vin', () {
      expect(
        sql.toLowerCase(),
        contains('create function public.update_listing_details_v2('),
      );
      expect(
        sql.toLowerCase(),
        contains(
          'grant execute on function public.update_listing_details_v2(\n'
          '    uuid, text, text, text, integer, numeric, text, integer,\n'
          '    text, text, text, text, text, boolean, text,\n'
          '    text, numeric, integer, text, text, text,\n'
          '    text\n'
          ') to authenticated;',
        ),
      );
    });
  });
}
