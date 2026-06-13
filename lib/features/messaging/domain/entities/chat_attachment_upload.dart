import 'dart:typed_data';

import 'package:equatable/equatable.dart';

/// Backend-agnostic chat image upload payload (no Supabase / picker types).
class ChatAttachmentUpload extends Equatable {
  const ChatAttachmentUpload({
    required this.conversationId,
    required this.bytes,
    required this.mimeType,
    this.caption,
    this.width,
    this.height,
    this.filename,
  });

  final String conversationId;
  final Uint8List bytes;
  final String mimeType;

  /// Optional caption stored in `messages.body` when non-empty after trim.
  final String? caption;
  final int? width;
  final int? height;

  /// Weak hint for object name only; never trusted verbatim for security.
  final String? filename;

  int get sizeBytes => bytes.length;

  @override
  List<Object?> get props => [
    conversationId,
    bytes.length,
    mimeType,
    caption,
    width,
    height,
    filename,
  ];
}
