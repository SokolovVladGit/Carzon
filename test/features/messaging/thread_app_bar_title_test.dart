import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/entities/conversation_kind.dart';
import 'package:carzon/features/messaging/presentation/utils/thread_app_bar_title.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();
  final t0 = DateTime.utc(2026, 5, 2, 10);

  test('support conversation uses support title', () {
    final title = threadAppBarTitle(
      Conversation(
        id: 'c1',
        buyerId: 'u1',
        sellerId: 'support',
        createdAt: t0,
        updatedAt: t0,
        conversationKind: ConversationKind.support,
      ),
      'list-1',
      l10n,
    );

    expect(title, l10n.supportConversationTitle);
  });

  test('listing conversation uses make and model headline', () {
    final title = threadAppBarTitle(
      Conversation(
        id: 'c1',
        listingId: 'list-1',
        buyerId: 'u1',
        sellerId: 's1',
        createdAt: t0,
        updatedAt: t0,
        listingMake: 'Volkswagen',
        listingModel: 'Golf',
      ),
      'list-1',
      l10n,
    );

    expect(title, 'Volkswagen Golf');
  });

  test('listing conversation falls back to generic chat without headline', () {
    final title = threadAppBarTitle(
      Conversation(
        id: 'c1',
        listingId: 'list-1',
        buyerId: 'u1',
        sellerId: 's1',
        createdAt: t0,
        updatedAt: t0,
      ),
      'abcdef12',
      l10n,
    );

    expect(title, l10n.messagingThreadTitle);
  });
}
