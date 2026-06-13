import 'package:carzon/features/messaging/data/models/chat_message_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ChatMessageModel.fromJson', () {
    test('parses text-only message as before', () {
      final message = ChatMessageModel.fromJson({
        'id': 'm1',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'body': 'Hello',
        'created_at': '2026-07-03T12:00:00.000Z',
      });

      expect(message.id, 'm1');
      expect(message.body, 'Hello');
      expect(message.attachments, isEmpty);
    });

    test('handles null body without crashing', () {
      final message = ChatMessageModel.fromJson({
        'id': 'm2',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'body': null,
        'created_at': '2026-07-03T12:00:00.000Z',
      });

      expect(message.body, '');
      expect(message.attachments, isEmpty);
    });

    test('parses one nested attachment row', () {
      final message = ChatMessageModel.fromJson({
        'id': 'm3',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'body': null,
        'created_at': '2026-07-03T12:00:00.000Z',
        'message_attachments': [
          {
            'id': 'a1',
            'message_id': 'm3',
            'conversation_id': 'c1',
            'storage_bucket': 'chat-attachments',
            'storage_path':
                'conversations/c1111111-1111-1111-1111-111111111111/'
                'u2222222-2222-2222-2222-222222222222/photo.jpg',
            'mime_type': 'image/jpeg',
            'size_bytes': 1234,
            'width': 800,
            'height': 600,
            'created_at': '2026-07-03T12:00:01.000Z',
          },
        ],
      });

      expect(message.body, '');
      expect(message.attachments, hasLength(1));
      expect(message.attachments.first.mimeType, 'image/jpeg');
      expect(message.attachments.first.sizeBytes, 1234);
      expect(message.attachments.first.storagePath, contains('photo.jpg'));
    });

    test('parses one-to-one PostgREST embed as object not array', () {
      final message = ChatMessageModel.fromJson({
        'id': 'm3',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'body': null,
        'created_at': '2026-07-03T12:00:00.000Z',
        'message_attachments': {
          'id': 'a1',
          'message_id': 'm3',
          'conversation_id': 'c1',
          'storage_bucket': 'chat-attachments',
          'storage_path':
              'conversations/c1111111-1111-1111-1111-111111111111/'
              'u2222222-2222-2222-2222-222222222222/photo.jpg',
          'mime_type': 'image/jpeg',
          'size_bytes': '1234',
          'width': null,
          'height': null,
          'created_at': '2026-07-03T12:00:01.000Z',
        },
      });

      expect(message.hasAttachments, isTrue);
      expect(message.attachments, hasLength(1));
      expect(message.attachments.first.sizeBytes, 1234);
    });

    test('ignores invalid attachment payload shape', () {
      final message = ChatMessageModel.fromJson({
        'id': 'm4',
        'conversation_id': 'c1',
        'sender_id': 'u1',
        'body': 'Hi',
        'created_at': '2026-07-03T12:00:00.000Z',
        'message_attachments': 'not-a-list',
      });

      expect(message.attachments, isEmpty);
    });
  });
}
