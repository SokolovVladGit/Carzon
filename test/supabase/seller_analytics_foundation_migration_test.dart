import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final file = File(
      'supabase/migrations/20260913190000_seller_analytics_foundation.sql',
    );
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync();
  });

  test('adds sold_at with status-safe check and no backfill', () {
    expect(sql, contains('add column if not exists sold_at timestamptz'));
    expect(sql, contains('listings_sold_at_status_chk'));
    expect(sql, contains('sold_at is null or status = \'sold\''));
    expect(sql.toLowerCase(), isNot(contains('set sold_at = updated_at')));
    expect(sql.toLowerCase(), isNot(contains('updated_at as')));
  });

  test('set_listing_status encodes sold lifecycle without new RPC', () {
    expect(
      sql,
      contains('create or replace function public.set_listing_status'),
    );
    expect(
      sql,
      contains('when p_status = \'sold\' and status is distinct from \'sold\''),
    );
    expect(sql, contains('then now()'));
    expect(
      sql,
      contains('when p_status is distinct from \'sold\' and status = \'sold\''),
    );
    expect(sql, contains('then null'));
    expect(sql, contains('else sold_at'));
    expect(sql, contains('seller_id = auth.uid()'));
  });

  test('seller context and mode RPCs do not write verified_dealer', () {
    expect(sql, contains('function public.get_my_seller_context()'));
    expect(
      sql,
      contains('function public.set_my_seller_type(p_seller_type text)'),
    );
    expect(sql, contains('ensure_seller_profile'));
    final setFn = sql.substring(sql.indexOf('set_my_seller_type'));
    expect(setFn, contains('set seller_type = v_type'));
    expect(setFn, isNot(contains('set verified_dealer')));
    expect(sql, contains('get_my_seller_profile() return shape'));
  });

  test('analytics RPCs are authenticated, uid-only, and Option B', () {
    expect(sql, contains('get_my_seller_analytics_summary'));
    expect(sql, contains('get_my_seller_analytics_daily'));
    expect(sql, contains('get_my_seller_analytics_listings'));
    expect(sql, contains('listing_view_daily'));
    expect(sql, contains('generate_series'));
    expect(sql, contains('Europe/Chisinau'));
    expect(sql, contains('invalid analytics period'));
    expect(sql.toLowerCase(), isNot(contains('create table')));
  });

  test('inquiry uses first buyer message, not conversation creation', () {
    expect(sql, contains('m.sender_id = c.buyer_id'));
    expect(sql, contains('min(m.created_at)'));
    expect(sql, contains("conversation_kind = 'listing'"));
  });

  test('conversion is null when views are zero', () {
    expect(sql, contains('when coalesce(v_views, 0) = 0 then null::numeric'));
  });

  test('listing order is documented: active, engagement, created_at, id', () {
    expect(sql, contains('case when e.status = \'active\' then 0 else 1 end'));
    expect(sql, contains('coalesce(v.period_views, 0) desc'));
    expect(sql, contains('coalesce(i.period_inquiries, 0) desc'));
    expect(sql, contains('coalesce(f.current_favorites, 0) desc'));
    expect(sql, contains('e.created_at desc'));
    expect(sql, contains('e.id'));
  });

  test('grants authenticated execute and keeps analytics tables revoked', () {
    expect(
      sql,
      contains(
        'grant execute on function public.get_my_seller_analytics_summary(integer)',
      ),
    );
    expect(sql, contains('to authenticated'));
    expect(
      sql,
      contains(
        'revoke all on function public.get_my_seller_analytics_summary(integer) from anon',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.listing_view_daily from authenticated',
      ),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.listing_view_dedupe from authenticated',
      ),
    );
  });

  test('public listings grant includes sold_at and omits contact fields', () {
    final grant = sql.substring(sql.indexOf('grant select ('));
    final end = grant.indexOf(';');
    final stmt = grant.substring(0, end);
    expect(stmt, contains('sold_at'));
    expect(stmt, contains('view_count'));
    expect(stmt, isNot(contains('contact_phone')));
    expect(stmt, isNot(contains('telegram_username')));
  });

  test('does not add speculative indexes', () {
    expect(sql.toLowerCase(), isNot(contains('create index')));
  });
}
