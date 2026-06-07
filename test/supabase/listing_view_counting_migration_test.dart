import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  late String sql;

  setUpAll(() {
    final file = File(
      'supabase/migrations/20260701120000_listing_view_counting.sql',
    );
    expect(file.existsSync(), isTrue);
    sql = file.readAsStringSync().toLowerCase();
  });

  test('adds listings.view_count with non-negative constraint', () {
    expect(sql, contains('view_count'));
    expect(sql, contains('listings_view_count_chk'));
    expect(sql, contains('check (view_count >= 0)'));
  });

  test('creates daily and dedupe analytics tables with RLS', () {
    expect(
      sql,
      contains('create table if not exists public.listing_view_daily'),
    );
    expect(
      sql,
      contains('create table if not exists public.listing_view_dedupe'),
    );
    expect(
      sql,
      contains(
        'alter table public.listing_view_daily enable row level security',
      ),
    );
    expect(
      sql,
      contains(
        'alter table public.listing_view_dedupe enable row level security',
      ),
    );
  });

  test('revokes direct client access to analytics tables', () {
    expect(
      sql,
      contains('revoke all on table public.listing_view_daily from anon'),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.listing_view_daily from authenticated',
      ),
    );
    expect(
      sql,
      contains('revoke all on table public.listing_view_dedupe from anon'),
    );
    expect(
      sql,
      contains(
        'revoke all on table public.listing_view_dedupe from authenticated',
      ),
    );
  });

  test('extends public listings column grant with view_count only', () {
    final grant = _statementStarting(sql, 'grant select (', 'public.listings');
    expect(grant, contains('view_count'));
    expect(grant, isNot(contains('contact_phone')));
    expect(grant, isNot(contains('telegram_username')));
    expect(grant, isNot(contains('whatsapp_enabled')));
  });

  test('defines record_listing_view RPC with Moldova timezone and grants', () {
    expect(sql, contains('function public.record_listing_view'));
    expect(sql, contains("at time zone 'europe/chisinau'"));
    expect(sql, contains('carzon_sha256_hex_utf8'));
    expect(sql, contains('on conflict do nothing'));
    expect(sql, contains("v_listing.status is distinct from 'active'"));
    expect(sql, contains('auth.uid() = v_listing.seller_id'));
    expect(
      sql,
      contains(
        'grant execute on function public.record_listing_view(uuid, text)',
      ),
    );
    expect(sql, contains('to anon, authenticated'));
  });
}

String _statementStarting(String haystack, String start, String until) {
  final i = haystack.indexOf(start);
  expect(i, greaterThanOrEqualTo(0), reason: 'Missing: $start');
  final j = haystack.indexOf(until, i);
  final end = haystack.indexOf(';', j);
  return haystack.substring(i, end > i ? end : haystack.length);
}
