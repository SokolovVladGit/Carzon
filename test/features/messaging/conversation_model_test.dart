import 'package:carzon/features/messaging/data/models/conversation_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ConversationModel.fromJson', () {
    test('maps has_unread true/false without mutating listings payload', () {
      final unread = ConversationModel.fromJson({
        'id': 'cid',
        'listing_id': 'lid',
        'buyer_id': 'b',
        'seller_id': 's',
        'created_at': '2026-05-02T12:00:00.000Z',
        'updated_at': '2026-05-02T13:00:00.000Z',
        'last_message_at': '2026-05-02T14:00:00.000Z',
        'last_message_preview': 'Hello',
        'listings': {'title': 'Listed car'},
        'has_unread': true,
      });

      expect(unread.hasUnread, isTrue);

      final readSameJson = ConversationModel.fromJson({
        'id': 'cid',
        'listing_id': 'lid',
        'buyer_id': 'b',
        'seller_id': 's',
        'created_at': '2026-05-02T12:00:00.000Z',
        'updated_at': '2026-05-02T13:00:00.000Z',
        'listings': {'title': 'Listed car'},
        'has_unread': false,
      });

      expect(readSameJson.hasUnread, isFalse);
    });

    test('parses support conversation with null listing_id and kind', () {
      final support = ConversationModel.fromJson({
        'id': 'support-cid',
        'listing_id': null,
        'conversation_kind': 'support',
        'buyer_id': 'b',
        'seller_id': 'support-user',
        'created_at': '2026-07-02T12:00:00.000Z',
        'updated_at': '2026-07-02T12:00:00.000Z',
        'has_unread': false,
      });

      expect(support.isSupportConversation, isTrue);
      expect(support.listingId, isNull);
      expect(support.conversationKind.name, 'support');
    });

    test(
      'defaults hasUnread false when RPC omits has_unread (single-thread fetch)',
      () {
        final legacy = ConversationModel.fromJson({
          'id': 'cid',
          'listing_id': 'lid',
          'buyer_id': 'b',
          'seller_id': 's',
          'created_at': '2026-05-02T12:00:00.000Z',
          'updated_at': '2026-05-02T13:00:00.000Z',
          'listings': <String, dynamic>{},
        });
        expect(legacy.hasUnread, isFalse);
      },
    );
  });
}
