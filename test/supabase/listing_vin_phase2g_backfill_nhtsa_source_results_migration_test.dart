import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260625120000_vin_phase2g_backfill_nhtsa_source_results.sql`.
void main() {
  group('20260625120000_vin_phase2g_backfill_nhtsa_source_results.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260625120000_vin_phase2g_backfill_nhtsa_source_results.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'Phase 2G backfill migration must exist');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('inserts into listing_vin_source_results from snapshot and cache join', () {
      expect(lower, contains('insert into public.listing_vin_source_results'));
      expect(lower, contains('from public.listing_vin_report_snapshot s'));
      expect(lower, contains('inner join public.vin_decode_cache c'));
      expect(lower, contains('on c.vin_hash = s.vin_hash'));
    });

    test('filters to nhtsa_vpic and successful decoded snapshot', () {
      expect(lower, contains("c.provider_id = 'nhtsa_vpic'"));
      expect(lower, contains("s.processing_status = 'succeeded'"));
      expect(lower, contains("s.decode_status = 'decoded'"));
      expect(lower, contains("c.decode_status = 'decoded'"));
    });

    test('uses ON CONFLICT DO NOTHING to avoid overwriting existing rows', () {
      expect(lower, contains('on conflict (listing_id, source_id) do nothing'));
    });

    test('uses expected taxonomy for nhtsa row', () {
      expect(lower, contains("'nhtsa_vpic'"));
      expect(lower, contains("'international'"));
      expect(lower, contains("'carzon_partner_api'"));
      expect(lower, contains("'succeeded'"));
      expect(lower, contains("'owner'"));
      expect(lower, contains("'basic_decode'"));
    });

    test('limitation_codes include required conservative entries', () {
      for (final code in [
        'basic_decode_only',
        'not_md_pmr_official_verification',
        'not_accident_history',
        'not_ownership_check',
        'not_insurance_check',
        'not_mileage_check',
        'not_registration_check',
      ]) {
        expect(lower, contains("'$code'"), reason: 'limitation_codes must include $code');
      }
    });

    test('source_metadata includes backfill markers', () {
      expect(lower, contains("'backfilled'"));
      expect(lower, contains("'backfilled_at'"));
      expect(lower, contains("'backfilled', true"));
      expect(lower, contains("'decode-vin-values-v1'"));
    });

    test('normalized_summary uses snapshot and cache normalized fields', () {
      expect(lower, contains("'body_type'"));
      expect(lower, contains("'fuel_type'"));
      expect(lower, contains("c.normalized_data->>'bodytype'"));
      expect(lower, contains("c.normalized_data->>'fueltype'"));
      expect(lower, contains("c.normalized_data->>'engine'"));
      expect(lower, contains("c.normalized_data->>'transmission'"));
    });

    test('fetched_at uses cache then snapshot fallbacks', () {
      expect(lower, contains('coalesce(c.fetched_at, s.last_processed_at, s.updated_at, now())'));
    });

    test('insert column list does not target vin_hash on source results table', () {
      final open = lower.indexOf('insert into public.listing_vin_source_results');
      expect(open, greaterThan(-1));
      final close = lower.indexOf('select', open);
      expect(close, greaterThan(open));
      final insertCols = lower.substring(open, close);
      expect(insertCols, isNot(contains('vin_hash')));
    });

    test('does not grant client roles on listing_vin_source_results', () {
      expect(lower, isNot(contains('grant ')));
      expect(lower, isNot(contains('to authenticated')));
      expect(lower, isNot(contains('to anon')));
    });

    test('no new RPCs and no listings ddl', () {
      expect(lower, isNot(contains('create or replace function')));
      expect(lower, isNot(contains('alter table public.listings')));
    });

    test('no HTTP URLs or credential markers in SQL', () {
      expect(lower, isNot(contains('http://')));
      expect(lower, isNot(contains('https://')));
      expect(lower, isNot(contains('access_token')));
      expect(lower, isNot(contains('api_key')));
    });
  });
}
