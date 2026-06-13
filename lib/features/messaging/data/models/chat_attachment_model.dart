import '../../domain/entities/chat_attachment.dart';

class ChatAttachmentModel extends ChatAttachment {
  const ChatAttachmentModel({
    required super.id,
    required super.messageId,
    required super.conversationId,
    required super.storageBucket,
    required super.storagePath,
    required super.mimeType,
    required super.sizeBytes,
    required super.createdAt,
    super.width,
    super.height,
  });

  factory ChatAttachmentModel.fromJson(Map<String, dynamic> json) {
    return ChatAttachmentModel(
      id: json['id'] as String,
      messageId: json['message_id'] as String,
      conversationId: json['conversation_id'] as String,
      storageBucket: json['storage_bucket'] as String,
      storagePath: json['storage_path'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: _asInt(json['size_bytes']),
      width: _asNullableInt(json['width']),
      height: _asNullableInt(json['height']),
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ??
          DateTime.now().toUtc(),
    );
  }

  static int _asInt(dynamic raw) {
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    if (raw is String) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    throw FormatException('Invalid attachment size_bytes: $raw');
  }

  static int? _asNullableInt(dynamic raw) {
    if (raw == null) return null;
    if (raw is int) return raw;
    if (raw is num) return raw.round();
    return null;
  }
}
