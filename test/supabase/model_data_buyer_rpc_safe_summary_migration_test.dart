import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Model Passport buyer RPC safe summary projection.
void main() {
  group('20260706133000_model_data_buyer_rpc_safe_summary.sql', () {
    late String sql;
    late String lower;
    late String buyerBlock;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260706133000_model_data_buyer_rpc_safe_summary.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'safe summary migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();

      final start = lower.indexOf(
        'create or replace function public.get_listing_model_data_for_buyer',
      );
      expect(start, greaterThan(-1));
      final end = lower.indexOf(
        'comment on function public.get_listing_model_data_for_buyer',
      );
      expect(end, greaterThan(start));
      buyerBlock = lower.substring(start, end);
    });

    test('recreates get_listing_model_data_for_buyer with same return signature', () {
      expect(
        lower,
        contains(
          'create or replace function public.get_listing_model_data_for_buyer(p_listing_id uuid)',
        ),
      );
      expect(buyerBlock, contains('returns table ('));
      expect(buyerBlock, contains('source_id text'));
      expect(buyerBlock, contains('normalized_summary jsonb'));
      expect(buyerBlock, contains('limitation_codes text[]'));
      expect(buyerBlock, contains('match_quality text'));
      expect(buyerBlock, contains('source_label text'));
      expect(buyerBlock, contains('provider_version text'));
      expect(buyerBlock, contains('fetched_at timestamptz'));
      expect(buyerBlock, contains('ttl_until timestamptz'));
      expect(buyerBlock, contains('updated_at timestamptz'));
    });

    test('function is volatile for PostgREST write side-effects', () {
      expect(buyerBlock, contains('volatile'));
      expect(buyerBlock, isNot(contains('\nstable\n')));
    });

    test('notifies PostgREST to reload schema', () {
      expect(lower, contains("notify pgrst, 'reload schema'"));
    });

    test('projects normalized_summary via explicit allowlist', () {
      expect(buyerBlock, contains('jsonb_build_object'));
      expect(buyerBlock, contains('jsonb_strip_nulls'));
      expect(buyerBlock, contains('buyer_summary.normalized_summary'));
      expect(buyerBlock, isNot(contains('c.normalized_summary,')));
      expect(buyerBlock, contains("'fuel_type'"));
      expect(buyerBlock, contains("'city_l_per_100km'"));
      expect(buyerBlock, contains("'highway_l_per_100km'"));
      expect(buyerBlock, contains("'combined_l_per_100km'"));
      expect(buyerBlock, contains("'co2_g_per_km'"));
      expect(buyerBlock, contains("'vehicle_class'"));
      expect(buyerBlock, contains("'market'"));
      expect(buyerBlock, contains("'match_quality'"));
    });

    test('forbidden normalized_summary keys are not projected', () {
      const forbidden = [
        'provider_vehicle_id',
        'city_mpg',
        'highway_mpg',
        'combined_mpg',
        'co2_g_per_mile',
        'transmission',
        'drive',
        'engine_descriptor',
        'source_metadata',
        'cache_key',
      ];
      for (final key in forbidden) {
        expect(
          buyerBlock,
          isNot(contains("'$key'")),
          reason: 'forbidden key $key must not appear in allowlist projection',
        );
      }
    });

    test('filters on projected summary not empty', () {
      expect(
        buyerBlock,
        contains("buyer_summary.normalized_summary <> '{}'::jsonb"),
      );
    });

    test('preserves enqueue, status filter, and identity match behavior', () {
      expect(buyerBlock, contains('enqueue_vehicle_model_fetch_if_needed'));
      expect(buyerBlock, contains("c.status in ('succeeded', 'partial')"));
      expect(buyerBlock, contains("c.source_id = 'epa_fueleconomy'"));
      expect(buyerBlock, contains('carzon_model_data_resolve_identity'));
      expect(buyerBlock, contains('carzon_model_data_default_limitation_codes'));
      expect(buyerBlock, contains("li.status = 'active'"));
    });

    test('does not reference listing_vehicle_identity', () {
      expect(buyerBlock, isNot(contains('listing_vehicle_identity')));
      expect(buyerBlock, isNot(contains('vin_hash')));
      expect(buyerBlock, isNot(contains('vin_normalized')));
    });

    test('does not create or drop tables', () {
      expect(lower, isNot(contains('create table')));
      expect(lower, isNot(contains('drop table')));
      expect(lower, isNot(contains('alter table')));
    });

    test('grants execute to anon and authenticated', () {
      expect(
        lower,
        contains(
          'grant execute on function public.get_listing_model_data_for_buyer(uuid)',
        ),
      );
      expect(lower, contains('to anon, authenticated'));
      expect(
        lower,
        contains(
          'revoke all on function public.get_listing_model_data_for_buyer(uuid)',
        ),
      );
    });

    test('does not expose provider alias metadata through buyer RPC', () {
      final pendingSql = File(
        'supabase/migrations/20260709120000_buyer_official_data_pending_signals.sql',
      ).readAsStringSync().toLowerCase();
      final pendingStart = pendingSql.indexOf(
        'create or replace function public.get_listing_model_data_for_buyer',
      );
      final pendingEnd = pendingSql.indexOf(
        'comment on function public.get_listing_model_data_for_buyer',
      );
      expect(pendingStart, greaterThan(-1));
      expect(pendingEnd, greaterThan(pendingStart));
      final pendingBuyerBlock = pendingSql.substring(pendingStart, pendingEnd);

      for (final block in [buyerBlock, pendingBuyerBlock]) {
        expect(block, isNot(contains('source_metadata,')));
        expect(block, isNot(contains('provider_model_query_original')));
        expect(block, isNot(contains('provider_model_query_matched')));
        expect(block, isNot(contains('provider_model_alias_used')));
        expect(block, isNot(contains('identity_candidate_source')));
        expect(block, isNot(contains('attempted_provider_models')));
      }
    });

    test('does not touch VIN or Recall objects', () {
      expect(lower, isNot(contains('listing_vin')));
      expect(lower, isNot(contains('vin_processing')));
      expect(lower, isNot(contains('recall')));
    });
  });
}
