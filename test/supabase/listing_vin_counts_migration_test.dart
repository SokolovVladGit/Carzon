import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20261006170000_listing_vin_counts.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20261006170000_listing_vin_counts.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('adds nullable count columns with conservative checks', () {
      expect(sql, contains('add column if not exists engine_cylinders integer'));
      expect(sql, contains('add column if not exists doors integer'));
      expect(sql, contains('add column if not exists seats integer'));
      expect(sql, contains('listings_engine_cylinders_check'));
      expect(sql, contains('engine_cylinders >= 1 and engine_cylinders <= 16'));
      expect(sql, contains('doors >= 1 and doors <= 6'));
      expect(sql, contains('seats >= 1 and seats <= 15'));
    });

    test('create and update RPCs persist the counts', () {
      expect(sql, contains('p_engine_cylinders'));
      expect(sql, contains('p_doors'));
      expect(sql, contains('p_seats'));
      expect(sql, contains('invalid engine_cylinders'));
      expect(sql, contains('invalid doors'));
      expect(sql, contains('invalid seats'));
      expect(sql, contains('engine_cylinders,'));
      expect(sql, contains('engine_cylinders            = v_cylinders'));
    });

    test('drops the previous signatures and grants the longer ones', () {
      expect(
        sql,
        contains(
          'drop function if exists public.create_listing_v2(',
        ),
      );
      expect(
        sql,
        contains(
          'drop function if exists public.update_listing_details_v2(',
        ),
      );
      expect(sql, contains('integer, integer, integer'));
      expect(
        sql,
        contains(
          'grant select (engine_cylinders, doors, seats)',
        ),
      );
    });

    test('does not touch hosted-only or unrelated objects', () {
      expect(sql.toLowerCase(), isNot(contains('enginehp')));
      expect(sql.toLowerCase(), isNot(contains('vehicle_model_catalog')));
    });
  });
}
