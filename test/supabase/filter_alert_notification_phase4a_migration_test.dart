import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for Phase 4A filter-alert queue migration, Edge Function, cron, config.
///
/// Does not execute Postgres, Edge, or Firebase.
void main() {
  group('supabase/functions/process-filter-alert-notifications/index.ts', () {
    late String ts;

    setUpAll(() {
      final f = File(
        'supabase/functions/process-filter-alert-notifications/index.ts',
      );
      expect(
        f.existsSync(),
        isTrue,
        reason: 'process-filter-alert-notifications Edge Function exists',
      );
      ts = f.readAsStringSync();
    });

    test('uses internal secret header and documents env secrets', () {
      expect(ts, contains('x-carzon-internal-secret'));
      expect(ts, contains('CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET'));
      expect(ts, contains('SUPABASE_SERVICE_ROLE_KEY'));
      expect(
        ts,
        contains('claim_filter_alert_notification_events_for_processing'),
      );
    });

    test('does not hardcode private keys in source', () {
      expect(ts.toLowerCase(), isNot(contains('begin private key')));
    });

    test('localized copy via shared module and token locale column', () {
      expect(ts, contains('filterAlertNotificationCopyForLocale'));
      expect(ts, contains('../_shared/push_notification_copy.ts'));
      expect(ts, contains('.select("id, token, locale")'));
      expect(ts, contains('title: copy.title'));
      expect(ts, contains('body: copy.body'));
    });

    test('FCM data payload is minimal ids only', () {
      expect(ts.toLowerCase(), isNot(contains('mailto')));
      expect(ts, contains('filterAlertNotificationDataPayload'));
      final shared = File(
        'supabase/functions/_shared/filter_alert_saved_search_validation.ts',
      ).readAsStringSync();
      final start = shared.indexOf('function filterAlertNotificationDataPayload');
      expect(start, greaterThan(-1));
      final block = shared.substring(start);
      expect(block, contains('filter_alert'));
      expect(block, contains('listing_id'));
      expect(block, contains('event_id'));
      expect(block.toLowerCase(), isNot(contains('seller')));
      expect(block.toLowerCase(), isNot(contains('price')));
      expect(block.toLowerCase(), isNot(contains('criteria')));
    });

    test('claims only filter_alert_listing_match via dedicated RPC', () {
      expect(
        ts,
        contains('claim_filter_alert_notification_events_for_processing'),
      );
      expect(ts, isNot(contains('claim_notification_events_for_processing')));
    });

    test('validates saved_searches v2 instead of filter_alert_settings', () {
      expect(ts, contains('.from("saved_searches")'));
      expect(ts, contains('filter_alert_saved_search_validation.ts'));
      expect(ts, contains('recipientHasEnabledSavedSearchWithCriteria'));
      expect(ts, contains('SAVED_SEARCH_DISABLED_OR_MISSING_SKIP_REASON'));
      expect(ts, contains('SAVED_SEARCH_VALIDATION_FAILED'));
      expect(ts, isNot(contains('.from("filter_alert_settings")')));
      expect(ts, isNot(contains('filter_alert_settings_off_or_no_criteria')));
    });

    test('revalidates listing is active before send', () {
      expect(ts, contains('.from("listings")'));
      expect(ts, contains('isListingEligibleForFilterAlertDelivery'));
      expect(ts, contains('LISTING_INACTIVE_OR_MISSING_SKIP_REASON'));
    });

    test('FCM payload helper excludes criteria and saved search fields', () {
      expect(ts, contains('filterAlertNotificationDataPayload'));
      expect(ts, isNot(contains("'criteria'")));
      expect(ts, isNot(contains('saved_search_id')));
      expect(ts.toLowerCase(), isNot(contains('vin_hash')));
    });
  });

  group(
    '20260601120000_filter_alert_notifications_queue_and_cron.sql — scheduler & vault',
    () {
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
        expect(
          lower,
          contains('carzon_invoke_process_filter_alert_notifications_worker'),
        );
      });

      test('posts via pg_net with internal header and Vault secret names', () {
        expect(lower, contains('net.http_post'));
        expect(lower, contains('x-carzon-internal-secret'));
        expect(
          lower,
          contains('carzon_process_filter_alert_notifications_url'),
        );
        expect(
          lower,
          contains('carzon_process_filter_alert_notifications_secret'),
        );
        expect(lower, contains('vault.decrypted_secrets'));
      });

      test(
        'documents process-filter-alert-notifications URL shape in comments only',
        () {
          expect(
            lower,
            contains('functions/v1/process-filter-alert-notifications'),
          );
          expect(
            sql.toUpperCase(),
            isNot(
              contains('CARZON_PROCESS_FILTER_ALERT_NOTIFICATIONS_SECRET='),
            ),
          );
          expect(lower, isNot(contains('begin private key')));
        },
      );

      test(
        'worker revokes client roles and does not grant execute to callers',
        () {
          expect(
            lower,
            contains('carzon_invoke_process_filter_alert_notifications_worker'),
          );
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
        },
      );
    },
  );
}
