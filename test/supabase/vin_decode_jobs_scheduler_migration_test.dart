import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for VIN decode pg_cron scheduler migration (Vault + pg_net).
///
/// Does not execute Postgres, Edge, or hosted deploy.
void main() {
  group('20260621120000_schedule_process_vin_decode_jobs_cron.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260621120000_schedule_process_vin_decode_jobs_cron.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'VIN decode cron migration exists',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('schedules pg_cron job every 5 minutes and posts via pg_net', () {
      expect(lower, contains('pg_cron'));
      expect(lower, contains('net.http_post'));
      expect(lower, contains('carzon_process_vin_decode_jobs_5m'));
      expect(lower, contains('cron.schedule'));
      expect(lower, contains('*/5 * * * *'));
      expect(lower, contains('carzon_invoke_process_vin_decode_jobs_worker'));
    });

    test('references process-vin-decode-jobs URL shape and internal header', () {
      expect(lower, contains('functions/v1/process-vin-decode-jobs'));
      expect(lower, contains('x-carzon-internal-secret'));
      expect(lower, contains('carzon_process_vin_decode_jobs_url'));
      expect(lower, contains('carzon_process_vin_decode_jobs_secret'));
    });

    test('posts conservative batch limit in JSON body', () {
      expect(lower, contains("'limit'"));
      expect(lower, contains('10'));
      expect(lower, contains('jsonb_build_object'));
    });

    test('reads secrets from vault view only (no env secret assignment in SQL)', () {
      expect(lower, contains('vault.decrypted_secrets'));
      expect(sql.toUpperCase(), isNot(contains('CARZON_PROCESS_VIN_DECODE_JOBS_SECRET=')));
      expect(lower, isNot(contains('begin private key')));
      expect(lower, isNot(contains('zypqfwktvzfnfvihxhbd')));
    });

    test('does not alter public listings or vin_status', () {
      expect(lower, isNot(contains('alter table public.listings')));
      expect(lower, isNot(contains('vin_status')));
    });

    test('does not expose VIN identifiers', () {
      expect(lower, isNot(contains('vin_hash')));
      expect(lower, isNot(contains('vin_normalized')));
    });

    test('does not grant execute on worker to client roles', () {
      expect(lower, contains('revoke all'));
      expect(lower, contains('authenticated'));
      expect(lower, contains('anon'));
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.carzon_invoke_process_vin_decode_jobs_worker',
          ),
        ),
      );
    });

    test('does not add listing/VIN-queue RPCs beyond cron invoke helper', () {
      expect(lower, isNot(contains('listing_vehicle_identity')));
      expect(lower, isNot(contains('vin_processing_jobs')));
      expect(lower, isNot(contains('get_vin_for_decode_job')));
      expect(lower, isNot(contains('claim_vin_decode_jobs_for_processing')));
      expect(lower, contains('carzon_invoke_process_vin_decode_jobs_worker'));
    });
  });
}
