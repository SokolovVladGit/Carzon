import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Phase 4A filter-alert queue migration, Edge Function, cron, config.
///
/// Does not execute Postgres, Edge, or Firebase.
void main() {
  group('supabase/functions/process-filter-alert-notifications/index.ts', () {
    late String ts;

    setUpAll(() {
      final f = File('supabase/functions/process-filter-alert-notifications/index.ts');
      expect(f.existsSync(), isTrue, reason: 'process-filter-alert-notifications Edge Function exists');
      ts = f.readAsStringSync();
    });

    test('uses internal secret header and documents env secrets', () {
      expect(ts, contains('x-carzon-internal-secret'));
      expect(ts, contains('CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET'));
      expect(ts, contains('SUPABASE_SERVICE_ROLE_KEY'));
      expect(ts, contains('claim_filter_alert_notification_events_for_processing'));
    });

    test('does not hardcode private keys in source', () {
      expect(ts.toLowerCase(), isNot(contains('begin private key')));
    });

    test('Russian generic title/body match Phase 4A product copy', () {
      expect(ts, contains('Новое объявление'));
      expect(ts, contains('Есть объявление по вашему сохранённому фильтру. Откройте, чтобы посмотреть.'));
    });

    test('FCM data payload is minimal ids only', () {
      expect(ts.toLowerCase(), isNot(contains('mailto')));
      final start = ts.indexOf('function dataPayload');
      expect(start, greaterThan(-1));
      final end = ts.indexOf('Deno.serve', start);
      expect(end, greaterThan(start));
      final block = ts.substring(start, end);
      expect(block, contains('filter_alert'));
      expect(block, contains('listing_id'));
      expect(block, contains('event_id'));
      expect(block.toLowerCase(), isNot(contains('seller')));
      expect(block.toLowerCase(), isNot(contains('price')));
    });

    test('claims only filter_alert_listing_match via dedicated RPC', () {
      expect(ts, contains('claim_filter_alert_notification_events_for_processing'));
      expect(ts, isNot(contains('claim_notification_events_for_processing')));
    });
  });

  group('20260601120000_filter_alert_notifications_queue_and_cron.sql — scheduler & vault', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260601120000_filter_alert_notifications_queue_and_cron.sql',
      );
      expect(f.existsSync(), isTrue);
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('schedules pg_cron job every minute for filter worker', () {
      expect(lower, contains('pg_cron'));
      expect(lower, contains('carzon_process_filter_alert_notifications_1m'));
      expect(lower, contains('* * * * *'));
      expect(lower, contains('carzon_invoke_process_filter_alert_notifications_worker'));
    });

    test('posts via pg_net with internal header and Vault secret names', () {
      expect(lower, contains('net.http_post'));
      expect(lower, contains('x-carzon-internal-secret'));
      expect(lower, contains('carzon_process_filter_alert_notifications_url'));
      expect(lower, contains('carzon_process_filter_alert_notifications_secret'));
      expect(lower, contains('vault.decrypted_secrets'));
    });

    test('documents process-filter-alert-notifications URL shape in comments only', () {
      expect(lower, contains('functions/v1/process-filter-alert-notifications'));
      expect(sql.toUpperCase(), isNot(contains('CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET=')));
      expect(lower, isNot(contains('begin private key')));
    });

    test('worker revokes client roles and does not grant execute to callers', () {
      expect(lower, contains('carzon_invoke_process_filter_alert_notifications_worker'));
      expect(lower, contains('from anon'));
      expect(lower, contains('from authenticated'));
      expect(
        lower,
        isNot(
          contains(
            'grant execute on function public.carzon_invoke_process_filter_alert_notifications_worker',
          ),
        ),
      );
    });
  });
}
