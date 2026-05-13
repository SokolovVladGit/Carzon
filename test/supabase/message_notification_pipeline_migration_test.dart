import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for `20260528120000_message_notification_delivery_pipeline.sql`.
///
/// Does not execute Postgres, Edge, or Firebase.
void main() {
  group('20260528120000_message_notification_delivery_pipeline.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260528120000_message_notification_delivery_pipeline.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'Phase 3A pipeline migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('creates queue and attempt log tables with RLS', () {
      expect(lower, contains('create table if not exists public.notification_delivery_events'));
      expect(lower, contains('create table if not exists public.notification_delivery_attempts'));
      expect(lower, contains('alter table public.notification_delivery_events enable row level security'));
      expect(lower, contains('alter table public.notification_delivery_attempts enable row level security'));
    });

    test('revokes anon/authenticated on internal tables', () {
      expect(lower, contains('revoke all on table public.notification_delivery_events from anon'));
      expect(lower, contains('revoke all on table public.notification_delivery_events from authenticated'));
      expect(lower, contains('revoke all on table public.notification_delivery_attempts from anon'));
      expect(lower, contains('revoke all on table public.notification_delivery_attempts from authenticated'));
    });

    test('defines enqueue trigger and claim RPC for service_role', () {
      expect(lower, contains('enqueue_message_notification_event'));
      expect(lower, contains('messages_enqueue_message_notification'));
      expect(lower, contains('claim_notification_events_for_processing'));
      expect(lower, contains('grant execute on function public.claim_notification_events_for_processing'));
      expect(lower, contains('to service_role'));
    });

    test('enqueue path does not reference external HTTP/FCM', () {
      expect(lower, isNot(contains('http://')));
      expect(lower, isNot(contains('https://')));
      expect(lower, isNot(contains('fcm.googleapis.com')));
    });

    test('enqueue payload build does not include message body column', () {
      final start = lower.indexOf('create or replace function public.enqueue_message_notification_event');
      expect(start, greaterThan(-1));
      final end = lower.indexOf('create or replace function public.claim_notification_events_for_processing', start);
      expect(end, greaterThan(start));
      final fn = lower.substring(start, end);
      expect(fn, isNot(contains('new.body')));
    });

    test('message dedup partial unique index exists', () {
      expect(lower, contains('notification_delivery_events_message_dedup_idx'));
    });
  });

  group('supabase/functions/process-message-notifications/index.ts', () {
    late String ts;

    setUpAll(() {
      final f = File('supabase/functions/process-message-notifications/index.ts');
      expect(f.existsSync(), isTrue, reason: 'process-message-notifications Edge Function exists');
      ts = f.readAsStringSync();
    });

    test('uses internal secret header and documents env secrets', () {
      expect(ts, contains('x-carzon-internal-secret'));
      expect(ts, contains('CARZON_PROCESS_MESSAGE_NOTIFICATIONS_SECRET'));
      expect(ts, contains('SUPABASE_SERVICE_ROLE_KEY'));
      expect(ts, contains('FCM_PROJECT_ID'));
      expect(ts, contains('FCM_PRIVATE_KEY'));
      expect(ts, contains('FCM_SERVICE_ACCOUNT_JSON'));
    });

    test('does not hardcode private keys in source', () {
      expect(ts.toLowerCase(), isNot(contains('begin private key')));
    });

    test('Russian generic title/body are fixed strings', () {
      expect(ts, contains('Новое сообщение'));
      expect(ts, contains('Вам написали по объявлению в Carzon.'));
    });

    test('FCM data payload keys are minimal (no email/body)', () {
      expect(ts, contains('type: "message"'));
      expect(ts.toLowerCase(), isNot(contains('mailto')));
      expect(ts, isNot(contains('message_body')));
      expect(ts, isNot(contains('p_body')));
    });
  });
}
