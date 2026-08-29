import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

const _migrationPath =
    'supabase/migrations/20260825120000_reduce_idle_background_worker_io.sql';

String _functionSql(String lowerSql, String functionName) {
  final marker = 'create or replace function public.$functionName()';
  final start = lowerSql.indexOf(marker);
  expect(start, greaterThanOrEqualTo(0), reason: '$functionName exists');

  final bodyStart = lowerSql.indexOf('as \$\$', start);
  expect(bodyStart, greaterThan(start), reason: '$functionName has SQL body');
  final end = lowerSql.indexOf('\n\$\$;', bodyStart);
  expect(end, greaterThan(bodyStart), reason: '$functionName body terminates');
  return lowerSql.substring(start, end + 4);
}

void main() {
  late String sql;
  late String lower;

  setUpAll(() {
    final migration = File(_migrationPath);
    expect(
      migration.existsSync(),
      isTrue,
      reason: 'efficiency migration exists',
    );
    sql = migration.readAsStringSync();
    lower = sql.toLowerCase();
  });

  group('background worker eligibility preflights', () {
    const workerPredicates = <String, List<String>>{
      'carzon_invoke_process_message_notifications_worker': [
        'from public.notification_delivery_events',
        "e.event_type = 'message_created'",
        "e.status = 'pending'",
        'e.next_attempt_at <= now()',
      ],
      'carzon_invoke_process_filter_alert_notifications_worker': [
        'from public.notification_delivery_events',
        "e.event_type = 'filter_alert_listing_match'",
        "e.status = 'pending'",
        'e.next_attempt_at <= now()',
      ],
      'carzon_invoke_process_price_drop_notifications_worker': [
        'from public.notification_delivery_events',
        "e.event_type = 'price_drop_favorite'",
        "e.status = 'pending'",
        'e.next_attempt_at <= now()',
      ],
      'carzon_invoke_process_vin_decode_jobs_worker': [
        'from public.vin_processing_jobs',
        "j.job_type = 'decode'",
        "j.status = 'pending'",
        'j.next_run_at <= now()',
        'j.attempts < j.max_attempts',
      ],
      'carzon_invoke_process_model_data_jobs_worker': [
        'from public.vehicle_model_fetch_jobs',
        "j.status = 'queued'",
        'j.attempts < j.max_attempts',
      ],
      'carzon_invoke_process_recall_data_jobs_worker': [
        'from public.vehicle_recall_fetch_jobs',
        "j.status = 'queued'",
        'j.run_after <= now()',
        'j.attempts < j.max_attempts',
      ],
      'carzon_invoke_process_fuel_price_jobs_worker': [
        'from public.fuel_price_fetch_jobs',
        "j.status = 'queued'",
        'j.attempts < j.max_attempts',
      ],
    };

    test('all seven invokers gate HTTP before Vault access', () {
      for (final entry in workerPredicates.entries) {
        final body = _functionSql(lower, entry.key);
        final preflight = body.indexOf('if not exists');
        final vault = body.indexOf('vault.decrypted_secrets');
        final http = body.indexOf('net.http_post');

        expect(preflight, greaterThan(-1), reason: '${entry.key} preflight');
        expect(
          vault,
          greaterThan(preflight),
          reason: '${entry.key} Vault after gate',
        );
        expect(
          http,
          greaterThan(vault),
          reason: '${entry.key} HTTP after gate',
        );
        for (final predicate in entry.value) {
          expect(body, contains(predicate), reason: '${entry.key}: $predicate');
        }
      }

      expect(RegExp(r'net\.http_post').allMatches(lower).length, 7);
    });

    test('notification workers remain event-type isolated', () {
      final message = _functionSql(
        lower,
        'carzon_invoke_process_message_notifications_worker',
      );
      final filter = _functionSql(
        lower,
        'carzon_invoke_process_filter_alert_notifications_worker',
      );
      final price = _functionSql(
        lower,
        'carzon_invoke_process_price_drop_notifications_worker',
      );

      expect(message, contains("e.event_type = 'message_created'"));
      expect(message, isNot(contains('filter_alert_listing_match')));
      expect(message, isNot(contains('price_drop_favorite')));
      expect(filter, contains("e.event_type = 'filter_alert_listing_match'"));
      expect(filter, isNot(contains("e.event_type = 'message_created'")));
      expect(filter, isNot(contains('price_drop_favorite')));
      expect(price, contains("e.event_type = 'price_drop_favorite'"));
      expect(price, isNot(contains("e.event_type = 'message_created'")));
      expect(price, isNot(contains('filter_alert_listing_match')));
    });

    test('model preflight does not invent due-time semantics', () {
      final body = _functionSql(
        lower,
        'carzon_invoke_process_model_data_jobs_worker',
      );
      expect(body, isNot(contains('run_after')));
      expect(body, isNot(contains('next_run_at')));
    });

    test('fuel enqueue remains before its eligibility preflight', () {
      final body = _functionSql(
        lower,
        'carzon_invoke_process_fuel_price_jobs_worker',
      );
      final enqueue = body.indexOf('enqueue_all_fuel_price_fetch_jobs');
      final preflight = body.indexOf('if not exists');
      expect(enqueue, greaterThan(-1));
      expect(preflight, greaterThan(enqueue));
    });

    test('preflights do not add claim or locking authority', () {
      expect(lower, isNot(contains('for update')));
      expect(lower, isNot(contains('advisory_lock')));
      expect(lower, isNot(contains('claim_notification_events')));
      expect(lower, isNot(contains('claim_vin_decode_jobs')));
    });
  });

  group('worker schedules and security', () {
    const schedules = <String, List<String>>{
      'supabase/migrations/20260529120000_schedule_process_message_notifications_cron.sql':
          ['carzon_process_message_notifications_1m', '* * * * *'],
      'supabase/migrations/20260601120000_filter_alert_notifications_queue_and_cron.sql':
          ['carzon_process_filter_alert_notifications_1m', '* * * * *'],
      'supabase/migrations/20260802120000_price_drop_favorite_notifications.sql':
          ['carzon_process_price_drop_notifications_1m', '* * * * *'],
      'supabase/migrations/20260621120000_schedule_process_vin_decode_jobs_cron.sql':
          ['carzon_process_vin_decode_jobs_5m', '*/5 * * * *'],
      'supabase/migrations/20260706123000_schedule_process_model_data_jobs_cron.sql':
          ['carzon_process_model_data_jobs_30m', '*/30 * * * *'],
      'supabase/migrations/20260707123000_schedule_process_recall_data_jobs_cron.sql':
          ['carzon_process_recall_data_jobs_30m', '*/30 * * * *'],
      'supabase/migrations/20260822123000_schedule_process_fuel_price_jobs_cron.sql':
          ['carzon_process_fuel_price_jobs_6h', '0 */6 * * *'],
    };

    test('all seven existing schedules remain at their source cadence', () {
      for (final entry in schedules.entries) {
        final source = File(entry.key).readAsStringSync();
        expect(source, contains(entry.value[0]), reason: entry.key);
        expect(source, contains(entry.value[1]), reason: entry.key);
      }
      expect(lower, isNot(contains('carzon_dispatch')));
      expect(lower, isNot(contains('notification_dispatcher')));
    });

    test('all invokers preserve definer/search path and client revokes', () {
      for (final functionName in <String>[
        'carzon_invoke_process_message_notifications_worker',
        'carzon_invoke_process_filter_alert_notifications_worker',
        'carzon_invoke_process_price_drop_notifications_worker',
        'carzon_invoke_process_vin_decode_jobs_worker',
        'carzon_invoke_process_model_data_jobs_worker',
        'carzon_invoke_process_recall_data_jobs_worker',
        'carzon_invoke_process_fuel_price_jobs_worker',
      ]) {
        final body = _functionSql(lower, functionName);
        expect(body, contains('security definer'), reason: functionName);
        expect(
          body,
          contains('set search_path = public'),
          reason: functionName,
        );
        expect(
          lower,
          contains(
            'revoke all on function public.$functionName() from public;',
          ),
        );
        expect(
          lower,
          contains('revoke all on function public.$functionName() from anon;'),
        );
        expect(
          lower,
          contains(
            'revoke all on function public.$functionName()\n    from authenticated;',
          ),
        );
      }
    });
  });

  group('bounded pg_cron history retention', () {
    test('deletes no more than 10000 completed rows older than 14 days', () {
      final body = _functionSql(lower, 'carzon_cleanup_cron_job_run_details');
      expect(body, contains('from cron.job_run_details'));
      expect(body, contains('d.end_time is not null'));
      expect(body, contains("interval '14 days'"));
      expect(body, contains('limit 10000'));
      expect(body, contains('delete from cron.job_run_details'));
      expect(body, contains('order by d.end_time asc, d.runid asc'));
      expect(body, isNot(contains('truncate')));
    });

    test('schedules one deterministic daily off-peak cleanup', () {
      expect(lower, contains('carzon_cleanup_cron_job_run_details_daily'));
      expect(lower, contains("'17 3 * * *'"));
      expect(lower, contains('cron.unschedule(jid)'));
      expect(lower, contains('cron.schedule'));
    });

    test('maintenance function is internal and uses a hardened search path', () {
      final body = _functionSql(lower, 'carzon_cleanup_cron_job_run_details');
      expect(body, contains('security definer'));
      expect(body, contains('set search_path = pg_catalog, pg_temp'));
      expect(
        lower,
        contains(
          'revoke all on function public.carzon_cleanup_cron_job_run_details() from public;',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.carzon_cleanup_cron_job_run_details() from anon;',
        ),
      );
      expect(
        lower,
        contains(
          'revoke all on function public.carzon_cleanup_cron_job_run_details()\n    from authenticated;',
        ),
      );
    });

    test('migration does not perform physical bloat maintenance', () {
      expect(lower, isNot(contains('vacuum full')));
      expect(lower, isNot(contains('reindex')));
      expect(lower, isNot(contains('alter table cron.job_run_details')));
      expect(lower, isNot(contains('drop extension')));
    });
  });
}
