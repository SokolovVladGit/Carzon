import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Model Passport pg_cron scheduler migration.
void main() {
  group('20260706123000_schedule_process_model_data_jobs_cron.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260706123000_schedule_process_model_data_jobs_cron.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'scheduler migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('schedules pg_cron job every 30 minutes and posts via pg_net', () {
      expect(lower, contains('pg_cron'));
      expect(lower, contains('net.http_post'));
      expect(lower, contains('carzon_process_model_data_jobs_30m'));
      expect(lower, contains('cron.schedule'));
      expect(lower, contains('*/30 * * * *'));
      expect(lower, contains('carzon_invoke_process_model_data_jobs_worker'));
    });

    test('references process-model-data-jobs URL shape and internal header', () {
      expect(lower, contains('functions/v1/process-model-data-jobs'));
      expect(lower, contains('x-carzon-internal-secret'));
      expect(lower, contains('carzon_process_model_data_jobs_url'));
      expect(lower, contains('carzon_process_model_data_jobs_secret'));
    });

    test('reads secrets from vault view only', () {
      expect(lower, contains('vault.decrypted_secrets'));
      expect(
        sql.toUpperCase(),
        isNot(contains('CARZON_PROCESS_MODEL_DATA_JOBS_SECRET=')),
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
            'grant execute on function public.carzon_invoke_process_model_data_jobs_worker',
          ),
        ),
      );
    });

    test('does not expose VIN identifiers or alter VIN tables', () {
      expect(lower, isNot(contains('vin_hash')));
      expect(lower, isNot(contains('listing_vehicle_identity')));
      expect(lower, isNot(contains('vin_processing_jobs')));
    });
  });
}
