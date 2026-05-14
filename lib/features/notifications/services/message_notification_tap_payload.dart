/// Privacy-safe FCM **data** keys for message notifications (see Edge
/// `process-message-notifications` `dataPayload`).
class MessageNotificationTapPayload {
  const MessageNotificationTapPayload({
    required this.conversationId,
    this.messageId,
    this.listingId,
  });

  final String conversationId;
  final String? messageId;
  final String? listingId;
}

final RegExp _uuidV4ish = RegExp(
  r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[1-8][0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
);

bool _isUuid(String value) => _uuidV4ish.hasMatch(value.trim());

/// True when [value] matches the same UUID shape required for message routing.
bool isMessageNotificationConversationId(String value) => _isUuid(value);

String? _optionalUuid(String? raw) {
  if (raw == null) {
    return null;
  }
  final trimmed = raw.trim();
  if (trimmed.isEmpty) {
    return null;
  }
  return _isUuid(trimmed) ? trimmed : null;
}

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

/// Parses FCM data map for a message notification tap. Returns null when the
/// payload is not a recognized message type or [conversationId] is missing or
/// not a UUID.
MessageNotificationTapPayload? parseMessageNotificationTapPayload(
  Map<String, dynamic> data,
) {
  final type = _stringData(data, 'type').trim().toLowerCase();
  if (type.isNotEmpty && type != 'message' && type != 'message_created') {
    return null;
  }
  final conversationId = _stringData(data, 'conversation_id').trim();
  if (!_isUuid(conversationId)) {
    return null;
  }
  final messageIdRaw = _stringData(data, 'message_id').trim();
  final listingIdRaw = _stringData(data, 'listing_id').trim();
  return MessageNotificationTapPayload(
    conversationId: conversationId,
    messageId: messageIdRaw.isEmpty ? null : _optionalUuid(messageIdRaw),
    listingId: listingIdRaw.isEmpty ? null : _optionalUuid(listingIdRaw),
  );
}
