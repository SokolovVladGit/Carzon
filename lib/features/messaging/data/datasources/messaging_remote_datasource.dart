import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

abstract interface class MessagingRemoteDataSource {
  Future<String> getOrCreateConversation(String listingId);

  Future<List<ConversationModel>> fetchConversations();

  Future<ConversationModel> fetchConversation(String conversationId);

  Future<List<ChatMessageModel>> fetchMessages(String conversationId);

  Future<String> sendMessage(String conversationId, String body);
}

class SupabaseMessagingRemoteDataSource implements MessagingRemoteDataSource {
  SupabaseMessagingRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const _convSelect =
      'id, listing_id, buyer_id, seller_id, created_at, '
      'updated_at, last_message_at, last_message_preview, '
      'listings(id, title, make, model, city, cover_image_url, price_eur, price_currency)';

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
  Future<List<ConversationModel>> fetchConversations() async {
    try {
      final rows = await _supabase.client
          .from('conversations')
          .select(_convSelect)
          .order('updated_at', ascending: false);
      return rows
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
          .select()
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
}
