import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Guards `20260619120000_vin_phase2b_worker_rpcs.sql`.
void main() {
  group('20260619120000_vin_phase2b_worker_rpcs.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260619120000_vin_phase2b_worker_rpcs.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'VIN Phase 2B worker migration must exist',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('does not alter public.listings or vin_status', () {
      expect(lower, isNot(contains('alter table public.listings')));
    });

    test('claim RPC uses FOR UPDATE SKIP LOCKED', () {
      expect(lower, contains('for update skip locked'));
      expect(lower, contains('claim_vin_decode_jobs_for_processing'));
      expect(lower, contains('vin_processing_jobs'));
    });

    test('claim RPC increments attempts and sets processing + lock fields', () {
      expect(lower, contains('attempts = j.attempts + 1'));
      expect(lower, contains("status = 'processing'"));
      expect(lower, contains('locked_at = now()'));
      expect(lower, contains('locked_by = p_worker_id'));
    });

    test('claim clamps batch limit between 1 and 50', () {
      expect(lower, contains('greatest(1'));
      expect(lower, contains('least('));
    });

    test(
      'complete success writes decode cache, snapshot, and job terminal state',
      () {
        expect(lower, contains('complete_vin_decode_job_success'));
        expect(lower, contains('vin_decode_cache'));
        expect(lower, contains('listing_vin_report_snapshot'));
        expect(lower, contains("decode_status = 'decoded'"));
        expect(lower, contains("processing_status = 'succeeded'"));
        expect(lower, contains("status = 'succeeded'"));
        expect(lower, contains('on conflict (vin_hash)'));
      },
    );

    test(
      'complete failure implements retry pending + backoff and terminal failed',
      () {
        expect(lower, contains('complete_vin_decode_job_failure'));
        expect(lower, contains("status = 'pending'"));
        expect(lower, contains('next_run_at'));
        expect(lower, contains('power('));
        expect(lower, contains("status = 'failed'"));
        expect(lower, contains("processing_status = 'failed'"));
        expect(lower, contains("decode_status = 'failed'"));
      },
    );

    test('revokes execute from public/anon/authenticated on worker RPCs', () {
      expect(
        lower,
        contains(
          'revoke all on function public.claim_vin_decode_jobs_for_processing',
        ),
      );
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
      expect(lower, contains('complete_vin_decode_job_success'));
      expect(lower, contains('complete_vin_decode_job_failure'));
    });

    test('grants execute only to service_role', () {
      expect(
        lower,
        contains(
          'grant execute on function public.claim_vin_decode_jobs_for_processing(integer, text)',
        ),
      );
      expect(
        lower,
        contains(
          'grant execute on function public.complete_vin_decode_job_success',
        ),
      );
      expect(
        lower,
        contains(
          'grant execute on function public.complete_vin_decode_job_failure(uuid, text, boolean)',
        ),
      );
      expect(lower, contains('to service_role'));
    });

    test('SECURITY DEFINER + safe search_path', () {
      expect(lower, contains('security definer'));
      expect(lower, contains('set search_path = public, pg_temp'));
    });

    test('no external HTTP/provider URLs or secrets in migration', () {
      expect(lower, isNot(contains('pg_net')));
      expect(lower, isNot(contains('http://')));
      expect(lower, isNot(contains('https://')));
      expect(lower, isNot(contains('carvertical')));
      expect(lower, isNot(contains('nhtsa')));
    });
  });
}
