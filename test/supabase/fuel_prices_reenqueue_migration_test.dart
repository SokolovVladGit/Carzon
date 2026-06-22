import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('20260822130000_fix_fuel_price_job_reenqueue.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260822130000_fix_fuel_price_job_reenqueue.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'reenqueue migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('recreates enqueue_fuel_price_fetch_if_needed', () {
      expect(
        lower,
        contains('create or replace function public.enqueue_fuel_price_fetch_if_needed'),
      );
    });

    test('returns truthful requeue status for terminal jobs', () {
      final fnStart = lower.indexOf(
        'create or replace function public.enqueue_fuel_price_fetch_if_needed',
      );
      expect(fnStart, greaterThan(-1));
      final fnBody = lower.substring(fnStart);
      expect(fnBody, contains("return 'requeued'"));
      expect(fnBody, contains("return 'enqueued'"));
      expect(fnBody, contains("return 'already_queued'"));
      expect(fnBody, contains("return 'skipped'"));
      expect(fnBody, isNot(contains('on conflict (idempotency_key) do nothing')));
    });

    test('requeues terminal succeeded failed dead jobs', () {
      expect(
        sql,
        contains("j.status in ('succeeded', 'failed', 'dead')"),
      );
      expect(sql, contains("status = 'queued'"));
      expect(sql, contains('attempts = 0'));
      expect(sql, contains('claimed_at = null'));
      expect(sql, contains('completed_at = null'));
      expect(sql, contains('last_error_safe = null'));
    });

    test('skips duplicate work when job is queued or processing', () {
      expect(
        sql,
        contains("v_existing_status in ('queued', 'processing')"),
      );
    });

    test('preserves service_role grant only', () {
      expect(
        lower,
        contains('grant execute on function public.enqueue_fuel_price_fetch_if_needed(text)'),
      );
      expect(lower, contains('to service_role'));
      expect(lower, contains('revoke all on function public.enqueue_fuel_price_fetch_if_needed(text)'));
    });

    test('does not change public buyer RPC', () {
      expect(lower, isNot(contains('get_fuel_prices_for_app')));
    });
  });
}
