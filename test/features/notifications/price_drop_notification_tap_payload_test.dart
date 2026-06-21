import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/features/notifications/services/price_drop_notification_public_copy.dart';
import 'package:carzon/features/notifications/services/price_drop_notification_tap_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const listingId = 'aaaaaaaa-bbbb-4ccc-a123-aaaaaaaaaaaa';
  const eventId = 'bbbbbbbb-bbbb-4ccc-b456-bbbbbbbbbbbb';

  group('parsePriceDropNotificationTapPayload', () {
    test('parses minimal data payload', () {
      final p = parsePriceDropNotificationTapPayload({
        'type': 'price_drop',
        'listing_id': listingId,
      });
      expect(p, isNotNull);
      expect(p!.listingId, listingId);
      expect(p.eventId, isNull);
    });

    test('parses optional event_id when uuid', () {
      final p = parsePriceDropNotificationTapPayload({
        'type': 'price_drop',
        'listing_id': listingId,
        'event_id': eventId,
      });
      expect(p!.eventId, eventId);
    });

    test('rejects wrong type', () {
      expect(
        parsePriceDropNotificationTapPayload({
          'type': 'filter_alert',
          'listing_id': listingId,
        }),
        isNull,
      );
    });

    test('rejects non-uuid listing_id', () {
      expect(
        parsePriceDropNotificationTapPayload({
          'type': 'price_drop',
          'listing_id': 'not-uuid',
        }),
        isNull,
      );
    });
  });

  group('parsePriceDropLocalNotificationPayload', () {
    test('parses pd| prefix', () {
      expect(
        parsePriceDropLocalNotificationPayload('pd|$listingId'),
        listingId,
      );
    });

    test('rejects bare uuid', () {
      expect(parsePriceDropLocalNotificationPayload(listingId), isNull);
    });
  });

  test('public copy stays generic (no listing fields)', () {
    const pref = AppLocalePreference.ru;
    expect(PriceDropNotificationPublicCopy.title(pref), isNot(contains('€')));
    expect(PriceDropNotificationPublicCopy.body(pref), isNot(contains('@')));
    expect(PriceDropNotificationPublicCopy.title(pref), 'Снижение цены');
  });
}
