import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260822120000_fuel_prices_foundation.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260822120000_fuel_prices_foundation.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'foundation migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('creates cache and job tables', () {
      expect(lower, contains('fuel_price_source_cache'));
      expect(lower, contains('fuel_price_fetch_jobs'));
    });

    test('enables RLS and revokes direct anon/authenticated table access', () {
      expect(lower, contains('enable row level security'));
      expect(lower, contains('revoke all on table public.fuel_price_source_cache'));
      expect(lower, contains('revoke all on table public.fuel_price_fetch_jobs'));
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
    });

    test('public RPC exists and is granted to anon/authenticated', () {
      expect(lower, contains('get_fuel_prices_for_app'));
      expect(
        lower,
        contains('grant execute on function public.get_fuel_prices_for_app()'),
      );
      expect(lower, contains('to anon, authenticated'));
    });

    test('worker RPCs granted to service_role only', () {
      expect(lower, contains('claim_fuel_price_fetch_jobs_for_processing'));
      expect(lower, contains('complete_fuel_price_fetch_job_success'));
      expect(lower, contains('complete_fuel_price_fetch_job_failure'));
      expect(lower, contains('enqueue_all_fuel_price_fetch_jobs'));
      expect(lower, contains('to service_role'));
    });

    test('buyer RPC does not expose source_metadata or cache_key', () {
      final start = lower.indexOf(
        'create or replace function public.get_fuel_prices_for_app',
      );
      final end = lower.indexOf(
        'comment on function public.get_fuel_prices_for_app',
      );
      expect(start, greaterThan(-1));
      expect(end, greaterThan(start));
      final buyerBody = lower.substring(start, end);
      expect(buyerBody, isNot(contains('source_metadata')));
      expect(buyerBody, isNot(contains('cache_key')));
    });

    test('seed cache keys for moldova and pmr', () {
      expect(sql, contains("'moldova:anre_plafon'"));
      expect(sql, contains("'pmr:sheriff_retail'"));
    });
  });
}
