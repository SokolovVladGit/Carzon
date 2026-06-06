import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/l10n/app_locale_cubit.dart';
import 'package:carzon/core/l10n/app_locale_local_datasource.dart';
import 'package:carzon/core/l10n/app_locale_preference.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/messaging/domain/entities/chat_message.dart';
import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/pages/conversation_thread_page.dart';
import 'package:carzon/features/messaging/presentation/pages/messages_inbox_page.dart';
import 'package:carzon/features/messaging/presentation/widgets/messages_inbox_conversation_tile.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
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
  final t0 = DateTime.utc(2026, 5, 2, 10);

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

  Conversation sampleConversation() => Conversation(
    id: 'conv-1',
    listingId: 'list-1',
    buyerId: 'u1',
    sellerId: 's1',
    createdAt: t0,
    updatedAt: t0,
    lastMessageAt: t0,
    lastMessagePreview: 'Hi',
    listingTitle: 'BMW 3',
  );

  Widget testedDark(Widget child) {
    return MaterialApp(
      theme: AppTheme.dark(),
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

  testWidgets('messages inbox renders title in dark theme', (tester) async {
    when(
      () => messagingRepo.getConversations(),
    ).thenAnswer((_) async => Success([sampleConversation()]));

    await tester.pumpWidget(testedDark(const MessagesInboxPage()));
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingTitle), findsOneWidget);
    expect(find.byType(MessagesInboxConversationTile), findsOneWidget);
    expect(find.text('BMW 3'), findsOneWidget);
    expect(find.text('Hi'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(MessagesInboxConversationTile),
        matching: find.byType(ClipOval),
      ),
      findsOneWidget,
    );
  });

  testWidgets('conversation thread renders composer in dark theme', (
    tester,
  ) async {
    when(
      () => messagingRepo.getConversation('conv-1'),
    ).thenAnswer((_) async => Success(sampleConversation()));
    when(
      () => messagingRepo.getMessages('conv-1'),
    ).thenAnswer((_) async => const Success<List<ChatMessage>>([]));

    await tester.pumpWidget(
      testedDark(const ConversationThreadPage(conversationId: 'conv-1')),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.messagingComposerHint), findsOneWidget);
    expect(find.text(l10n.messagingThreadEmptyBody), findsOneWidget);
  });
}
