/// Keys used in Phase 3A FCM **data** payloads for inbound chat (`type: message`).
///
/// Values are always strings on the FCM data channel. Tap routing is deferred;
/// the Edge worker builds the same key names server-side.
abstract final class MessageNotificationPushDataKeys {
  static const String type = 'type';
  static const String messageTypeValue = 'message';
  static const String conversationId = 'conversation_id';
  static const String messageId = 'message_id';
  static const String listingId = 'listing_id';
}
