import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Model Passport foundation migration.
void main() {
  group('20260706120000_vehicle_model_data_foundation.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260706120000_vehicle_model_data_foundation.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'foundation migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('creates cache and job tables', () {
      expect(lower, contains('vehicle_model_source_cache'));
      expect(lower, contains('vehicle_model_fetch_jobs'));
    });

    test('enables RLS and revokes direct anon/authenticated table access', () {
      expect(lower, contains('enable row level security'));
      expect(lower, contains('revoke all on table public.vehicle_model_source_cache'));
      expect(lower, contains('revoke all on table public.vehicle_model_fetch_jobs'));
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
    });

    test('buyer RPC exists and is granted to anon/authenticated', () {
      expect(lower, contains('get_listing_model_data_for_buyer'));
      expect(
        lower,
        contains(
          'grant execute on function public.get_listing_model_data_for_buyer(uuid)',
        ),
      );
      expect(lower, contains('to anon, authenticated'));
    });

    test('worker RPCs exist and are not granted to anon/authenticated', () {
      expect(lower, contains('enqueue_vehicle_model_fetch_if_needed'));
      expect(lower, contains('claim_vehicle_model_fetch_jobs_for_processing'));
      expect(lower, contains('complete_vehicle_model_fetch_job_success'));
      expect(lower, contains('complete_vehicle_model_fetch_job_failure'));
      expect(lower, contains('to service_role'));
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)\n    to anon',
          ),
        ),
      );
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.claim_vehicle_model_fetch_jobs_for_processing(integer)\n    to authenticated',
          ),
        ),
      );
    });

    test('buyer RPC does not read VIN tables', () {
      final start = lower.indexOf(
        'create or replace function public.get_listing_model_data_for_buyer',
      );
      final end = lower.indexOf(
        'comment on function public.get_listing_model_data_for_buyer',
      );
      final buyerBody = lower.substring(start, end);
      expect(buyerBody, isNot(contains('from public.listing_vehicle_identity')));
      expect(buyerBody, isNot(contains('vin_hash')));
      expect(buyerBody, isNot(contains('vin_normalized')));
      expect(buyerBody, isNot(contains('from public.listing_vin_source_results')));
    });

    test('buyer RPC return projection excludes internal fields', () {
      final start = lower.indexOf(
        'create or replace function public.get_listing_model_data_for_buyer',
      );
      expect(start, greaterThan(-1));
      final end = lower.indexOf(
        'comment on function public.get_listing_model_data_for_buyer',
      );
      expect(end, greaterThan(start));
      final buyerBlock = lower.substring(start, end);
      final returnsIdx = buyerBlock.indexOf('returns table (');
      expect(returnsIdx, greaterThan(-1));
      final returnBlock = buyerBlock.substring(returnsIdx);
      expect(returnBlock, isNot(contains('source_metadata')));
      expect(returnBlock, isNot(contains('cache_key text')));
      expect(returnBlock, isNot(contains('job_id')));
    });

    test('status, confidence, and match_quality checks exist', () {
      expect(lower, contains("'pending'"));
      expect(lower, contains("'succeeded'"));
      expect(lower, contains("'no_data'"));
      expect(lower, contains("'partial'"));
      expect(lower, contains("'failed'"));
      expect(lower, contains("'stale'"));
      expect(lower, contains("'official'"));
      expect(lower, contains("'open_data'"));
      expect(lower, contains("'exact_make_model_year'"));
      expect(lower, contains("'no_match'"));
    });

    test('indexes and TTL/fetched_at fields exist', () {
      expect(lower, contains('vehicle_model_source_cache_lookup_idx'));
      expect(lower, contains('vehicle_model_source_cache_status_updated_idx'));
      expect(lower, contains('vehicle_model_source_cache_ttl_until_idx'));
      expect(lower, contains('fetched_at'));
      expect(lower, contains('ttl_until'));
      expect(lower, contains('unique (cache_key)'));
      expect(lower, contains('unique (idempotency_key)'));
    });

    test('limitation code defaults exist', () {
      expect(lower, contains('carzon_model_data_default_limitation_codes'));
      expect(lower, contains('us_market_data_only'));
      expect(lower, contains('may_differ_by_trim_engine_market'));
      expect(lower, contains('model_level_not_exact_vehicle'));
      expect(lower, contains('not_vehicle_history'));
      expect(lower, contains('not_recall_data'));
    });

    test('normalization helpers and cache_key builder exist', () {
      expect(lower, contains('carzon_model_data_normalize_make_key'));
      expect(lower, contains('carzon_model_data_normalize_model_key'));
      expect(lower, contains('carzon_model_data_build_cache_key'));
      expect(lower, contains('carzon_sha256_hex_utf8'));
    });

    test('claim uses FOR UPDATE SKIP LOCKED', () {
      expect(lower, contains('for update skip locked'));
    });

    test('SECURITY DEFINER and safe search_path on RPCs', () {
      expect(lower, contains('security definer'));
      expect(lower, contains('set search_path = public, pg_temp'));
    });

    test('no external HTTP provider URLs in migration SQL', () {
      expect(lower, isNot(contains('https://fueleconomy.gov')));
      expect(lower, isNot(contains('https://')));
      expect(lower, isNot(contains('wikidata.org')));
    });

    test('does not alter VIN job tables', () {
      expect(lower, isNot(contains('alter table public.vin_processing_jobs')));
      expect(lower, isNot(contains('alter table public.listing_vin_source_results')));
      expect(lower, isNot(contains('alter table public.listings')));
    });
  });
}
