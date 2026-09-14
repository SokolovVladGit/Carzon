import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final file = File(
      'supabase/migrations/20260914153331_seller_listing_demand.sql',
    );
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
  });

  test('defines both dealer-only live matching RPCs', () {
    expect(sql, contains('get_my_seller_listing_demand'));
    expect(sql, contains('get_my_seller_inventory_demand'));
    expect(sql, contains('listing_matches_saved_discovery_criteria'));
    expect(sql, contains("v_type is distinct from 'dealer'"));
    expect(sql, contains("l.status = 'active'"));
    expect(sql, contains('ss.user_id is distinct from v_uid'));
    expect(sql, contains('auth.uid()'));
    expect(sql, contains("errcode = '28000'"));
    expect(sql, contains("errcode = '42501'"));
    expect(sql, contains('between 1 and 4'));
    expect(sql, isNot(contains('p_seller_id')));
    expect(sql, isNot(contains('alerts_enabled')));
    expect(sql, isNot(contains('p_period_days')));
    expect(sql.toLowerCase(), isNot(contains('create table')));
    expect(sql.toLowerCase(), isNot(contains('create index')));
    expect(sql.toLowerCase(), isNot(contains('materialized')));
    expect(
      sql,
      isNot(
        contains(
          'create or replace function public.listing_matches_saved_discovery_criteria',
        ),
      ),
    );
  });

  test('counts distinct users not saved-search rows', () {
    expect(sql, contains('count(u.user_id)'));
    expect(sql, contains('group by ss.user_id'));
    expect(sql, contains('select distinct ss.user_id'));
    expect(sql, isNot(contains('count(ss.id)')));
    expect(sql, isNot(contains('count(*) from public.saved_searches')));
  });

  test('grants authenticated execute and revokes anon/public', () {
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
    expect(sql, contains('security definer'));
    expect(sql, contains("search_path = public, pg_temp"));
  });

  test('orders per-listing rows by listing_id', () {
    expect(sql, contains('order by x.listing_id'));
  });
}
