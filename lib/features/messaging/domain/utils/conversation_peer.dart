import '../entities/conversation.dart';

/// Other participant in a two-party conversation, or null if [currentUserId]
/// is not buyer/seller.
String? conversationPeerUserId(
  Conversation conversation,
  String currentUserId,
) {
  if (currentUserId == conversation.buyerId) return conversation.sellerId;
  if (currentUserId == conversation.sellerId) return conversation.buyerId;
  return null;
}
