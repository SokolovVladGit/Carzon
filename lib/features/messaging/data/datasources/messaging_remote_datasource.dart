import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/blocked_user_model.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract interface class MessagingRemoteDataSource {
  Future<String> getOrCreateConversation(String listingId);

  Future<String> getOrCreateSupportConversation();

  Future<List<ConversationModel>> fetchConversations();

  Future<ConversationModel> fetchConversation(String conversationId);

  Future<List<ChatMessageModel>> fetchMessages(String conversationId);

  Future<String> sendMessage(String conversationId, String body);

  Future<String> sendMessageWithAttachment({
    required String conversationId,
    required String storagePath,
    required String mimeType,
    required int sizeBytes,
    String? caption,
    int? width,
    int? height,
  });

  Future<void> markConversationReadRpc(String conversationId);

  Future<int> fetchUnreadConversationCountRpc();

  Future<void> blockUserRpc(String conversationId);

  Future<void> reportUserRpc({
    required String conversationId,
    required String reason,
    String? note,
  });

  Future<List<BlockedUserModel>> fetchBlockedUsersRpc();

  Future<bool> unblockUserRpc(String blockedUserId);
}

class SupabaseMessagingRemoteDataSource implements MessagingRemoteDataSource {
  SupabaseMessagingRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const _convSelect =
      'id, listing_id, conversation_kind, buyer_id, seller_id, created_at, '
      'updated_at, last_message_at, last_message_preview, '
      'listings(id, title, make, model, city, cover_image_url, price_eur, price_currency)';

  static const _messagesSelect =
      'id, conversation_id, sender_id, body, created_at, '
      'message_attachments(id, message_id, conversation_id, storage_bucket, '
      'storage_path, mime_type, size_bytes, width, height, created_at)';

  static String _asConversationId(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    throw ServerException(
      'Unexpected response from get_or_create_conversation',
    );
  }

  static String _asMessageId(dynamic raw) {
    if (raw is String && raw.isNotEmpty) return raw;
    throw ServerException('Unexpected response from send_message');
  }

  @override
  Future<String> getOrCreateConversation(String listingId) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        'get_or_create_conversation',
        params: {'p_listing_id': listingId},
      );
      return _asConversationId(data);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to open conversation',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<String> getOrCreateSupportConversation() async {
    try {
      final dynamic data = await _supabase.client.rpc(
        'get_or_create_support_conversation',
      );
      return _asConversationId(data);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to open support conversation',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<ConversationModel>> fetchConversations() async {
    try {
      final dynamic raw = await _supabase.client.rpc(
        'list_inbox_conversations',
      );
      if (raw == null) return const [];
      if (raw is! List<dynamic>) {
        throw ServerException('Unexpected inbox response');
      }
      return raw
          .map<ConversationModel>(
            (row) => ConversationModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load conversations',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<ConversationModel> fetchConversation(String conversationId) async {
    try {
      final row = await _supabase.client
          .from('conversations')
          .select(_convSelect)
          .eq('id', conversationId)
          .maybeSingle();
      if (row == null) {
        throw ServerException('Conversation not found');
      }
      return ConversationModel.fromJson(Map<String, dynamic>.from(row));
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to load conversation',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<ChatMessageModel>> fetchMessages(String conversationId) async {
    try {
      final rows = await _supabase.client
          .from('messages')
          .select(_messagesSelect)
          .eq('conversation_id', conversationId)
          .order('created_at', ascending: true);
      return rows
          .map<ChatMessageModel>(
            (row) => ChatMessageModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to load messages',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<String> sendMessage(String conversationId, String body) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        'send_message',
        params: {'p_conversation_id': conversationId, 'p_body': body},
      );
      return _asMessageId(data);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to send message', cause: e, stackTrace: st);
    }
  }

  @override
  Future<String> sendMessageWithAttachment({
    required String conversationId,
    required String storagePath,
    required String mimeType,
    required int sizeBytes,
    String? caption,
    int? width,
    int? height,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_conversation_id': conversationId,
        'p_storage_path': storagePath,
        'p_mime_type': mimeType,
        'p_size_bytes': sizeBytes,
      };
      final trimmedCaption = caption?.trim();
      if (trimmedCaption != null && trimmedCaption.isNotEmpty) {
        params['p_body'] = trimmedCaption;
      }
      if (width != null) params['p_width'] = width;
      if (height != null) params['p_height'] = height;

      final dynamic data = await _supabase.client.rpc(
        'send_message_with_attachment',
        params: params,
      );
      return _asMessageId(data);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to send attachment message',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> markConversationReadRpc(String conversationId) async {
    try {
      await _supabase.client.rpc(
        'mark_conversation_read',
        params: {'p_conversation_id': conversationId},
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to update read state',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<int> fetchUnreadConversationCountRpc() async {
    try {
      final dynamic raw = await _supabase.client.rpc(
        'get_unread_conversation_count',
      );
      if (raw == null) return 0;
      if (raw is int) return raw;
      if (raw is num) return raw.round();
      throw ServerException('Unexpected unread count response');
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to load unread counts',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> blockUserRpc(String conversationId) async {
    try {
      await _supabase.client.rpc(
        'block_user',
        params: {'p_conversation_id': conversationId},
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to block user', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> reportUserRpc({
    required String conversationId,
    required String reason,
    String? note,
  }) async {
    try {
      final params = <String, dynamic>{
        'p_conversation_id': conversationId,
        'p_reason': reason,
      };
      if (note != null) {
        params['p_note'] = note;
      }
      await _supabase.client.rpc('report_user', params: params);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to submit report',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<BlockedUserModel>> fetchBlockedUsersRpc() async {
    try {
      final dynamic raw = await _supabase.client.rpc('list_blocked_users');
      if (raw == null) return const [];
      if (raw is! List<dynamic>) {
        throw ServerException('Unexpected blocked users response');
      }
      return raw
          .map<BlockedUserModel>(
            (row) => BlockedUserModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException(
        'Failed to load blocked users',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<bool> unblockUserRpc(String blockedUserId) async {
    try {
      final dynamic raw = await _supabase.client.rpc(
        'unblock_user',
        params: {'p_blocked_user_id': blockedUserId},
      );
      if (raw is bool) return raw;
      return false;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      if (e is ServerException) rethrow;
      throw ServerException('Failed to unblock user', cause: e, stackTrace: st);
    }
  }
}
