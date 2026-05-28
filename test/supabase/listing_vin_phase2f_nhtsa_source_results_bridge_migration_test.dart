import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260624120000_vin_phase2f_nhtsa_source_results_bridge.sql`.
void main() {
  group('20260624120000_vin_phase2f_nhtsa_source_results_bridge.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260624120000_vin_phase2f_nhtsa_source_results_bridge.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'Phase 2F NHTSA bridge migration must exist',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test(
      'replaces complete_vin_decode_job_success with same parameter list',
      () {
        expect(
          lower,
          contains(
            'create or replace function public.complete_vin_decode_job_success',
          ),
        );
        expect(lower, contains('p_normalized_data jsonb'));
        expect(lower, contains('p_field_comparisons jsonb'));
      },
    );

    test('upserts listing_vin_source_results only for nhtsa_vpic', () {
      expect(lower, contains("if p_provider_id = 'nhtsa_vpic'"));
      expect(lower, contains('insert into public.listing_vin_source_results'));
      expect(lower, contains('on conflict (listing_id, source_id)'));
      expect(lower, contains("'nhtsa_vpic'"));
    });

    test('uses expected taxonomy fields', () {
      expect(lower, contains("'international'"));
      expect(lower, contains("'carzon_partner_api'"));
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
        expect(
          lower,
          contains("'$code'"),
          reason: 'limitation_codes must include $code',
        );
      }
    });

    test(
      'normalized_summary uses make model year body_type fuel engine transmission',
      () {
        expect(lower, contains("'make'"));
        expect(lower, contains("'body_type'"));
        expect(lower, contains("'fuel_type'"));
        expect(lower, contains("'engine'"));
        expect(lower, contains("'transmission'"));
        expect(lower, contains('jsonb_strip_nulls'));
      },
    );

    test('source_metadata allows safe provenance only', () {
      expect(lower, contains("'provider_id'"));
      expect(lower, contains("'provider_version'"));
      expect(lower, contains("'source_label'"));
      expect(lower, contains("'nhtsa vpic'"));
      expect(lower, contains("'latency_ms'"));
      expect(lower, contains("'warning_codes'"));
    });

    test('status distinguishes succeeded vs partial on useful fields', () {
      expect(lower, contains('v_has_useful'));
      expect(lower, contains("then 'succeeded'"));
      expect(lower, contains("else 'partial'"));
    });

    test('preserves decode cache and snapshot updates', () {
      expect(lower, contains('insert into public.vin_decode_cache'));
      expect(lower, contains('update public.listing_vin_report_snapshot'));
      expect(lower, contains("decode_status = 'decoded'"));
      expect(lower, contains("processing_status = 'succeeded'"));
      expect(lower, contains('on conflict (vin_hash)'));
    });

    test('preserves job terminal success update', () {
      expect(lower, contains('update public.vin_processing_jobs'));
      expect(lower, contains("status = 'succeeded'"));
    });

    test('listing_vin_source_results insert block omits vin_hash column', () {
      final i = lower.indexOf('insert into public.listing_vin_source_results');
      expect(i, greaterThan(-1));
      final untilConflict = lower.indexOf(
        'on conflict (listing_id, source_id)',
        i,
      );
      expect(untilConflict, greaterThan(i));
      final block = lower.substring(i, untilConflict);
      expect(block, isNot(contains('vin_hash')));
    });

    test('no new grants on listing_vin_source_results for client roles', () {
      expect(
        lower,
        isNot(
          contains('grant select on table public.listing_vin_source_results'),
        ),
      );
      expect(
        lower,
        isNot(
          contains('grant insert on table public.listing_vin_source_results'),
        ),
      );
      expect(lower, isNot(contains('to authenticated')));
      expect(lower, isNot(contains('to anon')));
    });

    test('no HTTP URLs or raw payload storage markers in SQL', () {
      expect(lower, isNot(contains('http://')));
      expect(lower, isNot(contains('https://')));
      expect(lower, isNot(contains('raw_payload')));
      expect(lower, isNot(contains('raw provider')));
    });

    test('does not alter public.listings or Edge worker', () {
      expect(lower, isNot(contains('alter table public.listings')));
    });
  });
}
