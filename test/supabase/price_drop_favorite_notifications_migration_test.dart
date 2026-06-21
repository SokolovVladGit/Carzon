import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for `20260802120000_price_drop_favorite_notifications.sql`.
void main() {
  group('20260802120000_price_drop_favorite_notifications.sql', () {
    late String sql;
    late String lower;

    setUpAll(() {
      final f = File(
        'supabase/migrations/20260802120000_price_drop_favorite_notifications.sql',
      );
      expect(f.existsSync(), isTrue, reason: 'migration file exists');
      sql = f.readAsStringSync();
      lower = sql.toLowerCase();
    });

    test('adds price_drops_enabled with default false', () {
      expect(lower, contains('price_drops_enabled'));
      expect(lower, contains('default false'));
    });

    test('extends notification_delivery_events event_type', () {
      expect(lower, contains("'price_drop_favorite'"));
      expect(lower, contains('notification_delivery_events_event_type_chk'));
    });

    test('defines enqueue_price_drop_favorite_notification_events', () {
      expect(
        lower,
        contains(
          'create or replace function public.enqueue_price_drop_favorite_notification_events',
        ),
      );
      expect(lower, contains('from public.favorites f'));
      expect(lower, contains('np.price_drops_enabled = true'));
      expect(lower, contains('f.user_id is distinct from p_seller_id'));
      expect(lower, contains("'new_price_eur'"));
    });

    test('enqueue skips non-decrease at function entry', () {
      final fnStart = lower.indexOf(
        'create or replace function public.enqueue_price_drop_favorite_notification_events',
      );
      expect(fnStart, greaterThan(-1));
      final fnBody = lower.substring(fnStart, fnStart + 2200);
      expect(fnBody, contains('p_new_price_eur >= p_old_price_eur'));
    });

    test('dedup partial unique index on recipient listing new price', () {
      expect(
        lower,
        contains('notification_delivery_events_price_drop_dedup_idx'),
      );
      expect(lower, contains("payload->>'new_price_eur'"));
    });

    test('update_my_notification_preferences accepts four booleans', () {
      expect(lower, contains('p_price_drops_enabled'));
      expect(
        lower,
        contains(
          'grant execute on function public.update_my_notification_preferences(boolean, boolean, boolean, boolean)',
        ),
      );
      expect(
        lower,
        contains(
          'drop function if exists public.update_my_notification_preferences(boolean, boolean, boolean)',
        ),
      );
    });

    test(
      'update_listing_details_v2 captures old row and enqueues on decrease',
      () {
        expect(lower, contains('v_old_row'));
        expect(
          lower,
          contains(
            'perform public.enqueue_price_drop_favorite_notification_events',
          ),
        );
        expect(lower, contains('v_old_row.status = \'active\''));
        expect(lower, contains('v_row.status = \'active\''));
        expect(
          lower,
          contains(
            'v_old_row.price_currency is not distinct from v_row.price_currency',
          ),
        );
        expect(lower, contains('v_row.price_eur < v_old_row.price_eur'));
      },
    );

    test('claim RPC is service_role only', () {
      expect(
        lower,
        contains('claim_price_drop_notification_events_for_processing'),
      );
      expect(
        lower,
        contains(
          'grant execute on function public.claim_price_drop_notification_events_for_processing',
        ),
      );
      expect(lower, contains('to service_role'));
      expect(
        lower,
        contains(
          'revoke all on function public.claim_price_drop_notification_events_for_processing',
        ),
      );
      expect(lower, contains('from authenticated'));
    });

    test('cron worker uses Vault and safe skip warning', () {
      expect(
        lower,
        contains('carzon_invoke_process_price_drop_notifications_worker'),
      );
      expect(lower, contains('carzon_process_price_drop_notifications_url'));
      expect(lower, contains('carzon_process_price_drop_notifications_secret'));
      expect(lower, contains('raise warning'));
      expect(lower, contains('carzon_process_price_drop_notifications_1m'));
    });
  });
}
