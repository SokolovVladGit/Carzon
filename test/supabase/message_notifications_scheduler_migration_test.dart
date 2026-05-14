import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Phase 3E scheduler migration and related config.
///
/// Does not execute Postgres, Edge, or hosted deploy.
void main() {
  group('20260529120000_schedule_process_message_notifications_cron.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260529120000_schedule_process_message_notifications_cron.sql',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'Phase 3E cron migration exists',
      );
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('schedules pg_cron job and posts via pg_net', () {
      expect(lower, contains('pg_cron'));
      expect(lower, contains('net.http_post'));
      expect(lower, contains('carzon_process_message_notifications_1m'));
      expect(lower, contains("cron.schedule"));
      expect(lower, contains('* * * * *'));
      expect(lower, contains('carzon_invoke_process_message_notifications_worker'));
    });

    test('references process-message-notifications path and internal header', () {
      expect(
        lower,
        contains('functions/v1/process-message-notifications'),
      );
      expect(lower, contains('x-carzon-internal-secret'));
      expect(lower, contains('carzon_process_message_notifications_url'));
      expect(lower, contains('carzon_process_message_notifications_secret'));
    });

    test('reads secrets from vault view only (no env secret assignment in SQL)', () {
      expect(lower, contains('vault.decrypted_secrets'));
      expect(sql.toUpperCase(), isNot(contains('CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET=')));
      expect(lower, isNot(contains('begin private key')));
      // No real project ref in SQL (placeholders only in comments).
      expect(lower, isNot(contains('zypqfwktvzfnfvihxhbd')));
    });

    test('does not grant anon/authenticated on queue tables', () {
      expect(lower, isNot(contains('notification_delivery_events')));
      expect(lower, isNot(contains('notification_delivery_attempts')));
    });

    test('does not grant execute on worker to client roles beyond revoke', () {
      expect(lower, contains('revoke all'));
      expect(lower, contains('authenticated'));
      expect(lower, contains('anon'));
      expect(lower, isNot(contains('grant execute')));
    });

    test('worker forces claim path unchanged (still Edge / service_role only)', () {
      expect(lower, isNot(contains('claim_notification_events_for_processing')));
    });
  });

  group('supabase/config.toml process-message-notifications', () {
    late String raw;

    setUpAll(() {
      final f = File('supabase/config.toml');
      expect(f.existsSync(), isTrue);
      raw = f.readAsStringSync();
    });

    test('verify_jwt is false for internal cron Edge function sections', () {
      expect(raw, contains('[functions.process-message-notifications]'));
      expect(raw, contains('[functions.process-filter-alert-notifications]'));
      final lines = raw.split('\n').where((l) => l.trim() == 'verify_jwt = false').length;
      expect(lines >= 2, isTrue);
    });

    test('docs reference Phase 3E and Phase 4A migrations or ops runbook', () {
      expect(
        raw.contains('20260529120000') ||
            raw.contains('20260601120000') ||
            raw.contains('ops_message_notifications'),
        isTrue,
      );
    });
  });

  group('supabase/functions/process-message-notifications/index.ts (Phase 3E invariants)', () {
    late String ts;

    setUpAll(() {
      final f = File('supabase/functions/process-message-notifications/index.ts');
      expect(f.existsSync(), isTrue);
      ts = f.readAsStringSync();
    });

    test('still requires x-carzon-internal-secret vs env', () {
      expect(ts, contains('x-carzon-internal-secret'));
      expect(ts, contains('CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET'));
    });
  });
}
