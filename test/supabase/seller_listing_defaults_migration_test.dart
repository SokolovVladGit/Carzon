import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260907120000_seller_listing_defaults.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260907120000_seller_listing_defaults.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('creates private seller_listing_defaults table', () {
      expect(
        lower,
        contains('create table if not exists public.seller_listing_defaults'),
      );
      expect(lower, contains('user_id uuid primary key'));
      expect(lower, contains('contact_phone text'));
      expect(lower, contains('telegram_username text'));
      expect(
        lower,
        contains('whatsapp_enabled boolean not null default false'),
      );
      expect(lower, contains('market_region text'));
      expect(lower, contains('city text'));
    });

    test('enables RLS', () {
      expect(
        lower,
        contains(
          'alter table public.seller_listing_defaults enable row level security',
        ),
      );
    });

    test('revokes direct anon/authenticated/public table privileges', () {
      expect(
        lower,
        contains(
          'revoke all on table public.seller_listing_defaults from public',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on table public.seller_listing_defaults from anon',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on table public.seller_listing_defaults from authenticated',
        ),
      );
    });

    test('user_id FK references auth.users on delete cascade', () {
      expect(lower, contains('references auth.users (id) on delete cascade'));
    });

    test('defines get_my_listing_defaults', () {
      expect(
        lower,
        contains('create or replace function public.get_my_listing_defaults()'),
      );
    });

    test('defines upsert_my_listing_defaults', () {
      expect(
        lower,
        contains(
          'create or replace function public.upsert_my_listing_defaults(',
        ),
      );
      expect(lower, contains('p_contact_phone text'));
      expect(lower, contains('p_telegram_username text'));
      expect(lower, contains('p_whatsapp_enabled boolean'));
      expect(lower, contains('p_market_region text'));
      expect(lower, contains('p_city text'));
    });

    test('both RPCs require auth.uid()', () {
      expect(sql, contains('auth.uid()'));
      expect(lower, contains("raise exception 'not authenticated'"));
      final getIdx = lower.indexOf(
        'create or replace function public.get_my_listing_defaults()',
      );
      final upsertIdx = lower.indexOf(
        'create or replace function public.upsert_my_listing_defaults(',
      );
      expect(getIdx, greaterThanOrEqualTo(0));
      expect(upsertIdx, greaterThan(getIdx));
      expect(lower.substring(getIdx, upsertIdx), contains('auth.uid()'));
      expect(lower.substring(upsertIdx), contains('auth.uid()'));
    });

    test('RPC caller cannot choose arbitrary user_id', () {
      expect(lower, isNot(contains('p_user_id')));
      expect(lower, isNot(contains('p_seller_id')));
    });

    test('phone validation matches current listing rule', () {
      expect(lower, contains("regexp_replace(v_phone, '[^0-9]', '', 'g')"));
      expect(lower, contains('< 7'));
      expect(lower, contains("raise exception 'invalid contact_phone'"));
    });

    test('telegram validation matches current listing rule', () {
      expect(lower, contains("left(v_telegram, 1) = '@'"));
      expect(lower, contains("v_telegram !~ '^[a-za-z0-9_]{5,32}\$'"));
      expect(lower, contains("raise exception 'invalid telegram_username'"));
    });

    test('market_region validation', () {
      expect(lower, contains("v_region not in ('transnistria', 'moldova')"));
      expect(lower, contains("raise exception 'invalid market_region'"));
    });

    test('city normalization and region requirement', () {
      expect(
        lower,
        contains("v_city := nullif(btrim(coalesce(p_city, '')), '')"),
      );
      expect(lower, contains("raise exception 'city_requires_market_region'"));
      expect(lower, isNot(contains('listingcitiesforregion')));
      expect(lower, isNot(contains('chisinau')));
    });

    test('no public/anon execute; authenticated only', () {
      expect(
        lower,
        contains(
          'revoke all on function public.get_my_listing_defaults() from public',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.get_my_listing_defaults() from anon',
        ),
      );
      expect(
        lower,
        contains(
          'grant execute on function public.get_my_listing_defaults() to authenticated',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.upsert_my_listing_defaults(text, text, boolean, text, text) from public',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.upsert_my_listing_defaults(text, text, boolean, text, text) from anon',
        ),
      );
      expect(
        lower,
        contains(
          'grant execute on function public.upsert_my_listing_defaults(text, text, boolean, text, text) to authenticated',
        ),
      );
    });

    test('safe search_path on SECURITY DEFINER RPCs', () {
      expect(lower, contains('security definer'));
      expect(lower, contains('set search_path = public, pg_temp'));
    });

    test('does not store VIN, email, or provider payload', () {
      expect(RegExp(r'\bvin\b').hasMatch(lower), isFalse);
      expect(RegExp(r'\bemail\b').hasMatch(lower), isFalse);
      expect(lower, isNot(contains('nhtsa')));
      expect(lower, isNot(contains('provider')));
      expect(lower, isNot(contains('jsonb')));
    });

    test('does not alter seller_profiles or listing create RPCs', () {
      expect(lower, isNot(contains('alter table public.seller_profiles')));
      expect(lower, isNot(contains('create_listing_v2')));
      expect(lower, isNot(contains('update_listing_details_v2')));
    });
  });
}
