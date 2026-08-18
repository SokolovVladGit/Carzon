import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/features/notifications/services/filter_alert_notification_public_copy.dart';
import 'package:carzon/features/notifications/services/filter_alert_notification_tap_payload.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const listingId = 'aaaaaaaa-bbbb-4ccc-a123-aaaaaaaaaaaa';

  group('parseFilterAlertNotificationTapPayload', () {
    test('parses minimal data payload', () {
      final p = parseFilterAlertNotificationTapPayload({
        'type': 'filter_alert',
        'listing_id': listingId,
      });
      expect(p, isNotNull);
      expect(p!.listingId, listingId);
    });

    test('routing ignores legacy extra fields', () {
      final p = parseFilterAlertNotificationTapPayload({
        'type': 'filter_alert',
        'listing_id': listingId,
        'event_id': 'legacy-internal-id',
      });
      expect(p!.listingId, listingId);
    });

    test('rejects wrong type', () {
      expect(
        parseFilterAlertNotificationTapPayload({
          'type': 'message',
          'listing_id': listingId,
        }),
        isNull,
      );
    });

    test('rejects non-uuid listing_id', () {
      expect(
        parseFilterAlertNotificationTapPayload({
          'type': 'filter_alert',
          'listing_id': 'not-uuid',
        }),
        isNull,
      );
    });
  });

  group('parseFilterAlertLocalNotificationPayload', () {
    test('parses fa| prefix', () {
      expect(
        parseFilterAlertLocalNotificationPayload('fa|$listingId'),
        listingId,
      );
    });

    test('rejects bare uuid', () {
      expect(parseFilterAlertLocalNotificationPayload(listingId), isNull);
    });

    test('rejects bad id after prefix', () {
      expect(parseFilterAlertLocalNotificationPayload('fa|x'), isNull);
    });
  });

  test('public copy stays generic (no listing fields)', () {
    const pref = AppLocalePreference.ru;
    expect(FilterAlertNotificationPublicCopy.title(pref), isNot(contains('₽')));
    expect(FilterAlertNotificationPublicCopy.body(pref), isNot(contains('@')));
    expect(
      FilterAlertNotificationPublicCopy.body(pref).toLowerCase(),
      isNot(contains('seller')),
    );
  });
}
