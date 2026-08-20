import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/messaging/domain/entities/chat_attachment.dart';
import 'package:carzon/features/messaging/domain/entities/chat_message.dart';
import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/entities/conversation_kind.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/pages/conversation_thread_page.dart';
import 'package:carzon/features/messaging/presentation/pages/messages_inbox_page.dart';
import 'package:carzon/features/messaging/presentation/widgets/chat_image_message_bubble.dart';
import 'package:carzon/features/messaging/presentation/widgets/chat_message_bubble.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockMessagingRepository extends Mock implements MessagingRepository {}

final class _InMemoryAppLocaleLocalDataSource
    implements AppLocaleLocalDataSource {
  @override
  Future<AppLocalePreference> loadPreference() async => AppLocalePreference.ru;

  @override
  Future<void> savePreference(AppLocalePreference preference) async {}
}

void main() {
  late _MockAuthCubit authCubit;
  late _MockMessagingRepository messagingRepo;
  late AppLocaleCubit appLocaleCubit;
  final l10n = ruStrings();

  const user = AuthUser(id: 'u1', email: 'buyer@test.com');

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() async {
    await sl.reset();
    authCubit = _MockAuthCubit();
    messagingRepo = _MockMessagingRepository();
    appLocaleCubit = AppLocaleCubit(
      localDataSource: _InMemoryAppLocaleLocalDataSource(),
    );
    sl.registerLazySingleton<MessagingRepository>(() => messagingRepo);
    sl.registerLazySingleton<MessagingUnreadSummaryCubit>(
      () => MessagingUnreadSummaryCubit(sl<MessagingRepository>()),
    );

    when(
      () => messagingRepo.markConversationRead(any()),
    ).thenAnswer((_) async => const Success(true));
    when(
      () => messagingRepo.getUnreadConversationCount(),
    ).thenAnswer((_) async => const Success(0));
    when(
      () => messagingRepo.listBlockedUsers(),
    ).thenAnswer((_) async => const Success([]));

    when(() => authCubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  final t0 = DateTime.utc(2026, 5, 2, 10);

  const kTinyPng = <int>[
    0x89,
    0x50,
    0x4E,
    0x47,
    0x0D,
    0x0A,
    0x1A,
    0x0A,
    0x00,
    0x00,
    0x00,
    0x0D,
    0x49,
    0x48,
    0x44,
    0x52,
    0x00,
    0x00,
    0x00,
    0x01,
    0x00,
    0x00,
    0x00,
    0x01,
    0x08,
    0x06,
    0x00,
    0x00,
    0x00,
    0x1F,
    0x15,
    0xC4,
    0x89,
    0x00,
    0x00,
    0x00,
    0x0A,
    0x49,
    0x44,
    0x41,
    0x54,
    0x78,
    0x9C,
    0x63,
    0x00,
    0x01,
    0x00,
    0x00,
    0x05,
    0x00,
    0x01,
    0x0D,
    0x0A,
    0x2D,
    0xB4,
    0x00,
    0x00,
    0x00,
    0x00,
    0x49,
    0x45,
    0x4E,
    0x44,
    0xAE,
    0x42,
    0x60,
    0x82,
  ];

  Conversation sampleConversation({
    String listingTitle = 'Volkswagen Golf',
    bool hasUnread = false,
  }) => Conversation(
    id: 'conv-1',
    listingId: 'list-1',
    buyerId: 'u1',
    sellerId: 's1',
    createdAt: t0,
    updatedAt: t0,
    lastMessageAt: t0,
    lastMessagePreview: 'Last',
    listingTitle: listingTitle,
    hasUnread: hasUnread,
  );

  Conversation sampleSupportConversation() => Conversation(
    id: 'conv-support',
    buyerId: 'u1',
    sellerId: 'support-1',
    createdAt: t0,
    updatedAt: t0,
    conversationKind: ConversationKind.support,
  );

  Widget testedInbox(Widget child) {
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<AppLocaleCubit>.value(value: appLocaleCubit),
        ],
        child: child,
      ),
    );
  }

  Widget testedInboxRouter(GoRouter router) {
    return MaterialApp.router(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
      builder: (context, child) => MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<AppLocaleCubit>.value(value: appLocaleCubit),
        ],
        child: child ?? const SizedBox.shrink(),
      ),
    );
  }

  testWidgets('inbox empty state renders', (tester) async {
    when(
      () => messagingRepo.getConversations(),
    ).thenAnswer((_) async => const Success<List<Conversation>>([]));

    await tester.pumpWidget(testedInbox(const MessagesInboxPage()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingEmptyTitle), findsOneWidget);
    expect(find.text(l10n.messagingEmptyBody), findsOneWidget);
  });

  testWidgets('inbox pull-to-refresh updates list without full-screen error', (
    tester,
  ) async {
    var hits = 0;
    final conv = sampleConversation();
    final conv2 = Conversation(
      id: 'conv-2',
      listingId: 'list-2',
      buyerId: 'u1',
      sellerId: 's2',
      createdAt: t0,
      updatedAt: t0,
      lastMessagePreview: 'New',
      listingTitle: 'BMW 3',
    );
    when(() => messagingRepo.getConversations()).thenAnswer((_) async {
      hits++;
      if (hits == 1) {
        return Success<List<Conversation>>([conv]);
      }
      return Success<List<Conversation>>([conv, conv2]);
    });

    await tester.pumpWidget(testedInbox(const MessagesInboxPage()));
    await tester.pumpAndSettle();

    expect(find.text('Volkswagen Golf'), findsOneWidget);
    expect(hits, 1);

    await tester.fling(
      find.byType(Scrollable).first,
      const Offset(0, 400),
      1000,
    );
    await tester.pumpAndSettle();

    expect(hits, greaterThanOrEqualTo(2));
    expect(find.text('BMW 3'), findsOneWidget);
  });

  testWidgets(
    'visible inbox polls, pauses, resumes immediately, and updates unread',
    (tester) async {
      var hits = 0;
      final initial = sampleConversation();
      final incoming = Conversation(
        id: 'conv-2',
        listingId: 'list-2',
        buyerId: 'u1',
        sellerId: 's2',
        createdAt: t0,
        updatedAt: t0.add(const Duration(minutes: 1)),
        lastMessageAt: t0.add(const Duration(minutes: 1)),
        lastMessagePreview: 'Incoming',
        listingTitle: 'Live BMW',
        hasUnread: true,
      );
      when(() => messagingRepo.getConversations()).thenAnswer((_) async {
        hits++;
        return Success<List<Conversation>>(
          hits == 1 ? [initial] : [incoming, initial],
        );
      });

      await tester.pumpWidget(testedInbox(const MessagesInboxPage()));
      await tester.pumpAndSettle();
      expect(hits, 1);

      await tester.pump(const Duration(seconds: 16));
      await tester.pump();
      expect(hits, 2);
      expect(find.text('Live BMW'), findsOneWidget);
      expect(
        sl<MessagingUnreadSummaryCubit>().state.unreadConversationCount,
        1,
      );

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump(const Duration(seconds: 16));
      expect(hits, 2);

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      await tester.pump();
      expect(hits, 3);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(seconds: 16));
      expect(hits, 3);
    },
  );

  testWidgets('inbox conversation tap navigates to thread route', (
    tester,
  ) async {
    final conv = sampleConversation();
    var inboxHits = 0;
    when(() => messagingRepo.getConversations()).thenAnswer((_) async {
      inboxHits++;
      return Success<List<Conversation>>([conv]);
    });

    final router = GoRouter(
      initialLocation: '/messages',
      routes: [
        GoRoute(
          path: '/messages',
          builder: (context, state) => BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const MessagesInboxPage(),
          ),
        ),
        GoRoute(
          path: '/messages/:conversationId',
          builder: (_, state) => Scaffold(
            body: Text('thread:${state.pathParameters['conversationId']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(testedInboxRouter(router));
    await tester.pumpAndSettle();

    expect(find.text('Volkswagen Golf'), findsOneWidget);
    await tester.tap(find.text('Volkswagen Golf'));
    await tester.pumpAndSettle();

    expect(find.text('thread:conv-1'), findsOneWidget);
    await tester.pump(const Duration(seconds: 16));
    expect(inboxHits, 1);
  });

  testWidgets('thread empty state shows dedicated copy', (tester) async {
    final conv = sampleConversation();
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(
      () => messagingRepo.getMessages('conv-1'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingThreadEmptyBody), findsOneWidget);
    expect(find.text(l10n.messagingQuickReplyHint), findsOneWidget);
    expect(find.text(l10n.messagingQuickReplyStillAvailable), findsOneWidget);
  });

  testWidgets(
    'support thread empty state shows support copy without quick replies',
    (tester) async {
      final conv = sampleSupportConversation();
      when(
        () => messagingRepo.getConversation('conv-support'),
      ).thenAnswer((_) async => Success(conv));
      when(
        () => messagingRepo.getMessages('conv-support'),
      ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

      await tester.pumpWidget(
        testedInbox(
          const ConversationThreadPage(conversationId: 'conv-support'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.messagingSupportThreadEmptyTitle), findsOneWidget);
      expect(find.text(l10n.messagingSupportThreadEmptyBody), findsOneWidget);
      expect(find.text(l10n.messagingThreadEmptyBody), findsNothing);
      expect(find.text(l10n.messagingQuickReplyHint), findsNothing);
      expect(find.text(l10n.messagingQuickReplyStillAvailable), findsNothing);
      expect(find.text(l10n.supportConversationTitle), findsNWidgets(2));
    },
  );

  testWidgets('support thread AppBar shows support title', (tester) async {
    final conv = sampleSupportConversation();
    when(
      () => messagingRepo.getConversation('conv-support'),
    ).thenAnswer((_) async => Success(conv));
    when(
      () => messagingRepo.getMessages('conv-support'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-support')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(l10n.supportConversationTitle),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(l10n.messagingThreadTitle),
      ),
      findsNothing,
    );
  });

  testWidgets('listing thread AppBar shows listing headline', (tester) async {
    final conv = sampleConversation(listingTitle: 'Volkswagen Golf');
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(
      () => messagingRepo.getMessages('conv-1'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text('Volkswagen Golf'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('listing thread AppBar falls back to generic chat title', (
    tester,
  ) async {
    final conv = Conversation(
      id: 'conv-1',
      listingId: 'list-1',
      buyerId: 'u1',
      sellerId: 's1',
      createdAt: t0,
      updatedAt: t0,
    );
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(
      () => messagingRepo.getMessages('conv-1'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: find.byType(AppBar),
        matching: find.text(l10n.messagingThreadTitle),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'grouped incoming and outgoing messages each render a timestamp',
    (tester) async {
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final conv = sampleConversation();
      when(
        () => messagingRepo.getConversation('conv-1'),
      ).thenAnswer((_) async => Success(conv));
      when(() => messagingRepo.getMessages('conv-1')).thenAnswer(
        (_) async => Success<List<ChatMessage>>([
          ChatMessage(
            id: 'm1',
            conversationId: 'conv-1',
            senderId: 'u1',
            body: 'First grouped',
            createdAt: t0,
          ),
          ChatMessage(
            id: 'm2',
            conversationId: 'conv-1',
            senderId: 'u1',
            body: 'Second grouped',
            createdAt: t0.add(const Duration(minutes: 1)),
          ),
          ChatMessage(
            id: 'm3',
            conversationId: 'conv-1',
            senderId: 's1',
            body: 'Reply',
            createdAt: t0.add(const Duration(minutes: 2)),
          ),
          ChatMessage(
            id: 'm4',
            conversationId: 'conv-1',
            senderId: 's1',
            body: 'Second reply',
            createdAt: t0.add(const Duration(minutes: 3)),
          ),
        ]),
      );

      await tester.pumpWidget(
        testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
      );
      await tester.pumpAndSettle();

      expect(find.text('First grouped'), findsOneWidget);
      expect(find.text('Second grouped'), findsOneWidget);
      expect(find.text('Reply'), findsOneWidget);
      expect(find.text('Second reply'), findsOneWidget);
      expect(find.byType(ChatMessageBubble), findsNWidgets(4));
      for (var i = 0; i < 4; i++) {
        final label = DateFormat.Hm(
          'ru',
        ).format(t0.add(Duration(minutes: i)).toLocal());
        expect(find.text(label), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('thread quick reply inserts text and does not send', (
    tester,
  ) async {
    final conv = sampleConversation();
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(
      () => messagingRepo.getMessages('conv-1'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.messagingQuickReplyStillAvailable));
    await tester.pump();

    final field = tester.widget<TextField>(find.byType(TextField));
    expect(field.controller?.text, l10n.messagingQuickReplyStillAvailable);
    verifyNever(() => messagingRepo.sendMessage(any(), any()));
  });

  testWidgets('thread shows date separator for messages on different days', (
    tester,
  ) async {
    final conv = sampleConversation();
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(() => messagingRepo.getMessages('conv-1')).thenAnswer(
      (_) async => Success<List<ChatMessage>>([
        ChatMessage(
          id: 'd1',
          conversationId: 'conv-1',
          senderId: 's1',
          body: 'day one',
          createdAt: DateTime(2025, 5, 1, 12),
        ),
        ChatMessage(
          id: 'd2',
          conversationId: 'conv-1',
          senderId: 's1',
          body: 'day two',
          createdAt: DateTime(2025, 5, 2, 12),
        ),
      ]),
    );

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    final day1 = DateFormat('d MMMM y', 'ru').format(DateTime(2025, 5, 1));
    final day2 = DateFormat('d MMMM y', 'ru').format(DateTime(2025, 5, 2));
    expect(find.text(day1), findsOneWidget);
    expect(find.text(day2), findsOneWidget);
  });

  testWidgets('thread long-press copies message and shows snackbar', (
    tester,
  ) async {
    final conv = sampleConversation();
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(() => messagingRepo.getMessages('conv-1')).thenAnswer(
      (_) async => Success<List<ChatMessage>>([
        ChatMessage(
          id: 'm-in',
          conversationId: 'conv-1',
          senderId: 's1',
          body: 'from seller',
          createdAt: t0,
        ),
      ]),
    );

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    await tester.longPress(find.text('from seller'));
    await tester.pump();
    await tester.pump();

    expect(find.text(l10n.messagingMessageCopied), findsOneWidget);
  });

  testWidgets('thread pull-to-refresh calls repository again', (tester) async {
    final conv = sampleConversation();
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(() => messagingRepo.getMessages('conv-1')).thenAnswer(
      (_) async => Success<List<ChatMessage>>([
        ChatMessage(
          id: 'm-a',
          conversationId: 'conv-1',
          senderId: 's1',
          body: 'first',
          createdAt: t0,
        ),
      ]),
    );

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    await tester.fling(find.byType(ListView), const Offset(0, 400), 1000);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));

    verify(() => messagingRepo.getConversation('conv-1')).called(2);
    verify(() => messagingRepo.getMessages('conv-1')).called(2);
  });

  testWidgets('thread renders bubbles and composer; send disabled when empty', (
    tester,
  ) async {
    final conv = sampleConversation();
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(() => messagingRepo.getMessages('conv-1')).thenAnswer(
      (_) async => Success<List<ChatMessage>>([
        ChatMessage(
          id: 'm-in',
          conversationId: 'conv-1',
          senderId: 's1',
          body: 'from seller',
          createdAt: t0,
        ),
        ChatMessage(
          id: 'm-out',
          conversationId: 'conv-1',
          senderId: 'u1',
          body: 'from buyer',
          createdAt: t0.add(const Duration(minutes: 1)),
        ),
      ]),
    );

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text('from seller'), findsOneWidget);
    expect(find.text('from buyer'), findsOneWidget);

    final sendButton = find.byType(FilledButton);
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), '   ');
    await tester.pump();
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNull);

    await tester.enterText(find.byType(TextField), 'hello');
    await tester.pump();
    expect(tester.widget<FilledButton>(sendButton).onPressed, isNotNull);
  });

  testWidgets('thread renders image bubble for attachment message', (
    tester,
  ) async {
    final conv = sampleConversation();
    final attachment = ChatAttachment(
      id: 'a1',
      messageId: 'm-img',
      conversationId: 'conv-1',
      storageBucket: 'chat-attachments',
      storagePath: 'conversations/conv-1/u1/photo.jpg',
      mimeType: 'image/jpeg',
      sizeBytes: 100,
      createdAt: t0,
    );
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(conv));
    when(() => messagingRepo.getMessages('conv-1')).thenAnswer(
      (_) async => Success<List<ChatMessage>>([
        ChatMessage(
          id: 'm-img',
          conversationId: 'conv-1',
          senderId: 'u1',
          body: '',
          createdAt: t0,
          attachments: [attachment],
        ),
      ]),
    );
    when(
      () => messagingRepo.downloadChatAttachmentBytes(any()),
    ).thenAnswer((_) async => Success(kTinyPng));

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ChatImageMessageBubble), findsOneWidget);
    expect(find.byType(ChatMessageBubble), findsNothing);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('thread polls conversation on a timer while open', (
    tester,
  ) async {
    final conv = sampleConversation();
    var convHits = 0;
    when(() => messagingRepo.getConversation('conv-1')).thenAnswer((_) async {
      convHits++;
      return Success(conv);
    });
    when(
      () => messagingRepo.getMessages('conv-1'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

    await tester.pumpWidget(
      testedInbox(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    expect(convHits, greaterThanOrEqualTo(1));

    await tester.pump(const Duration(seconds: 16));

    expect(convHits, greaterThanOrEqualTo(2));
  });

  group('Inbox unread visibility', () {
    testWidgets('unread conversation shows dot marker and bold listing title', (
      tester,
    ) async {
      final conv = sampleConversation(hasUnread: true);
      when(
        () => messagingRepo.getConversations(),
      ).thenAnswer((_) async => Success<List<Conversation>>([conv]));

      await tester.pumpWidget(testedInbox(const MessagesInboxPage()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('messages_inbox_unread_dot_conv-1')),
        findsOneWidget,
      );
      final title = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Volkswagen Golf'),
      );
      expect(title.style?.fontWeight, FontWeight.w700);
    });

    testWidgets('read conversation hides unread dot and lowers title weight', (
      tester,
    ) async {
      final conv = sampleConversation(hasUnread: false);
      when(
        () => messagingRepo.getConversations(),
      ).thenAnswer((_) async => Success<List<Conversation>>([conv]));

      await tester.pumpWidget(testedInbox(const MessagesInboxPage()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('messages_inbox_unread_dot_conv-1')),
        findsNothing,
      );
      final title = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Volkswagen Golf'),
      );
      expect(title.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('mixed list shows unread dot only on unread thread', (
      tester,
    ) async {
      final read = Conversation(
        id: 'conv-read',
        listingId: 'list-r',
        buyerId: 'u1',
        sellerId: 's1',
        createdAt: t0,
        updatedAt: t0,
        lastMessageAt: t0,
        lastMessagePreview: 'Older',
        listingTitle: 'Quiet Car',
        hasUnread: false,
      );
      final unread = Conversation(
        id: 'conv-unread',
        listingId: 'list-u',
        buyerId: 'u1',
        sellerId: 's2',
        createdAt: t0,
        updatedAt: t0,
        lastMessageAt: t0,
        lastMessagePreview: 'New',
        listingTitle: 'Hot Lead',
        hasUnread: true,
      );
      when(
        () => messagingRepo.getConversations(),
      ).thenAnswer((_) async => Success<List<Conversation>>([unread, read]));

      await tester.pumpWidget(testedInbox(const MessagesInboxPage()));
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('messages_inbox_unread_dot_conv-unread'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('messages_inbox_unread_dot_conv-read'),
        ),
        findsNothing,
      );

      final unreadTitle = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Hot Lead'),
      );
      final readTitle = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Quiet Car'),
      );
      expect(
        unreadTitle.style!.fontWeight!.index,
        greaterThan(readTitle.style!.fontWeight!.index),
      );

      final unreadPreview = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && w.data == 'New'),
      );
      final readPreview = tester.widget<Text>(
        find.byWidgetPredicate((w) => w is Text && w.data == 'Older'),
      );
      expect(unreadPreview.style?.fontWeight, FontWeight.w500);
      expect(readPreview.style?.fontWeight, FontWeight.w400);
      expect(
        unreadPreview.style?.color,
        isNot(equals(readPreview.style?.color)),
      );
    });

    testWidgets(
      'returning from thread triggers silent refresh and clears unread row',
      (tester) async {
        var convFetchPass = 0;
        when(() => messagingRepo.getConversations()).thenAnswer((_) async {
          convFetchPass++;
          if (convFetchPass == 1) {
            return Success<List<Conversation>>([
              sampleConversation(hasUnread: true),
            ]);
          }
          return Success<List<Conversation>>([
            sampleConversation(hasUnread: false),
          ]);
        });

        final conv = sampleConversation(hasUnread: false);
        when(
          () => messagingRepo.getConversation('conv-1'),
        ).thenAnswer((_) async => Success(conv));
        when(
          () => messagingRepo.getMessages('conv-1'),
        ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

        final router = GoRouter(
          initialLocation: '/messages',
          routes: [
            GoRoute(
              path: '/messages',
              builder: (context, state) => BlocProvider<AuthCubit>.value(
                value: authCubit,
                child: const MessagesInboxPage(),
              ),
            ),
            GoRoute(
              path: '/messages/:conversationId',
              builder: (_, state) => BlocProvider<AuthCubit>.value(
                value: authCubit,
                child: ConversationThreadPage(
                  conversationId: state.pathParameters['conversationId']!,
                ),
              ),
            ),
          ],
        );

        await tester.pumpWidget(testedInboxRouter(router));
        await tester.pumpAndSettle();

        expect(
          find.byKey(
            const ValueKey<String>('messages_inbox_unread_dot_conv-1'),
          ),
          findsOneWidget,
        );

        await tester.tap(find.text('Volkswagen Golf'));
        await tester.pumpAndSettle();

        expect(find.byType(ConversationThreadPage), findsOneWidget);

        await tester.tap(
          find.descendant(
            of: find.byType(ConversationThreadPage),
            matching: find.byWidgetPredicate(
              (w) => w is IconButton && w.icon is BackButtonIcon,
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(convFetchPass, greaterThanOrEqualTo(2));
        expect(
          find.byKey(
            const ValueKey<String>('messages_inbox_unread_dot_conv-1'),
          ),
          findsNothing,
        );
        final title = tester.widget<Text>(
          find.byWidgetPredicate(
            (w) => w is Text && w.data == 'Volkswagen Golf',
          ),
        );
        expect(title.style?.fontWeight, FontWeight.w600);
      },
    );
  });
}
