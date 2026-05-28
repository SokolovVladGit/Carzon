final RegExp _filterUuidV4ish = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool _isListingUuid(String value) => _filterUuidV4ish.hasMatch(value.trim());

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

/// Privacy-safe FCM **data** keys for filter-alert pushes (Edge `dataPayload`).
class FilterAlertNotificationTapPayload {
  const FilterAlertNotificationTapPayload({
    required this.listingId,
    this.eventId,
  });

  final String listingId;
  final String? eventId;
}

/// Parses FCM data for `type=filter_alert`. Returns null if malformed.
FilterAlertNotificationTapPayload? parseFilterAlertNotificationTapPayload(
  Map<String, dynamic> data,
) {
  final type = _stringData(data, 'type').trim().toLowerCase();
  if (type != 'filter_alert') {
    return null;
  }
  final listingRaw = _stringData(data, 'listing_id').trim();
  if (!_isListingUuid(listingRaw)) {
    return null;
  }
  final eventRaw = _stringData(data, 'event_id').trim();
  return FilterAlertNotificationTapPayload(
    listingId: listingRaw,
    eventId: eventRaw.isEmpty || !_isListingUuid(eventRaw) ? null : eventRaw,
  );
}

/// Prefix for [flutter_local_notifications] tap payload for filter alerts (not a bare UUID).
const String kFilterAlertLocalNotificationPayloadPrefix = 'fa|';

String filterAlertLocalNotificationPayload(String listingId) =>
    '$kFilterAlertLocalNotificationPayloadPrefix$listingId';

String? parseFilterAlertLocalNotificationPayload(String? raw) {
  if (raw == null || raw.isEmpty) {
    return null;
  }
  final trimmed = raw.trim();
  if (!trimmed.startsWith(kFilterAlertLocalNotificationPayloadPrefix)) {
    return null;
  }
  final id = trimmed
      .substring(kFilterAlertLocalNotificationPayloadPrefix.length)
      .trim();
  return _isListingUuid(id) ? id : null;
}
