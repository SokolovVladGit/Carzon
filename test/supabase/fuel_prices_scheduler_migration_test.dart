import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260822123000_schedule_process_fuel_price_jobs_cron.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260822123000_schedule_process_fuel_price_jobs_cron.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'scheduler migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('uses pg_cron pg_net and vault', () {
      expect(lower, contains('pg_cron'));
      expect(lower, contains('pg_net'));
      expect(lower, contains('supabase_vault'));
    });

    test('schedules carzon_process_fuel_price_jobs_6h', () {
      expect(sql, contains('carzon_process_fuel_price_jobs_6h'));
      expect(sql, contains('carzon_invoke_process_fuel_price_jobs_worker'));
    });

    test('references vault secret names', () {
      expect(sql, contains('carzon_process_fuel_price_jobs_url'));
      expect(sql, contains('carzon_process_fuel_price_jobs_secret'));
    });

    test('invoke helper is not granted to clients', () {
      expect(
        lower,
        contains(
          'revoke all on function public.carzon_invoke_process_fuel_price_jobs_worker()',
        ),
      );
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
    });
  });
}
