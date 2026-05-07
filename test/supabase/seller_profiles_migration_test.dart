import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260515120000_seller_profiles_foundation.sql` — structural audit only
/// (no live Postgres), consistent with other Carzon migration tests.
void main() {
  group('20260515120000_seller_profiles_foundation.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260515120000_seller_profiles_foundation.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'seller_profiles migration must exist',
      );
      sql = f.readAsStringSync();
    });

    test('creates seller_profiles with core and trust columns', () {
      expect(
        sql.toLowerCase(),
        contains('create table if not exists public.seller_profiles'),
      );
      expect(sql, contains('user_id'));
      expect(sql, contains('display_name'));
      expect(sql, contains('avatar_url'));
      expect(sql, contains('avatar_path'));
      expect(sql, contains('member_since'));
      expect(sql, contains('seller_type'));
      expect(sql, contains('public_visibility'));
      expect(sql, contains('moderation_status'));
      expect(sql, contains('rating_average'));
      expect(sql, contains('rating_count'));
      expect(sql, contains('review_count'));
      expect(sql, contains('verified_phone'));
      expect(sql, contains('verified_email'));
      expect(sql, contains('verified_dealer'));
      expect(sql, contains('created_at'));
      expect(sql, contains('updated_at'));
    });

    test('enforces seller_type, moderation, rating, non-negative counts', () {
      expect(sql.toLowerCase(), contains('seller_profiles_seller_type_chk'));
      expect(sql, contains("'private'"));
      expect(sql, contains("'dealer'"));
      expect(
        sql.toLowerCase(),
        contains('seller_profiles_moderation_status_chk'),
      );
      expect(sql, contains("'hidden'"));
      expect(sql, contains("'suspended'"));
      expect(sql.toLowerCase(), contains('seller_profiles_rating_average_chk'));
      expect(sql.toLowerCase(), contains('rating_average is null'));
      expect(sql.toLowerCase(), contains('seller_profiles_rating_count_chk'));
      expect(sql.toLowerCase(), contains('seller_profiles_review_count_chk'));
    });

    test('enforces length limits on display_name and avatar fields', () {
      expect(
        sql.toLowerCase(),
        contains('seller_profiles_display_name_len_chk'),
      );
      expect(sql.toLowerCase(), contains('seller_profiles_avatar_url_len_chk'));
      expect(
        sql.toLowerCase(),
        contains('seller_profiles_avatar_path_len_chk'),
      );
      expect(sql, contains('<= 200'));
      expect(sql, contains('<= 2048'));
      expect(sql, contains('<= 1024'));
    });

    test('adds seller-avatars bucket and owner-scoped storage policies', () {
      expect(sql, contains("'seller-avatars'"));
      expect(sql.toLowerCase(), contains('seller_avatars_public_read'));
      expect(sql.toLowerCase(), contains('seller_avatars_owner_insert'));
      expect(sql.toLowerCase(), contains('seller_avatars_owner_update'));
      expect(sql.toLowerCase(), contains('seller_avatars_owner_delete'));
      expect(sql, contains("split_part(name, '/', 1) = 'avatars'"));
      expect(sql, contains("split_part(name, '/', 2) = auth.uid()::text"));
    });

    test('enables RLS and owner-only select on seller_profiles', () {
      expect(
        sql.toLowerCase(),
        contains(
          'alter table public.seller_profiles enable row level security',
        ),
      );
      expect(sql.toLowerCase(), contains('seller_profiles_select_own'));
      expect(sql.toLowerCase(), contains('user_id = auth.uid()'));
    });

    test('defines get_seller_public_profile RPC with safe return shape', () {
      expect(
        sql.toLowerCase(),
        contains('create or replace function public.get_seller_public_profile'),
      );
      expect(sql.toLowerCase(), contains('returns table'));
      expect(sql, contains('active_listings_count'));
      expect(sql.toLowerCase(), contains('public_visibility'));
      expect(sql.toLowerCase(), contains('moderation_status'));
      expect(sql.toLowerCase(), contains("sp.moderation_status = 'active'"));
      expect(sql.toLowerCase(), contains("li.status = 'active'"));
      expect(
        sql.toLowerCase(),
        contains(
          'grant execute on function public.get_seller_public_profile(uuid)',
        ),
      );
      expect(sql.toLowerCase(), contains('to anon'));
      expect(sql.toLowerCase(), contains('to authenticated'));
    });

    test('does not read auth.users.email for profile fields', () {
      final lower = sql.toLowerCase();
      expect(lower.contains("raw_user_meta_data->>'email'"), isFalse);
      expect(lower.contains(' u.email'), isFalse);
      expect(lower.contains('users.email'), isFalse);
    });

    test('defines ensure_seller_profile and listings insert trigger', () {
      expect(
        sql.toLowerCase(),
        contains('create or replace function public.ensure_seller_profile'),
      );
      expect(sql.toLowerCase(), contains('from auth.users'));
      expect(sql.toLowerCase(), contains('full_name'));
      expect(sql.toLowerCase(), contains('avatar_url'));
      expect(
        sql.toLowerCase(),
        contains('listings_after_insert_ensure_seller_profile'),
      );
      expect(sql.toLowerCase(), contains('after insert on public.listings'));
    });

    test('adds listings seller_id indexes', () {
      expect(sql.toLowerCase(), contains('listings_seller_id_idx'));
      expect(sql.toLowerCase(), contains('listings_active_seller_id_idx'));
      expect(sql.toLowerCase(), contains("where status = 'active'"));
    });

    test('backfill joins listings to auth.users without email', () {
      expect(sql.toLowerCase(), contains('insert into public.seller_profiles'));
      expect(sql.toLowerCase(), contains('join auth.users u'));
      expect(sql.toLowerCase(), contains('on conflict (user_id) do nothing'));
    });

    test('revokes client access to ensure_seller_profile', () {
      expect(
        sql.toLowerCase(),
        contains(
          'revoke all on function public.ensure_seller_profile(uuid) from authenticated',
        ),
      );
    });
  });
}
