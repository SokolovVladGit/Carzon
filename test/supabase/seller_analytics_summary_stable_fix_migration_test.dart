import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;
  late String lower;

  setUpAll(() {
    final file = File(
      'supabase/migrations/20260914160658_seller_analytics_summary_stable_fix.sql',
    );
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
    lower = sql.toLowerCase();
  });

  test(
    'replaces summary RPC as STABLE SECURITY DEFINER with controlled search_path',
    () {
      expect(
        sql,
        contains(
          'create or replace function public.get_my_seller_analytics_summary(',
        ),
      );
      expect(sql, contains('p_period_days integer'));
      expect(lower, contains('language plpgsql\nstable\nsecurity definer'));
      expect(sql, contains('set search_path = public, pg_temp'));
      expect(lower, isNot(contains('language plpgsql\nvolatile')));
    },
  );

  test(
    'STABLE analytics RPC must not call a write-capable seller-profile helper',
    () {
      expect(sql, isNot(contains('perform public.ensure_seller_profile')));
      expect(sql, isNot(contains('ensure_seller_profile(')));
      expect(sql, isNot(contains('ensure_seller_profile')));
    },
  );

  test('body is read-only: no INSERT/UPDATE/DELETE', () {
    expect(lower, isNot(contains('insert into')));
    expect(lower, isNot(contains('update public')));
    expect(lower, isNot(contains('delete from')));
  });

  test(
    'profile lookup is read-only with private/false missing-row defaults',
    () {
      expect(sql, contains('v_type text := \'private\''));
      expect(sql, contains('v_verified boolean := false'));
      expect(
        sql,
        contains(
          'select sp.seller_type, sp.verified_dealer\n'
          '      into v_type, v_verified\n'
          '      from public.seller_profiles sp\n'
          '     where sp.user_id = v_uid;',
        ),
      );
      expect(sql, contains('if not found then'));
      expect(sql, contains("v_type := 'private'"));
      expect(sql, contains('v_verified := false'));
      expect(sql, isNot(contains('raise exception \'seller profile')));
    },
  );

  test('keeps 7/30/90 validation, return contract, and metric SQL', () {
    expect(sql, contains('auth.uid()'));
    expect(sql, contains("errcode = '28000'"));
    expect(sql, contains('p_period_days is distinct from 7'));
    expect(sql, contains('p_period_days is distinct from 30'));
    expect(sql, contains('p_period_days is distinct from 90'));
    expect(sql, contains("errcode = '22023'"));
    expect(sql, contains('seller_type text'));
    expect(sql, contains('verified_dealer boolean'));
    expect(sql, contains('active_count integer'));
    expect(sql, contains('sold_count integer'));
    expect(sql, contains('period_views integer'));
    expect(sql, contains('current_favorites integer'));
    expect(sql, contains('period_inquiries integer'));
    expect(sql, contains('conversion_percent numeric'));
    expect(sql, contains('listing_view_daily'));
    expect(sql, contains("Europe/Chisinau"));
    expect(sql, contains("l.status in ('active', 'sold')"));
    expect(sql, contains("l.status = 'active'"));
    expect(sql, contains('m.sender_id = c.buyer_id'));
    expect(sql, contains('min(m.created_at)'));
    expect(sql, contains("conversation_kind = 'listing'"));
    expect(sql, contains('when coalesce(v_views, 0) = 0 then null::numeric'));
    expect(sql, isNot(contains('get_my_seller_analytics_daily')));
    expect(sql, isNot(contains('get_my_seller_analytics_listings')));
    expect(sql, isNot(contains('get_my_seller_context')));
    expect(sql, isNot(contains('set_my_seller_type')));
    expect(sql, isNot(contains('get_my_seller_listing_demand')));
  });

  test('reasserts authenticated execute and anon/public revoke', () {
    expect(
      sql,
      contains(
        'revoke all on function public.get_my_seller_analytics_summary(integer) from public',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function public.get_my_seller_analytics_summary(integer) from anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.get_my_seller_analytics_summary(integer)',
      ),
    );
    expect(sql, contains('to authenticated'));
  });
}
