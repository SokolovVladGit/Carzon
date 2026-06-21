import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for seller-entered transmission_type migration.
void main() {
  group('20260711120000_listing_transmission_type.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260711120000_listing_transmission_type.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('adds nullable transmission_type column with CHECK values', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('transmission_type'), isTrue);
      for (final value in [
        'manual',
        'automatic',
        'cvt',
        'robotic',
        'dual_clutch',
        'other',
      ]) {
        expect(lower.contains("'$value'"), isTrue, reason: value);
      }
    });

    test('extends create_listing_v2 and update_listing_details_v2', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('p_transmission_type'), isTrue);
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
      expect(lower.contains('invalid transmission_type'), isTrue);
    });

    test('drops pre-transmission RPC signatures before recreate', () {
      const preTransmissionCreateDrop = '''
drop function if exists public.create_listing_v2(
    text, text, text, integer, numeric, integer,
    text, text, text, text, text, boolean,
    text, text, text[], text[], text,
    text, numeric, integer, text, text, text,
    text
);''';

      const preTransmissionUpdateDrop = '''
drop function if exists public.update_listing_details_v2(
    uuid, text, text, text, integer, numeric, text, integer,
    text, text, text, text, text, boolean, text,
    text, numeric, integer, text, text, text,
    text
);''';

      expect(sql, contains(preTransmissionCreateDrop));
      expect(sql, contains(preTransmissionUpdateDrop));

      final createDropStart =
          sql.indexOf('drop function if exists public.create_listing_v2');
      final createDropEnd = sql.indexOf(');', createDropStart) + 3;
      final createDrop = sql.substring(createDropStart, createDropEnd);
      expect(
        createDrop,
        isNot(contains('text, numeric, integer, text, text, text, text,')),
      );

      final updateDropStart = sql.indexOf(
        'drop function if exists public.update_listing_details_v2',
      );
      final updateDropEnd = sql.indexOf(');', updateDropStart) + 3;
      final updateDrop = sql.substring(updateDropStart, updateDropEnd);
      expect(
        updateDrop,
        isNot(contains('text, numeric, integer, text, text, text, text,')),
      );
    });

    test('public select grant includes transmission_type', () {
      expect(sql, contains('transmission_type,'));
      expect(sql.toLowerCase(), contains('grant select ('));
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
