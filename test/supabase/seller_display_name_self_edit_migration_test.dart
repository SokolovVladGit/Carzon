import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260516120000_seller_display_name_self_edit.sql`.
void main() {
  group('20260516120000_seller_display_name_self_edit.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260516120000_seller_display_name_self_edit.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('defines get_my_seller_profile for authenticated only', () {
      expect(
        sql.toLowerCase(),
        contains('create or replace function public.get_my_seller_profile'),
      );
      expect(sql, contains('auth.uid()'));
      expect(sql.toLowerCase(), contains('ensure_seller_profile'));
      expect(sql, contains('display_name'));
      expect(sql, contains('avatar_url'));
      expect(sql, contains('member_since'));
      expect(sql, contains('public_visibility'));
      expect(
        sql.toLowerCase(),
        contains(
          'grant execute on function public.get_my_seller_profile() to authenticated',
        ),
      );
      expect(
        sql.toLowerCase(),
        contains(
          'revoke all on function public.get_my_seller_profile() from anon',
        ),
      );
    });

    test(
      'defines update_my_seller_display_name with length limit and trim semantics',
      () {
        expect(
          sql.toLowerCase(),
          contains(
            'create or replace function public.update_my_seller_display_name',
          ),
        );
        expect(sql.toLowerCase(), contains('btrim'));
        expect(sql.toLowerCase(), contains('nullif'));
        expect(sql, contains('> 80'));
        expect(sql.toLowerCase(), contains('seller_display_name_too_long'));
        expect(sql.toLowerCase(), contains('set display_name = v_clean'));
        expect(
          sql.toLowerCase(),
          contains(
            'grant execute on function public.update_my_seller_display_name(text) to authenticated',
          ),
        );
        expect(
          sql.toLowerCase(),
          contains(
            'revoke all on function public.update_my_seller_display_name(text) from anon',
          ),
        );
      },
    );

    test('does not mention rating review verification moderation updates', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('rating_average'), isFalse);
      expect(lower.contains('review_count'), isFalse);
      expect(lower.contains('verified_phone'), isFalse);
      expect(lower.contains('moderation_status'), isFalse);
      expect(lower.contains('seller_type'), isFalse);
    });

    test('does not accept client user id parameter', () {
      expect(sql.toLowerCase(), contains('p_display_name'));
      expect(sql.toLowerCase(), isNot(contains('p_user_id')));
      expect(sql.toLowerCase(), isNot(contains('p_seller_id')));
    });

    test('does not source display_name from auth email columns', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('users.email'), isFalse);
      expect(lower.contains('from auth.users'), isFalse);
      expect(lower.contains('raw_user_meta_data'), isFalse);
    });
  });
}
