import '../../../../core/utils/result.dart';
import '../entities/blocked_user.dart';
import '../entities/chat_attachment_upload.dart';
import '../entities/chat_message.dart';
import '../entities/conversation.dart';
import '../entities/user_report_reason.dart';

/// Contract for buyer–seller messaging (Supabase implementation in data layer).
abstract class MessagingRepository {
  /// RPC `get_or_create_conversation` — returns conversation id.
  Future<Result<String>> getOrCreateConversation(String listingId);

  /// RPC `get_or_create_support_conversation` — returns conversation id.
  Future<Result<String>> getOrCreateSupportConversation();

  /// RLS-scoped listing of threads for the current user, newest activity first.
  Future<Result<List<Conversation>>> getConversations();

  /// Loads one conversation (and listing title when join succeeds).
  Future<Result<Conversation>> getConversation(String conversationId);

  /// Chronological messages for a thread.
  Future<Result<List<ChatMessage>>> getMessages(String conversationId);

  /// Sends a participant message ([body] already validated upstream).
  Future<Result<String>> sendMessage(String conversationId, String body);

  /// Uploads a private chat image and commits via `send_message_with_attachment`.
  Future<Result<String>> sendMessageWithAttachment(ChatAttachmentUpload upload);

  /// Authenticated download of a private attachment object (for future UI).
  Future<Result<List<int>>> downloadChatAttachmentBytes(String storagePath);

  /// Participant marks the thread read (RPC-only).
  Future<Result<bool>> markConversationRead(String conversationId);

  /// Distinct participant conversations having inbound unread messages since last_read.
  Future<Result<int>> getUnreadConversationCount();

  /// RPC `block_user` — peer derived server-side from [conversationId].
  Future<Result<void>> blockUser(String conversationId);

  /// RPC `report_user` — reported peer derived server-side.
  Future<Result<void>> reportUser({
    required String conversationId,
    required UserReportReason reason,
    String? note,
  });

  /// RPC `list_blocked_users` — safe public display fields only.
  Future<Result<List<BlockedUser>>> listBlockedUsers();

  /// RPC `unblock_user` — scoped to auth.uid().
  Future<Result<bool>> unblockUser(String blockedUserId);
}
