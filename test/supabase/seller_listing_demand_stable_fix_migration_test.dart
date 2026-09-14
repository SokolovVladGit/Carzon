import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;
  late String lower;

  setUpAll(() {
    final file = File(
      'supabase/migrations/20260914154128_seller_listing_demand_stable_fix.sql',
    );
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
    lower = sql.toLowerCase();
  });

  test('replaces both demand RPCs as STABLE SECURITY DEFINER', () {
    expect(
      sql,
      contains(
        'create or replace function public.get_my_seller_listing_demand()',
      ),
    );
    expect(
      sql,
      contains(
        'create or replace function public.get_my_seller_inventory_demand()',
      ),
    );
    expect(lower, contains('language plpgsql\nstable\nsecurity definer'));
    expect(sql, contains('set search_path = public, pg_temp'));
    expect(lower, isNot(contains('language plpgsql\nvolatile')));
  });

  test('does not call ensure_seller_profile or write seller_profiles', () {
    expect(sql, isNot(contains('perform public.ensure_seller_profile')));
    expect(sql, isNot(contains('ensure_seller_profile(')));
    expect(lower, isNot(contains('insert into')));
    expect(lower, isNot(contains('update public')));
    expect(lower, isNot(contains('delete from')));
  });

  test('keeps auth, dealer gate, k=5, matcher, and output contract', () {
    expect(sql, contains('auth.uid()'));
    expect(sql, contains("errcode = '28000'"));
    expect(sql, contains("v_type is distinct from 'dealer'"));
    expect(sql, contains("errcode = '42501'"));
    expect(sql, contains('listing_matches_saved_discovery_criteria'));
    expect(sql, contains("l.status = 'active'"));
    expect(sql, contains('ss.user_id is distinct from v_uid'));
    expect(sql, contains('between 1 and 4'));
    expect(sql, contains('listing_id uuid'));
    expect(sql, contains('matching_users integer'));
    expect(sql, contains('is_suppressed boolean'));
    expect(sql, isNot(contains('p_seller_id')));
    expect(
      sql,
      isNot(
        contains(
          'create or replace function public.listing_matches_saved_discovery_criteria',
        ),
      ),
    );
  });

  test('reasserts authenticated execute and anon/public revoke', () {
    expect(
      sql,
      contains(
        'revoke all on function public.get_my_seller_listing_demand() from public',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function public.get_my_seller_listing_demand() from anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.get_my_seller_listing_demand()',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function public.get_my_seller_inventory_demand() from public',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on function public.get_my_seller_inventory_demand() from anon',
      ),
    );
    expect(
      sql,
      contains(
        'grant execute on function public.get_my_seller_inventory_demand()',
      ),
    );
    expect(sql, contains('to authenticated'));
  });
}
