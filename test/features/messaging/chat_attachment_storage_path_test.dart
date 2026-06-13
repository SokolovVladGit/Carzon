import 'package:carzon/features/messaging/data/datasources/chat_attachment_remote_datasource.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseChatAttachmentRemoteDataSource.buildStoragePath', () {
    test('uses conversations/<conversation>/<uploader>/<filename>', () {
      final path = SupabaseChatAttachmentRemoteDataSource.buildStoragePath(
        conversationId: 'conv-1',
        uploaderId: 'user-1',
        ext: 'jpg',
        originalFileName: 'photo.jpg',
      );

      expect(path, 'conversations/conv-1/user-1/photo.jpg');
    });

    test('never embeds .. in sanitized filename', () {
      final path = SupabaseChatAttachmentRemoteDataSource.buildStoragePath(
        conversationId: 'conv-1',
        uploaderId: 'user-1',
        ext: 'png',
        originalFileName: '../evil.png',
      );

      expect(path, isNot(contains('..')));
      expect(path, startsWith('conversations/conv-1/user-1/'));
      expect(path, endsWith('.png'));
    });

    test('fallback filename uses mime extension', () {
      final path = SupabaseChatAttachmentRemoteDataSource.buildStoragePath(
        conversationId: 'conv-1',
        uploaderId: 'user-1',
        ext: 'jpg',
      );

      expect(path, startsWith('conversations/conv-1/user-1/'));
      expect(path, endsWith('.jpg'));
      expect(path.split('/').last, isNotEmpty);
    });
  });
}
