import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/presentation/widgets/messages_inbox_conversation_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final t0 = DateTime.utc(2026, 5, 2, 10);

  Conversation conversation({
    bool hasUnread = false,
    num? price,
    String? city,
    String? coverUrl,
    String listingTitle = 'Volkswagen Golf',
  }) => Conversation(
    id: 'conv-1',
    listingId: 'list-1',
    buyerId: 'u1',
    sellerId: 's1',
    createdAt: t0,
    updatedAt: t0,
    lastMessageAt: t0,
    lastMessagePreview: 'Preview text',
    listingTitle: listingTitle,
    listingCoverImageUrl: coverUrl,
    listingPriceAmount: price,
    listingPriceCurrencyDb: price != null ? 'eur' : null,
    listingCity: city,
    hasUnread: hasUnread,
  );

  Widget wrap(Widget child, {bool dark = false, double maxWidth = 360}) {
    return MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: maxWidth,
            child: child,
          ),
        ),
      ),
    );
  }

  testWidgets('shows headline, preview, and unread dot key when unread', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MessagesInboxConversationTile(
          conversation: conversation(hasUnread: true),
          listingHeadlineFallback: 'Fallback',
          messagePreview: 'Preview text',
          timeText: '2 мая, 10:00',
          onTap: () {},
        ),
      ),
    );

    expect(find.text('Volkswagen Golf'), findsOneWidget);
    expect(find.text('Preview text'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('messages_inbox_unread_dot_conv-1')),
      findsOneWidget,
    );
    final title = tester.widget<Text>(find.text('Volkswagen Golf'));
    expect(title.style?.fontWeight, FontWeight.w700);
    expect(title.maxLines, 1);
  });

  testWidgets('hides unread dot when read', (tester) async {
    await tester.pumpWidget(
      wrap(
        MessagesInboxConversationTile(
          conversation: conversation(hasUnread: false),
          listingHeadlineFallback: 'Fallback',
          messagePreview: 'Preview text',
          timeText: '2 мая, 10:00',
          onTap: () {},
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey<String>('messages_inbox_unread_dot_conv-1')),
      findsNothing,
    );
    final title = tester.widget<Text>(find.text('Volkswagen Golf'));
    expect(title.style?.fontWeight, FontWeight.w600);
  });

  testWidgets('does not show price or city as prominent meta lines', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        MessagesInboxConversationTile(
          conversation: conversation(price: 12500, city: 'Chișinău'),
          listingHeadlineFallback: 'Fallback',
          messagePreview: 'Preview text',
          timeText: null,
          onTap: () {},
        ),
      ),
    );

    expect(find.textContaining('12'), findsNothing);
    expect(find.text('Chișinău'), findsNothing);
    expect(find.text('Preview text'), findsOneWidget);
  });

  testWidgets('long title and preview ellipsize without overflow', (
    tester,
  ) async {
    const longTitle =
        'Volkswagen Golf Performance Line Very Long Vehicle Name';
    const longPreview =
        'This is an intentionally long preview message that should truncate on narrow screens without overflowing the layout bounds';

    await tester.pumpWidget(
      wrap(
        MessagesInboxConversationTile(
          conversation: conversation(
            listingTitle: longTitle,
            hasUnread: true,
          ),
          listingHeadlineFallback: 'Fallback',
          messagePreview: longPreview,
          timeText: '2 мая, 10:00',
          onTap: () {},
        ),
        maxWidth: 320,
      ),
    );

    expect(tester.takeException(), isNull);
    final title = tester.widget<Text>(find.text(longTitle));
    expect(title.overflow, TextOverflow.ellipsis);
    final preview = tester.widget<Text>(find.text(longPreview));
    expect(preview.maxLines, 1);
    expect(preview.overflow, TextOverflow.ellipsis);
  });

  testWidgets('dark theme renders messenger row', (tester) async {
    await tester.pumpWidget(
      wrap(
        MessagesInboxConversationTile(
          conversation: conversation(hasUnread: true),
          listingHeadlineFallback: 'Fallback',
          messagePreview: 'Preview text',
          timeText: '2 мая, 10:00',
          onTap: () {},
        ),
        dark: true,
      ),
    );

    expect(find.byType(MessagesInboxConversationTile), findsOneWidget);
    expect(find.byType(ClipOval), findsOneWidget);
    expect(find.byType(InkWell), findsOneWidget);
  });
}
