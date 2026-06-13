import 'package:equatable/equatable.dart';

/// Metadata for one image attached to a chat message (MVP: one per message).
class ChatAttachment extends Equatable {
  const ChatAttachment({
    required this.id,
    required this.messageId,
    required this.conversationId,
    required this.storageBucket,
    required this.storagePath,
    required this.mimeType,
    required this.sizeBytes,
    required this.createdAt,
    this.width,
    this.height,
  });

  final String id;
  final String messageId;
  final String conversationId;
  final String storageBucket;
  final String storagePath;
  final String mimeType;
  final int sizeBytes;
  final int? width;
  final int? height;
  final DateTime createdAt;

  @override
  List<Object?> get props => [
    id,
    messageId,
    conversationId,
    storageBucket,
    storagePath,
    mimeType,
    sizeBytes,
    width,
    height,
    createdAt,
  ];
}
