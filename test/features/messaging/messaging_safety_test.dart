import 'package:carzon/app/di/injection.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/domain/entities/blocked_user.dart';
import 'package:carzon/features/messaging/domain/entities/chat_message.dart';
import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/entities/conversation_kind.dart';
import 'package:carzon/features/messaging/domain/entities/user_report_reason.dart';
import 'package:carzon/features/messaging/domain/messaging_failure_kind.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/domain/utils/conversation_peer.dart';
import 'package:carzon/features/messaging/presentation/bloc/blocked_users_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/blocked_users_state.dart';
import 'package:carzon/features/messaging/presentation/bloc/conversation_thread_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/conversation_thread_state.dart';
import 'package:carzon/features/messaging/presentation/pages/blocked_users_page.dart';
import 'package:carzon/features/messaging/presentation/utils/messaging_failure_mapper.dart';
import 'package:carzon/features/messaging/presentation/utils/messaging_user_messages.dart';
import 'package:carzon/features/messaging/presentation/utils/user_report_note_validation.dart';
import 'package:carzon/features/messaging/presentation/widgets/thread_composer_bar.dart';
import 'package:carzon/features/messaging/presentation/widgets/thread_messaging_safety_ui.dart';
import 'package:carzon/features/messaging/presentation/widgets/thread_safety_overflow_menu.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late _MockMessagingRepository repository;
  final l10n = ruStrings();
  final roL10n = roStrings();
  final t0 = DateTime.utc(2026, 7, 14, 12);

  final listingConversation = Conversation(
    id: 'c1',
    listingId: 'l1',
    buyerId: 'u1',
    sellerId: 's1',
    createdAt: t0,
    updatedAt: t0,
  );

  final supportConversation = Conversation(
    id: 'c-support',
    buyerId: 'u1',
    sellerId: 'support-id',
    conversationKind: ConversationKind.support,
    createdAt: t0,
    updatedAt: t0,
  );

  setUp(() {
    repository = _MockMessagingRepository();
    when(
      () => repository.markConversationRead(any()),
    ).thenAnswer((_) async => const Success(true));
    when(
      () => repository.listBlockedUsers(),
    ).thenAnswer((_) async => const Success([]));
  });

  setUpAll(() {
    registerFallbackValue(UserReportReason.spam);
  });

  group('conversationPeerUserId', () {
    test('returns seller when current user is buyer', () {
      expect(conversationPeerUserId(listingConversation, 'u1'), 's1');
    });
  });

  group('messagingFailureKindFrom', () {
    test('maps messaging blocked server message', () {
      expect(
        messagingFailureKindFrom(const ServerFailure('messaging blocked')),
        MessagingFailureKind.messagingBlocked,
      );
    });

    test('maps stable moderation rejection for send and report feedback', () {
      expect(
        messagingFailureKindFrom(
          const ServerFailure(
            'carzon_content_rejected',
            postgrestCode: 'P0001',
          ),
        ),
        MessagingFailureKind.contentRejected,
      );
      expect(
        messagingFailureMessage(
          l10n,
          MessagingFailureKind.contentRejected,
          isSendAction: true,
        ),
        l10n.contentModerationRejected,
      );
    });
  });

  group('messagingFailureMessage', () {
    test('maps messaging blocked to generic send copy RU', () {
      expect(
        messagingFailureMessage(
          l10n,
          MessagingFailureKind.messagingBlocked,
          isSendAction: true,
        ),
        l10n.messagingSafetySendUnavailable,
      );
    });

    test('maps messaging blocked to generic send copy RO', () {
      expect(
        messagingFailureMessage(
          roL10n,
          MessagingFailureKind.messagingBlocked,
          isSendAction: true,
        ),
        roL10n.messagingSafetySendUnavailable,
      );
    });
  });

  group('ConversationThreadCubit safety', () {
    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'blockPeer calls blockUser with conversation id',
      build: () {
        when(
          () => repository.blockUser('c1'),
        ).thenAnswer((_) async => const Success(null));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
          currentUserId: 'u1',
        );
      },
      act: (c) async {
        final ok = await c.blockPeer();
        expect(ok, isTrue);
      },
      expect: () => [
        isA<ConversationThreadState>().having(
          (s) => s.blockActionInProgress,
          'blocking',
          isTrue,
        ),
        isA<ConversationThreadState>()
            .having((s) => s.peerBlockedByMe, 'blocked', isTrue)
            .having((s) => s.blockActionInProgress, 'done', isFalse),
      ],
      verify: (_) {
        verify(() => repository.blockUser('c1')).called(1);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'reportPeer calls reportUser with conversation reason and note',
      build: () {
        when(
          () => repository.reportUser(
            conversationId: 'c1',
            reason: UserReportReason.spam,
            note: 'note',
          ),
        ).thenAnswer((_) async => const Success(null));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
          currentUserId: 'u1',
        );
      },
      act: (c) async {
        final ok = await c.reportPeer(
          reason: UserReportReason.spam,
          note: 'note',
        );
        expect(ok, isTrue);
      },
      verify: (_) {
        verify(
          () => repository.reportUser(
            conversationId: 'c1',
            reason: UserReportReason.spam,
            note: 'note',
          ),
        ).called(1);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'send failure messaging blocked sets messagingUnavailable',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(listingConversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));
        when(() => repository.sendMessage('c1', 'hi')).thenAnswer(
          (_) async => const FailureResult(ServerFailure('messaging blocked')),
        );
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
          currentUserId: 'u1',
        );
      },
      act: (c) async {
        await c.load();
        await c.send('hi');
      },
      expect: () => [
        isA<ConversationThreadState>(),
        isA<ConversationThreadState>(),
        isA<ConversationThreadState>().having(
          (s) => s.sending,
          'sending',
          isTrue,
        ),
        isA<ConversationThreadState>().having(
          (s) => s.messagingUnavailable,
          'unavailable',
          isTrue,
        ),
      ],
    );
  });

  group('BlockedUsersCubit', () {
    blocTest<BlockedUsersCubit, BlockedUsersState>(
      'load success emits users',
      build: () {
        when(() => repository.listBlockedUsers()).thenAnswer(
          (_) async => Success([
            BlockedUser(
              blockedUserId: 'peer-1',
              createdAt: t0,
              displayName: 'Alex',
            ),
          ]),
        );
        return BlockedUsersCubit(repository: repository);
      },
      act: (c) => c.load(),
      expect: () => [
        isA<BlockedUsersState>().having(
          (s) => s.status,
          'loading',
          BlockedUsersStatus.loading,
        ),
        isA<BlockedUsersState>()
            .having((s) => s.status, 'success', BlockedUsersStatus.success)
            .having((s) => s.users.length, 'count', 1),
      ],
    );

    blocTest<BlockedUsersCubit, BlockedUsersState>(
      'unblock removes row on success',
      build: () {
        when(
          () => repository.unblockUser('peer-1'),
        ).thenAnswer((_) async => const Success(true));
        return BlockedUsersCubit(repository: repository);
      },
      seed: () => BlockedUsersState(
        status: BlockedUsersStatus.success,
        users: [BlockedUser(blockedUserId: 'peer-1', createdAt: t0)],
      ),
      act: (c) async {
        final ok = await c.unblock('peer-1');
        expect(ok, isTrue);
      },
      expect: () => [
        isA<BlockedUsersState>().having(
          (s) => s.unblockingUserId,
          'unblocking',
          'peer-1',
        ),
        isA<BlockedUsersState>()
            .having((s) => s.users, 'users', isEmpty)
            .having((s) => s.unblockingUserId, 'done', isNull),
      ],
      verify: (_) {
        verify(() => repository.unblockUser('peer-1')).called(1);
      },
    );
  });

  group('userReportNoteValidation', () {
    test('isUserReportNoteTooLong rejects notes over 1000 chars', () {
      expect(isUserReportNoteTooLong('x' * 1001), isTrue);
      expect(isUserReportNoteTooLong('x' * 1000), isFalse);
      expect(isUserReportNoteTooLong('  hello  '), isFalse);
    });
  });

  group('Thread safety widgets', () {
    testWidgets('listing thread shows overflow menu', (tester) async {
      when(
        () => repository.getConversation('c1'),
      ).thenAnswer((_) async => Success(listingConversation));
      when(
        () => repository.getMessages('c1'),
      ).thenAnswer((_) async => const Success([]));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider(
            create: (_) => ConversationThreadCubit(
              repository: repository,
              conversationId: 'c1',
              currentUserId: 'u1',
            )..load(),
            child: Scaffold(
              appBar: AppBar(actions: const [ThreadSafetyOverflowMenu()]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('thread_safety_overflow_menu')),
        findsOneWidget,
      );
    });

    testWidgets('support thread hides overflow menu', (tester) async {
      when(
        () => repository.getConversation('c-support'),
      ).thenAnswer((_) async => Success(supportConversation));
      when(
        () => repository.getMessages('c-support'),
      ).thenAnswer((_) async => const Success([]));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: BlocProvider(
            create: (_) => ConversationThreadCubit(
              repository: repository,
              conversationId: 'c-support',
              currentUserId: 'u1',
            )..load(),
            child: Scaffold(
              appBar: AppBar(actions: const [ThreadSafetyOverflowMenu()]),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('thread_safety_overflow_menu')),
        findsNothing,
      );
    });

    testWidgets(
      'blocked banner and disabled composer when peer blocked by me',
      (tester) async {
        final cubit = ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
          currentUserId: 'u1',
        );
        addTearDown(cubit.close);
        cubit.emit(
          ConversationThreadState(
            status: ConversationThreadStatus.success,
            conversation: listingConversation,
            peerBlockedByMe: true,
          ),
        );

        final controller = TextEditingController();
        addTearDown(controller.dispose);

        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: BlocProvider.value(
              value: cubit,
              child: Scaffold(
                body: Column(
                  children: [
                    const ThreadBlockedBanner(
                      blockedByMe: true,
                      messagingUnavailable: false,
                    ),
                    ThreadComposerBar(
                      conversationId: 'c1',
                      textController: controller,
                      composerDisabled: true,
                      onSendSucceeded: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(
          find.text(l10n.messagingSafetyBlockedBannerTitle),
          findsOneWidget,
        );
        final field = tester.widget<TextField>(find.byType(TextField));
        expect(field.enabled, isFalse);
      },
    );
  });

  group('BlockedUsersPage', () {
    setUp(() async {
      await sl.reset();
      sl.registerLazySingleton<MessagingRepository>(() => repository);
    });

    tearDown(() async {
      await sl.reset();
    });

    testWidgets('shows empty state', (tester) async {
      when(
        () => repository.listBlockedUsers(),
      ).thenAnswer((_) async => const Success([]));

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const BlockedUsersPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(l10n.messagingSafetyBlockedUsersEmptyTitle),
        findsOneWidget,
      );
    });
  });
}
