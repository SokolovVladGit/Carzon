import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Recall / Safety Campaigns Phase 1 foundation migration.
void main() {
  group('20260707120000_vehicle_recall_data_foundation.sql', () {
    late String sql;
    late String lower;
    late String buyerBlock;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260707120000_vehicle_recall_data_foundation.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'recall foundation migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();

      final start = lower.indexOf(
        'create or replace function public.get_listing_recalls_for_buyer',
      );
      expect(start, greaterThan(-1));
      final end = lower.indexOf(
        'comment on function public.get_listing_recalls_for_buyer',
      );
      expect(end, greaterThan(start));
      buyerBlock = lower.substring(start, end);
    });

    test('creates recall cache and job tables', () {
      expect(lower, contains('vehicle_recall_source_cache'));
      expect(lower, contains('vehicle_recall_fetch_jobs'));
    });

    test('does not modify Model Passport or VIN tables', () {
      expect(lower, isNot(contains('alter table public.vehicle_model_source_cache')));
      expect(lower, isNot(contains('alter table public.vehicle_model_fetch_jobs')));
      expect(lower, isNot(contains('alter table public.vin_processing_jobs')));
      expect(lower, isNot(contains('alter table public.listing_vin_source_results')));
      expect(lower, isNot(contains('alter table public.listing_vehicle_identity')));
      expect(lower, isNot(contains('alter table public.listings')));
      expect(lower, isNot(contains('alter table public.vin_decode_cache')));
    });

    test('enables RLS and revokes direct anon/authenticated table access', () {
      expect(lower, contains('enable row level security'));
      expect(
        lower,
        contains('revoke all on table public.vehicle_recall_source_cache'),
      );
      expect(
        lower,
        contains('revoke all on table public.vehicle_recall_fetch_jobs'),
      );
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
    });

    test('source_id nhtsa_recalls is used', () {
      expect(lower, contains("'nhtsa_recalls'"));
      expect(lower, contains('carzon_recall_data_resolve_identity'));
      expect(lower, contains('carzon_recall_data_build_cache_key'));
      expect(lower, contains('carzon_recall_data_default_limitation_codes'));
    });

    test('buyer RPC exists, is volatile, and granted to anon/authenticated', () {
      expect(lower, contains('get_listing_recalls_for_buyer'));
      expect(buyerBlock, contains('volatile'));
      expect(buyerBlock, isNot(contains('\nstable\n')));
      expect(
        lower,
        contains(
          'grant execute on function public.get_listing_recalls_for_buyer(uuid)',
        ),
      );
      expect(lower, contains('to anon, authenticated'));
    });

    test('worker RPCs exist and are service_role only', () {
      expect(lower, contains('enqueue_vehicle_recall_fetch_if_needed'));
      expect(lower, contains('claim_vehicle_recall_fetch_jobs_for_processing'));
      expect(lower, contains('complete_vehicle_recall_fetch_job_success'));
      expect(lower, contains('complete_vehicle_recall_fetch_job_failure'));
      expect(lower, contains('to service_role'));
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.claim_vehicle_recall_fetch_jobs_for_processing(integer, text)\n    to anon',
          ),
        ),
      );
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.claim_vehicle_recall_fetch_jobs_for_processing(integer, text)\n    to authenticated',
          ),
        ),
      );
    });

    test('buyer RPC does not read VIN or identity tables', () {
      expect(buyerBlock, isNot(contains('listing_vehicle_identity')));
      expect(buyerBlock, isNot(contains('vin_hash')));
      expect(buyerBlock, isNot(contains('vin_normalized')));
      expect(buyerBlock, isNot(contains('listing_vin_source_results')));
      expect(buyerBlock, isNot(contains('vin_decode_cache')));
      expect(buyerBlock, isNot(contains('vin_processing_jobs')));
    });

    test('buyer RPC return projection excludes internal fields', () {
      final returnsIdx = buyerBlock.indexOf('returns table (');
      expect(returnsIdx, greaterThan(-1));
      final returnBlock = buyerBlock.substring(returnsIdx);
      expect(returnBlock, isNot(contains('source_metadata')));
      expect(returnBlock, isNot(contains('cache_key text')));
      expect(returnBlock, isNot(contains('job_id')));
      expect(returnBlock, isNot(contains('error_code')));
      expect(returnBlock, isNot(contains('error_message')));
    });

    test('buyer RPC projects campaigns via explicit allowlist', () {
      expect(buyerBlock, contains('jsonb_build_object'));
      expect(buyerBlock, contains('jsonb_strip_nulls'));
      expect(buyerBlock, contains('buyer_summary.normalized_summary'));
      expect(buyerBlock, isNot(contains('c.normalized_summary,')));
      expect(buyerBlock, contains("'campaigns'"));
      expect(buyerBlock, contains("'campaign_count'"));
      expect(buyerBlock, contains("'market'"));
      expect(buyerBlock, contains("'campaign_number'"));
      expect(buyerBlock, contains("'manufacturer'"));
      expect(buyerBlock, contains("'component'"));
      expect(buyerBlock, contains("'summary'"));
      expect(buyerBlock, contains("'consequence'"));
      expect(buyerBlock, contains("'remedy'"));
      expect(buyerBlock, contains("'notes'"));
      expect(buyerBlock, contains("'report_received_date'"));
      expect(buyerBlock, contains("'nhtsa_action_number'"));
      expect(buyerBlock, contains("'park_it'"));
      expect(buyerBlock, contains("'park_outside'"));
      expect(buyerBlock, contains("'over_the_air_update'"));
    });

    test('forbidden buyer projection keys are absent', () {
      const forbidden = [
        'source_metadata',
        'cache_key',
        'raw_provider',
        'provider_response',
        'listing_id',
        'vin_hash',
        'vin_normalized',
      ];
      for (final key in forbidden) {
        expect(
          buyerBlock,
          isNot(contains("'$key'")),
          reason: 'forbidden key $key must not appear in buyer allowlist',
        );
      }
    });

    test('buyer RPC only returns rows with displayable campaigns', () {
      expect(buyerBlock, contains("c.status in ('succeeded', 'partial')"));
      expect(buyerBlock, contains("c.source_id = 'nhtsa_recalls'"));
      expect(buyerBlock, contains('jsonb_array_length'));
      expect(buyerBlock, contains("li.status = 'active'"));
      expect(
        buyerBlock,
        contains('perform public.enqueue_vehicle_recall_fetch_if_needed'),
      );
    });

    test('cache and job status whitelists exist', () {
      expect(lower, contains("'pending'"));
      expect(lower, contains("'succeeded'"));
      expect(lower, contains("'no_data'"));
      expect(lower, contains("'partial'"));
      expect(lower, contains("'failed'"));
      expect(lower, contains("'stale'"));
      expect(lower, contains("'queued'"));
      expect(lower, contains("'processing'"));
      expect(lower, contains("'dead'"));
    });

    test('default limitation codes are model-level and not VIN-verified', () {
      expect(lower, contains('model_level_not_exact_vehicle'));
      expect(lower, contains('not_vin_verified_recall_status'));
      expect(lower, contains('verify_with_official_dealer_or_nhtsa'));
    });

    test('indexes, TTL, and idempotency exist', () {
      expect(lower, contains('vehicle_recall_source_cache_lookup_idx'));
      expect(lower, contains('vehicle_recall_source_cache_ttl_until_idx'));
      expect(lower, contains('vehicle_recall_fetch_jobs_status_run_after_idx'));
      expect(lower, contains('unique (cache_key)'));
      expect(lower, contains('unique (idempotency_key)'));
      expect(lower, contains('fetched_at'));
      expect(lower, contains('ttl_until'));
      expect(lower, contains('run_after'));
    });

    test('claim uses FOR UPDATE SKIP LOCKED and respects run_after', () {
      expect(lower, contains('for update skip locked'));
      expect(lower, contains('j.run_after <= now()'));
    });

    test('failure completion supports retry backoff', () {
      expect(lower, contains('p_retry_delay_seconds'));
      expect(lower, contains('run_after = now()'));
      expect(lower, contains("status = 'dead'"));
    });

    test('SECURITY DEFINER and safe search_path on RPCs', () {
      expect(lower, contains('security definer'));
      expect(lower, contains('set search_path = public, pg_temp'));
    });

    test('no external HTTP provider URLs in migration SQL', () {
      expect(lower, isNot(contains('https://api.nhtsa.gov')));
      expect(lower, isNot(contains('https://')));
    });

    test('comments avoid exact-vehicle open recall claims', () {
      const forbidden = [
        'this exact vehicle has an open recall',
        'open recall on this vehicle',
        'this vehicle has an open recall',
      ];
      for (final phrase in forbidden) {
        expect(
          lower,
          isNot(contains(phrase)),
          reason: 'unsafe phrase: $phrase',
        );
      }
      expect(
        lower,
        contains('not vin-verified open recall status for this exact vehicle'),
      );
    });

    test('notifies PostgREST to reload schema', () {
      expect(lower, contains("notify pgrst, 'reload schema'"));
    });

    test('reuses generic model-data normalizers without coupling cache tables', () {
      expect(lower, contains('carzon_model_data_fold_whitespace'));
      expect(lower, contains('carzon_model_data_normalize_make_key'));
      expect(lower, contains('carzon_model_data_normalize_model_key'));
      expect(lower, isNot(contains('vehicle_model_source_cache')));
      expect(lower, isNot(contains('vehicle_model_fetch_jobs')));
      expect(lower, isNot(contains('get_listing_model_data_for_buyer')));
    });
  });
}
