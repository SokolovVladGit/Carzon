import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Textual inspection for `20260506140000_update_listing_details_v2_rpc.sql`.
///
/// Mirrors `update_listing_cover_image_migration_test.dart` — guards RPC
/// contracts without executing SQL against a live Postgres.
void main() {
  group('20260506140000_update_listing_details_v2_rpc.sql', () {
    late String sql;
    late File migrationFile;

    setUpAll(() {
      migrationFile = File(
        'supabase/migrations/20260506140000_update_listing_details_v2_rpc.sql',
      );
      expect(
        migrationFile.existsSync(),
        isTrue,
        reason: 'migration file must exist at the expected path',
      );
      sql = migrationFile.readAsStringSync();
    });

    test(
      'defines update_listing_details_v2 with p_price_currency in signature',
      () {
        expect(
          sql.toLowerCase(),
          contains(
            'create or replace function public.update_listing_details_v2(',
          ),
        );
        expect(sql, contains('p_price_currency'));
        expect(sql, contains('p_price_currency    text'));
        expect(sql.toLowerCase(), contains('returns public.listings'));
      },
    );

    test('is SECURITY DEFINER with pinned search_path', () {
      expect(sql.toLowerCase(), contains('security definer'));
      expect(sql.toLowerCase(), contains('set search_path = public, pg_temp'));
    });

    test(
      'validates currency eur/usd consistently with create_listing_v2 style',
      () {
        expect(sql, contains('raise exception \'invalid price_currency\''));
        expect(sql.toLowerCase(), contains("v_currency not in ('eur', 'usd')"));
      },
    );

    test('UPDATE assigns price_currency from normalized currency', () {
      expect(sql.toLowerCase(), contains('price_currency    = v_currency'));
    });

    test('ownership enforced with auth.uid inside UPDATE WHERE clause', () {
      expect(sql.toLowerCase(), contains('auth.uid() is null'));
      expect(
        sql.toLowerCase(),
        contains("raise exception 'not authenticated'"),
      );
      expect(sql.toLowerCase(), contains('where id = p_listing_id'));
      expect(sql.toLowerCase(), contains('and seller_id = auth.uid()'));
      expect(
        sql.toLowerCase(),
        contains("'listing not found or not owned by caller'"),
      );
    });

    test('UPDATE set clause never assigns seller_id or cover_image_url', () {
      final match = RegExp(
        r'set\s(?<body>[\s\S]+?)\s+where\s',
        caseSensitive: false,
      ).firstMatch(sql);
      expect(
        match,
        isNotNull,
        reason: 'expected UPDATE ... SET ... WHERE block',
      );
      final setBody = match!.namedGroup('body')!;
      expect(setBody.toLowerCase(), isNot(contains('seller_id')));
      expect(setBody.toLowerCase(), isNot(contains('cover_image_url')));
      expect(setBody.toLowerCase(), contains('telegram_username'));
    });

    test(
      'does not mutate listing_images (no INSERT/DELETE into child table)',
      () {
        expect(
          sql.toLowerCase(),
          isNot(contains('insert into public.listing_images')),
        );
        expect(
          sql.toLowerCase(),
          isNot(contains('delete from public.listing_images')),
        );
      },
    );

    test('does not add CREATE POLICY on listings or listing_images', () {
      expect(sql.toLowerCase(), isNot(contains('create policy')));
    });

    test(
      'revokes execute from public/anon and grants only to authenticated',
      () {
        expect(
          sql,
          contains(
            'revoke all on function public.update_listing_details_v2(\n'
            '    uuid, text, text, text, integer, numeric, text, integer,\n'
            '    text, text, text, text, text, boolean\n'
            ') from public',
          ),
        );
        expect(
          sql,
          contains(
            'revoke all on function public.update_listing_details_v2(\n'
            '    uuid, text, text, text, integer, numeric, text, integer,\n'
            '    text, text, text, text, text, boolean\n'
            ') from anon',
          ),
        );
        expect(
          sql,
          contains(
            'grant execute on function public.update_listing_details_v2(\n'
            '    uuid, text, text, text, integer, numeric, text, integer,\n'
            '    text, text, text, text, text, boolean\n'
            ') to authenticated',
          ),
        );
      },
    );
  });

  group('legacy update_listing_details migration still present', () {
    test('migration file unchanged for original RPC signature', () {
      final file = File(
        'supabase/migrations/20260425130000_update_listing_details_rpc.sql',
      );
      expect(file.existsSync(), isTrue);
      final legacySql = file.readAsStringSync();
      expect(
        legacySql.toLowerCase(),
        contains('create or replace function public.update_listing_details('),
      );
      expect(legacySql, isNot(contains('update_listing_details_v2')));
    });
  });
}
