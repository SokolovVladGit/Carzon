import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/entities/conversation_kind.dart';
import 'package:carzon/features/messaging/presentation/utils/conversation_display_copy.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();
  final t0 = DateTime.utc(2026, 7, 2);

  Conversation listingConversation() => Conversation(
    id: 'c1',
    listingId: 'l1',
    buyerId: 'b',
    sellerId: 's',
    createdAt: t0,
    updatedAt: t0,
    listingTitle: 'BMW X5',
  );

  Conversation supportConversation() => Conversation(
    id: 'c2',
    buyerId: 'b',
    sellerId: 'support',
    createdAt: t0,
    updatedAt: t0,
    conversationKind: ConversationKind.support,
  );

  test('conversationPrimaryLine uses listing title for listing threads', () {
    expect(
      conversationPrimaryLine(listingConversation(), 'fallback', l10n),
      'BMW X5',
    );
  });

  test('conversationPrimaryLine uses support title for support threads', () {
    expect(
      conversationPrimaryLine(supportConversation(), 'fallback', l10n),
      l10n.supportConversationTitle,
    );
  });

  test('conversationEmptyPreviewLine uses support subtitle for support threads', () {
    expect(
      conversationEmptyPreviewLine(supportConversation(), l10n),
      l10n.contactSupportSubtitle,
    );
  });
}
