import '../../../../core/utils/result.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';

/// Contract for buyer–seller messaging (Supabase implementation in data layer).
abstract class MessagingRepository {
  /// RPC `get_or_create_conversation` — returns conversation id.
  Future<Result<String>> getOrCreateConversation(String listingId);

  /// RLS-scoped listing of threads for the current user, newest activity first.
  Future<Result<List<Conversation>>> getConversations();

  /// Loads one conversation (and listing title when join succeeds).
  Future<Result<Conversation>> getConversation(String conversationId);

  /// Chronological messages for a thread.
  Future<Result<List<ChatMessage>>> getMessages(String conversationId);

  /// RPC `send_message` — returns new message id.
  Future<Result<String>> sendMessage(String conversationId, String body);
}
