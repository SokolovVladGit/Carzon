/// Server-aligned limits for chat image attachments (MVP).
abstract final class ChatAttachmentLimits {
  /// 10 * 1024 * 1024 — matches hosted `chat-attachments` bucket + RPC cap.
  static const int maxBytes = 10485760;

  static const List<String> allowedMimeTypes = ['image/jpeg', 'image/png'];

  static const String storageBucket = 'chat-attachments';
}
