final RegExp _priceDropUuidV4ish = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool _isListingUuid(String value) => _priceDropUuidV4ish.hasMatch(value.trim());

String _stringData(Map<String, dynamic> data, String key) {
  final value = data[key];
  if (value == null) {
    return '';
  }
  if (value is String) {
    return value;
  }
  return value.toString();
}

/// Privacy-safe FCM **data** keys for price-drop pushes (Edge `dataPayload`).
class PriceDropNotificationTapPayload {
  const PriceDropNotificationTapPayload({
    required this.listingId,
    this.eventId,
  });

  final String listingId;
  final String? eventId;
}

/// Parses FCM data for `type=price_drop`. Returns null if malformed.
PriceDropNotificationTapPayload? parsePriceDropNotificationTapPayload(
  Map<String, dynamic> data,
) {
  final type = _stringData(data, 'type').trim().toLowerCase();
  if (type != 'price_drop') {
    return null;
  }
  final listingRaw = _stringData(data, 'listing_id').trim();
  if (!_isListingUuid(listingRaw)) {
    return null;
  }
  final eventRaw = _stringData(data, 'event_id').trim();
  return PriceDropNotificationTapPayload(
    listingId: listingRaw,
    eventId: eventRaw.isEmpty || !_isListingUuid(eventRaw) ? null : eventRaw,
  );
}

/// Prefix for [flutter_local_notifications] tap payload for price drops.
const String kPriceDropLocalNotificationPayloadPrefix = 'pd|';

String priceDropLocalNotificationPayload(String listingId) =>
    '$kPriceDropLocalNotificationPayloadPrefix$listingId';

String? parsePriceDropLocalNotificationPayload(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final trimmed = raw.trim();
  if (!trimmed.startsWith(kPriceDropLocalNotificationPayloadPrefix)) {
    return null;
  }
  final id = trimmed
      .substring(kPriceDropLocalNotificationPayloadPrefix.length)
      .trim();
  return _isListingUuid(id) ? id : null;
}
