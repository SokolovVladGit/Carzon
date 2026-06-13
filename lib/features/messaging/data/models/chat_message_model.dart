import '../../domain/entities/chat_attachment.dart';
import '../../domain/entities/chat_message.dart';
import 'chat_attachment_model.dart';

class ChatMessageModel extends ChatMessage {
  const ChatMessageModel({
    required super.id,
    required super.conversationId,
    required super.senderId,
    required super.body,
    required super.createdAt,
    super.attachments = const [],
  });

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    return ChatMessageModel(
      id: json['id'] as String,
      conversationId: json['conversation_id'] as String,
      senderId: json['sender_id'] as String,
      body: (json['body'] as String?) ?? '',
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
      attachments: _parseAttachments(json['message_attachments']),
    );
  }

  static List<ChatAttachment> _parseAttachments(dynamic raw) {
    if (raw == null) return const [];
    if (raw is Map) {
      return List<ChatAttachment>.unmodifiable([
        ChatAttachmentModel.fromJson(Map<String, dynamic>.from(raw)),
      ]);
    }
    if (raw is! List<dynamic>) return const [];
    final out = <ChatAttachment>[];
    for (final item in raw) {
      if (item is! Map) continue;
      out.add(
        ChatAttachmentModel.fromJson(Map<String, dynamic>.from(item)),
      );
    }
    return List<ChatAttachment>.unmodifiable(out);
  }
}
