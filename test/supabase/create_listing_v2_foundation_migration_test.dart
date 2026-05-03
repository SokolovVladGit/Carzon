import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Textual inspection for `20260504180000_create_listing_v2_foundation.sql`.
///
/// No SQL execution harness — guards schema/RLS/RPC contracts the same way as
/// `update_listing_cover_image_migration_test.dart`.
void main() {
  late String sql;
  late File foundationFile;
  late File legacyCreateFile;

  setUpAll(() {
    foundationFile = File(
      'supabase/migrations/20260504180000_create_listing_v2_foundation.sql',
    );
    legacyCreateFile = File(
      'supabase/migrations/20260503120000_create_listing_rpc.sql',
    );
    expect(
      foundationFile.existsSync(),
      isTrue,
      reason: 'v2 foundation migration must exist',
    );
    expect(
      legacyCreateFile.existsSync(),
      isTrue,
      reason: 'legacy create_listing migration must remain in tree',
    );
    sql = foundationFile.readAsStringSync();
  });

  group('20260504180000_create_listing_v2_foundation.sql', () {
    test('adds listings.price_currency with check constraint', () {
      expect(sql.toLowerCase(), contains('alter table public.listings'));
      expect(sql, contains('price_currency'));
      expect(sql.toLowerCase(), contains('default \'eur\''));
      expect(sql.toLowerCase(), contains('check (price_currency'));
      expect(sql.toLowerCase(), contains('listing_images'));
    });

    test('defines listing_images with position guard and uniqueness', () {
      expect(
        sql.toLowerCase(),
        contains('create table if not exists public.listing_images'),
      );
      expect(sql.toLowerCase(), contains('position between 0 and 8'));
      expect(sql.toLowerCase(), contains('unique (listing_id, position)'));
      expect(sql.toLowerCase(), contains('public_url ~* \'^https?://'));
    });

    test(
      'creates exactly two SELECT policies on listing_images (no write policies)',
      () {
        expect(
          sql.toLowerCase(),
          contains(
            'alter table public.listing_images enable row level security',
          ),
        );
        expect(
          sql.toLowerCase(),
          contains('"listing_images_public_read_active_catalog"'),
        );
        expect(sql.toLowerCase(), contains('"listing_images_owner_read_own"'));
        expect(sql.toLowerCase(), contains('for select'));
        final createPolicyLines = RegExp(
          r'^\s*create policy ',
          multiLine: true,
          caseSensitive: false,
        ).allMatches(sql);
        expect(
          createPolicyLines.length,
          2,
          reason: 'exactly catalog + owner read policies',
        );
      },
    );

    test(
      'defines create_listing_v2 as SECURITY DEFINER with pinned search_path',
      () {
        expect(
          sql.toLowerCase(),
          contains('create or replace function public.create_listing_v2('),
        );
        expect(sql.toLowerCase(), contains('security definer'));
        expect(
          sql.toLowerCase(),
          contains('set search_path = public, pg_temp'),
        );
      },
    );

    test('create_listing_v2 enforces auth, currency, and max 9 images', () {
      expect(sql, contains('auth.uid() is null'));
      expect(sql, contains("raise exception 'not authenticated'"));
      expect(sql, contains("raise exception 'invalid price_currency'"));
      expect(sql, contains("raise exception 'too many images'"));
      expect(sql, contains("raise exception 'invalid image url'"));
    });

    test(
      'create_listing_v2 revokes public/anon and grants authenticated only',
      () {
        expect(
          sql,
          contains('revoke all on function public.create_listing_v2('),
        );
        expect(
          sql,
          contains('grant execute on function public.create_listing_v2('),
        );
        expect(sql, contains('to authenticated'));
      },
    );

    test('defines replace_listing_images with ownership guard', () {
      expect(
        sql.toLowerCase(),
        contains('create or replace function public.replace_listing_images('),
      );
      expect(
        sql,
        contains("raise exception 'listing not found or not owned by caller'"),
      );
    });

    test('replace_listing_images revokes public/anon and grants authenticated', () {
      expect(
        sql,
        contains(
          'revoke all on function public.replace_listing_images(uuid, text[], text[]) from public',
        ),
      );
      expect(
        sql,
        contains(
          'grant execute on function public.replace_listing_images(uuid, text[], text[]) to authenticated',
        ),
      );
    });

    test(
      'does not add broad INSERT/UPDATE/DELETE policies on listing_images',
      () {
        // Two SELECT policies only.
        final lower = sql.toLowerCase();
        expect(
          lower,
          isNot(contains('on public.listing_images\n    for insert')),
        );
        expect(
          lower,
          isNot(contains('on public.listing_images\n    for update')),
        );
        expect(
          lower,
          isNot(contains('on public.listing_images\n    for delete')),
        );
      },
    );
  });

  group('legacy create_listing migration still present', () {
    test(
      '20260503120000_create_listing_rpc.sql still defines create_listing',
      () {
        final legacySql = legacyCreateFile.readAsStringSync().toLowerCase();
        expect(
          legacySql,
          contains('create or replace function public.create_listing('),
        );
      },
    );
  });
}
