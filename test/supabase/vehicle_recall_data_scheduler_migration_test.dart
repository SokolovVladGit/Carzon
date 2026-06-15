import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Recall pg_cron scheduler migration.
void main() {
  group('20260707123000_schedule_process_recall_data_jobs_cron.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260707123000_schedule_process_recall_data_jobs_cron.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'recall scheduler migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('schedules pg_cron job every 30 minutes and posts via pg_net', () {
      expect(lower, contains('pg_cron'));
      expect(lower, contains('net.http_post'));
      expect(lower, contains('carzon_process_recall_data_jobs_30m'));
      expect(lower, contains('cron.schedule'));
      expect(lower, contains('*/30 * * * *'));
      expect(lower, contains('carzon_invoke_process_recall_data_jobs_worker'));
    });

    test('references process-recall-data-jobs URL shape and internal header', () {
      expect(lower, contains('functions/v1/process-recall-data-jobs'));
      expect(lower, contains('x-carzon-internal-secret'));
      expect(lower, contains('carzon_process_recall_data_jobs_url'));
      expect(lower, contains('carzon_process_recall_data_jobs_secret'));
    });

    test('reads secrets from vault view only', () {
      expect(lower, contains('vault.decrypted_secrets'));
      expect(
        sql.toUpperCase(),
        isNot(contains('CARZON_PROCESS_RECALL_DATA_JOBS_SECRET=')),
      );
      expect(lower, isNot(contains('begin private key')));
    });

    test('does not grant execute on worker invoke to client roles', () {
      expect(lower, contains('revoke all'));
      expect(lower, contains('authenticated'));
      expect(lower, contains('anon'));
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.carzon_invoke_process_recall_data_jobs_worker',
          ),
        ),
      );
    });

    test('does not reference Model Passport or VIN workers', () {
      expect(lower, isNot(contains('process-model-data-jobs')));
      expect(lower, isNot(contains('process-vin-decode-jobs')));
      expect(lower, isNot(contains('carzon_process_model_data_jobs')));
      expect(lower, isNot(contains('listing_vehicle_identity')));
      expect(lower, isNot(contains('vin_hash')));
    });
  });
}
