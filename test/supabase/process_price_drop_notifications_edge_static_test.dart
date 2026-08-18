import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Static checks for P2 V1 `process-price-drop-notifications` Edge Function.
void main() {
  group('supabase/functions/process-price-drop-notifications/index.ts', () {
    late String ts;

    setUpAll(() {
      final f = File(
        'supabase/functions/process-price-drop-notifications/index.ts',
      );
      expect(f.existsSync(), isTrue);
      ts = f.readAsStringSync();
    });

    test('uses internal secret header and documents env secrets', () {
      expect(ts, contains('x-carzon-internal-secret'));
      expect(ts, contains('CARZON_PROCESS_PRICE_DROP_NOTIFICATIONS_SECRET'));
      expect(ts, contains('SUPABASE_SERVICE_ROLE_KEY'));
      expect(
        ts,
        contains('claim_price_drop_notification_events_for_processing'),
      );
    });

    test('rejects missing secret at handler entry', () {
      expect(ts, contains('unauthorized invoke attempt'));
      expect(ts, contains('jsonResponse(401'));
    });

    test('FCM data payload is minimal ids only', () {
      expect(ts, contains('priceDropNotificationDataPayload'));
      final shared = File(
        'supabase/functions/_shared/price_drop_favorite_validation.ts',
      ).readAsStringSync();
      final start = shared.indexOf('function priceDropNotificationDataPayload');
      expect(start, greaterThan(-1));
      final block = shared.substring(start);
      expect(block, contains('price_drop'));
      expect(block, contains('listing_id'));
      expect(block, isNot(contains('event_id')));
      expect(block.toLowerCase(), isNot(contains('old_price')));
      expect(block.toLowerCase(), isNot(contains('new_price')));
      expect(block.toLowerCase(), isNot(contains('seller')));
      expect(block.toLowerCase(), isNot(contains('vin')));
      expect(block.toLowerCase(), isNot(contains('criteria')));
      expect(block.toLowerCase(), isNot(contains('token')));
    });

    test('validates favorites and preferences at send time', () {
      expect(ts, contains('.from("favorites")'));
      expect(ts, contains('price_drops_enabled'));
      expect(ts, contains('FAVORITE_MISSING_SKIP_REASON'));
    });

    test('localized copy via shared module', () {
      expect(ts, contains('priceDropNotificationCopyForLocale'));
      expect(ts, contains('../_shared/push_notification_copy.ts'));
      expect(ts, isNot(contains('listing_title')));
    });
  });

  group('supabase/functions/_shared/push_notification_copy.ts', () {
    test('defines RU and RO price drop copy', () {
      final shared = File(
        'supabase/functions/_shared/push_notification_copy.ts',
      ).readAsStringSync();
      expect(shared, contains('Снижение цены'));
      expect(shared, contains('Цена на сохранённый автомобиль снизилась.'));
      expect(shared, contains('Reducere de preț'));
      expect(shared, contains('Prețul anunțului salvat a scăzut.'));
      expect(shared, contains('priceDropNotificationCopyForLocale'));
    });
  });
}
