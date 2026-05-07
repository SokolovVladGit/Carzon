import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Structural audit for `20260517120000_seller_avatar_self_edit.sql`.
void main() {
  group('20260517120000_seller_avatar_self_edit.sql', () {
    late String sql;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260517120000_seller_avatar_self_edit.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
    });

    test('drops get_my_seller_profile before recreating with avatar_path', () {
      final lower = sql.toLowerCase();
      final dropIdx = lower.indexOf(
        'drop function if exists public.get_my_seller_profile()',
      );
      final createIdx = lower.indexOf(
        'create or replace function public.get_my_seller_profile',
      );
      expect(dropIdx, greaterThan(-1));
      expect(createIdx, greaterThan(-1));
      expect(dropIdx, lessThan(createIdx));
    });

    test('drops functions whose return row shape changes before recreate', () {
      final lower = sql.toLowerCase();
      expect(
        lower.contains(
          'drop function if exists public.get_my_seller_profile()',
        ),
        isTrue,
      );
      expect(
        lower.contains(
          'drop function if exists public.update_my_seller_display_name(text)',
        ),
        isTrue,
      );
      expect(
        lower.contains(
          'drop function if exists public.update_my_seller_avatar(text, text)',
        ),
        isTrue,
      );
      expect(
        lower.contains(
          'drop function if exists public.clear_my_seller_avatar()',
        ),
        isTrue,
      );
      final dropFunctionLines = sql
          .split('\n')
          .map((l) => l.toLowerCase().trimLeft())
          .where((l) => l.startsWith('drop function'));
      expect(dropFunctionLines.any((l) => l.contains('cascade')), isFalse);
    });

    test('get_my_seller_profile returns avatar_path', () {
      expect(
        sql.toLowerCase(),
        contains('create or replace function public.get_my_seller_profile'),
      );
      expect(sql, contains('avatar_path'));
      expect(sql.toLowerCase(), contains('sp.avatar_path'));
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

    test('update_my_seller_display_name return includes avatar_path', () {
      expect(sql.toLowerCase(), contains('update_my_seller_display_name'));
      expect(sql, contains('avatar_path'));
    });

    test(
      'update_my_seller_avatar authenticated only with path ownership checks',
      () {
        final lower = sql.toLowerCase();
        expect(
          lower.contains(
            'create or replace function public.update_my_seller_avatar',
          ),
          isTrue,
        );
        expect(lower.contains('p_avatar_path'), isTrue);
        expect(lower.contains('p_avatar_url'), isTrue);
        expect(lower.contains('auth.uid()'), isTrue);
        expect(lower.contains('avatars/'), isTrue);
        expect(lower.contains("'..'"), isTrue);
        expect(lower.contains('set avatar_path'), isTrue);
        expect(lower.contains('avatar_url = v_url'), isTrue);
        expect(
          lower.contains(
            'grant execute on function public.update_my_seller_avatar(text, text) to authenticated',
          ),
          isTrue,
        );
        expect(
          lower.contains(
            'revoke all on function public.update_my_seller_avatar(text, text) from anon',
          ),
          isTrue,
        );
        expect(lower.contains('p_user_id'), isFalse);
        expect(lower.contains('p_seller_id'), isFalse);
      },
    );

    test(
      'clear_my_seller_avatar authenticated only clears avatar columns only',
      () {
        final lower = sql.toLowerCase();
        expect(
          lower.contains(
            'create or replace function public.clear_my_seller_avatar',
          ),
          isTrue,
        );
        expect(lower.contains('set avatar_path = null'), isTrue);
        expect(lower.contains('avatar_url = null'), isTrue);
        expect(
          lower.contains(
            'grant execute on function public.clear_my_seller_avatar() to authenticated',
          ),
          isTrue,
        );
        expect(
          lower.contains(
            'revoke all on function public.clear_my_seller_avatar() from anon',
          ),
          isTrue,
        );
      },
    );

    test('clear_my_seller_avatar nulls avatar columns', () {
      expect(sql.toLowerCase(), contains('set avatar_path = null'));
      expect(sql.toLowerCase(), contains('avatar_url = null'));
    });

    test('update_my_seller_avatar sets avatar_path and avatar_url only', () {
      expect(sql, contains('avatar_path = v_path'));
      expect(sql, contains('avatar_url = v_url'));
    });

    test('does not expose auth.users email reads', () {
      final lower = sql.toLowerCase();
      expect(lower.contains('users.email'), isFalse);
      expect(lower.contains('from auth.users'), isFalse);
    });
  });
}
