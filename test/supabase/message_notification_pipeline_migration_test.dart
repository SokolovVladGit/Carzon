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

  group('20260601120000_filter_alert_notifications_queue_and_cron.sql (Phase 4A)', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260601120000_filter_alert_notifications_queue_and_cron.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'Phase 4A filter alert migration exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('extends event_type for filter_alert_listing_match', () {
      expect(lower, contains('filter_alert_listing_match'));
      expect(lower, contains('notification_delivery_events_event_type'));
    });

    test('filter alert dedup partial unique index exists', () {
      expect(lower, contains('notification_delivery_events_filter_alert_dedup_idx'));
    });

    test('message claim path only selects message_created', () {
      expect(lower, contains('claim_notification_events_for_processing'));
      // Two conditions: filter claim uses filter_alert; message claim must scope to message_created.
      expect(lower, contains("ne.event_type = 'message_created'"));
      expect(lower, contains("ne.event_type = 'filter_alert_listing_match'"));
    });

    test('enqueue and trigger paths do not reference HTTP or FCM', () {
      final enq = lower.indexOf(
        'create or replace function public.enqueue_filter_alert_notification_events_for_listing',
      );
      expect(enq, greaterThan(-1));
      final trig = lower.indexOf(
        'create or replace function public.trigger_enqueue_filter_alert_notifications',
        enq,
      );
      expect(trig, greaterThan(enq));
      final enqueueFn = lower.substring(enq, trig);
      expect(enqueueFn, isNot(contains('http://')));
      expect(enqueueFn, isNot(contains('https://')));

      final claim = lower.indexOf(
        'create or replace function public.claim_notification_events_for_processing',
        trig,
      );
      expect(claim, greaterThan(trig));
      final triggerFn = lower.substring(trig, claim);
      expect(triggerFn, isNot(contains('http://')));
      expect(triggerFn, isNot(contains('https://')));
    });

    test('revokes listing matcher and enqueue from anon/authenticated', () {
      expect(lower, contains('listing_matches_saved_discovery_criteria'));
      expect(lower, contains('revoke all on function public.listing_matches_saved_discovery_criteria'));
      expect(lower, contains('enqueue_filter_alert_notification_events_for_listing'));
      expect(lower, contains('revoke all on function public.enqueue_filter_alert_notification_events_for_listing'));
    });

    test('listing triggers for insert and status transition', () {
      expect(lower, contains('listings_enqueue_filter_alert_notifications_ins'));
      expect(lower, contains('listings_enqueue_filter_alert_notifications_upd'));
      expect(lower, contains('after insert on public.listings'));
      expect(lower, contains('after update of status on public.listings'));
      expect(lower, contains('trigger_enqueue_filter_alert_notifications'));
    });

    test('owner exclusion and active gating appear in enqueue selector', () {
      expect(lower, contains('is distinct from r.seller_id'));
      expect(lower, contains("r.status is distinct from 'active'"));
    });

    test('claim_filter_alert_notification_events_for_processing granted to service_role only', () {
      expect(lower, contains('claim_filter_alert_notification_events_for_processing'));
      expect(lower, contains('grant execute on function public.claim_filter_alert_notification_events_for_processing'));
      expect(lower, contains('to service_role'));
    });

    test(
      'listing_matches_saved_discovery_criteria: typeIn uses EXISTS + jsonb_array_elements_text alias, '
      'not invalid PL/pgSQL FOR row loop',
      () {
        final start = lower.indexOf(
          'create or replace function public.listing_matches_saved_discovery_criteria',
        );
        expect(start, greaterThan(-1));
        final end = lower.indexOf(
          'comment on function public.listing_matches_saved_discovery_criteria',
          start,
        );
        expect(end, greaterThan(start));
        final fn = lower.substring(start, end);
        expect(fn, isNot(contains('for v_elem_text in')));
        expect(fn, isNot(contains('select value from jsonb_array_elements_text')));
        expect(fn, contains('jsonb_array_elements_text'));
        expect(fn, contains('exists'));
        expect(fn, contains('as elem(value)'));
      },
    );
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
