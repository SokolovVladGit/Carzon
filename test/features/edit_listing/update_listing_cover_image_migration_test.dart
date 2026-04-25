import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Migration inspection test for `update_listing_cover_image`.
///
/// There is no SQL execution harness in the repo, so these checks are
/// deliberately textual: they guard the security-critical properties
/// of the RPC (SECURITY DEFINER, pinned search_path, atomic ownership
/// check, grants limited to `authenticated`, no direct UPDATE policy
/// on `public.listings`) by inspecting the migration file as text.
void main() {
  group('20260425150000_update_listing_cover_image_rpc.sql', () {
    late String sql;

    setUpAll(() {
      final file = File(
        'supabase/migrations/20260425150000_update_listing_cover_image_rpc.sql',
      );
      expect(
        file.existsSync(),
        isTrue,
        reason: 'migration file must exist at the expected path',
      );
      sql = file.readAsStringSync();
    });

    test('defines the expected RPC signature', () {
      expect(
        sql,
        contains('create or replace function public.update_listing_cover_image('),
      );
      expect(sql, contains('p_listing_id       uuid'));
      expect(sql, contains('p_cover_image_url  text'));
      expect(sql, contains('returns public.listings'));
    });

    test('is SECURITY DEFINER with a pinned search_path', () {
      expect(sql.toLowerCase(), contains('security definer'));
      expect(
        sql.toLowerCase(),
        contains('set search_path = public, pg_temp'),
      );
    });

    test('requires authentication before doing any work', () {
      expect(sql, contains('auth.uid() is null'));
      expect(sql, contains("raise exception 'not authenticated'"));
    });

    test('accepts NULL to remove the cover image', () {
      expect(sql, contains('if p_cover_image_url is null then'));
      expect(sql, contains('v_url := null;'));
    });

    test('rejects blank strings and non-http(s) URLs', () {
      expect(
        sql,
        contains("raise exception 'cover_image_url cannot be blank'"),
      );
      expect(sql, contains("raise exception 'invalid cover_image_url'"));
      expect(sql, contains(r"v_url !~* '^https?://'"));
    });

    test('atomically enforces ownership inside the UPDATE', () {
      expect(sql, contains('update public.listings'));
      expect(sql, contains('set cover_image_url = v_url'));
      expect(sql, contains('where id = p_listing_id'));
      expect(sql, contains('and seller_id = auth.uid()'));
    });

    test('updates only cover_image_url', () {
      final updateClause = RegExp(
        r'update public\.listings\s+set cover_image_url = v_url\s+where',
        caseSensitive: false,
      );
      expect(
        updateClause.hasMatch(sql),
        isTrue,
        reason: 'only cover_image_url should be in the SET clause',
      );
      // Sanity-check a handful of columns owned by the other RPCs — if
      // this ever changes, reviewers must reconsider the RLS posture.
      expect(sql, isNot(contains('set title')));
      expect(sql, isNot(contains('set status')));
      expect(sql, isNot(contains('set seller_id')));
      expect(sql, isNot(contains('set contact_phone')));
    });

    test('raises a generic error when no row matches', () {
      expect(
        sql,
        contains("raise exception 'listing not found or not owned by caller'"),
      );
    });

    test('revokes execute from public/anon and grants only to authenticated',
        () {
      expect(
        sql,
        contains('revoke all on function public.update_listing_cover_image(uuid, text) from public'),
      );
      expect(
        sql,
        contains('revoke all on function public.update_listing_cover_image(uuid, text) from anon'),
      );
      expect(
        sql,
        contains('grant execute on function public.update_listing_cover_image(uuid, text) to authenticated'),
      );
    });

    test('does NOT add any direct UPDATE policy to public.listings', () {
      // Very conservative: no `create policy` of any kind may appear
      // in this migration — all writes go through the SECURITY DEFINER
      // RPCs instead.
      expect(sql.toLowerCase(), isNot(contains('create policy')));
      expect(sql.toLowerCase(), isNot(contains('for update')));
    });
  });
}
