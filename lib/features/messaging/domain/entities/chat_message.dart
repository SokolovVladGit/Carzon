import 'package:equatable/equatable.dart';

import 'chat_attachment.dart';

/// Single message in a conversation (text caption and/or image attachment).
class ChatMessage extends Equatable {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.body,
    required this.createdAt,
    this.attachments = const [],
  });

  final String id;
  final String conversationId;
  final String senderId;

  /// Caption text; empty when image-only or legacy rows with null body.
  final String body;
  final DateTime createdAt;
  final List<ChatAttachment> attachments;

  bool get hasAttachments => attachments.isNotEmpty;

  @override
  List<Object?> get props => [
    id,
    conversationId,
    senderId,
    body,
    createdAt,
    attachments,
  ];
}
