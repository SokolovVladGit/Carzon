import 'package:equatable/equatable.dart';

/// Single text message in a conversation.
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String conversationId;
  final String senderId;
  final String body;
  final DateTime createdAt;

  @override
  List<Object?> get props => [id, conversationId, senderId, body, createdAt];
}
