import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260511120000_listings_body_type.sql`: column, check, index, RPC wiring.
///
/// Mirrors other migration inspection tests — no live Postgres harness.
void main() {
  group('20260511120000_listings_body_type.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260511120000_listings_body_type.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'body_type migration must exist');
      sql = f.readAsStringSync();
    });

    test('adds nullable listings.body_type with allowed-value check', () {
      expect(sql.toLowerCase(), contains('alter table public.listings'));
      expect(sql, contains('body_type'));
      expect(sql.toLowerCase(), contains('listings_body_type_chk'));
      expect(sql.toLowerCase(), contains('body_type is null'));
      expect(sql, contains("'sedan'"));
      expect(sql, contains("'suv'"));
      expect(sql, contains("'other'"));
    });

    test('adds partial index for active feed (region, body, created_at)', () {
      expect(
        sql.toLowerCase(),
        contains('listings_feed_active_region_body_created_idx'),
      );
      expect(sql.toLowerCase(), contains('where status = \'active\''));
      expect(
        sql.toLowerCase(),
        contains('(market_region, body_type, created_at desc)'),
      );
    });

    test('create_listing_v2 includes p_body_type and validates it', () {
      expect(
        sql.toLowerCase(),
        contains('create function public.create_listing_v2('),
      );
      expect(sql, contains('p_body_type'));
      expect(sql.toLowerCase(), contains("raise exception 'invalid body_type"));
    });

    test(
      'update_listing_details_v2 includes p_body_type and assigns body_type',
      () {
        expect(
          sql.toLowerCase(),
          contains('create function public.update_listing_details_v2('),
        );
        expect(sql.toLowerCase(), contains('body_type         = v_body_type'));
      },
    );

    test('revokes public/anon and grants authenticated for both RPCs', () {
      expect(
        sql,
        contains(
          'revoke all on function public.create_listing_v2(\n'
          '    text, text, text, integer, numeric, integer,\n'
          '    text, text, text, text, text, boolean,\n'
          '    text, text, text[], text[], text\n'
          ') from public',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function public.update_listing_details_v2(\n'
          '    uuid, text, text, text, integer, numeric, text, integer,\n'
          '    text, text, text, text, text, boolean, text\n'
          ') to authenticated',
        ),
      );
    });
  });
}
