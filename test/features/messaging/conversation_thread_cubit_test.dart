import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/domain/entities/chat_message.dart';
import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/messaging_failure_kind.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/conversation_thread_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/conversation_thread_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late _MockMessagingRepository repository;

  final t0 = DateTime.utc(2026, 5, 1, 12);
  final conversation = Conversation(
    id: 'c1',
    listingId: 'l1',
    buyerId: 'b1',
    sellerId: 's1',
    createdAt: t0,
    updatedAt: t0,
  );

  final message = ChatMessage(
    id: 'm1',
    conversationId: 'c1',
    senderId: 'b1',
    body: 'Hello',
    createdAt: t0,
  );

  final message2 = ChatMessage(
    id: 'm2',
    conversationId: 'c1',
    senderId: 's1',
    body: 'Hi',
    createdAt: t0.add(const Duration(hours: 1)),
  );

  setUp(() {
    repository = _MockMessagingRepository();
    when(
      () => repository.markConversationRead(any()),
    ).thenAnswer((_) async => const Success(true));
  });

  setUpAll(() {
    registerFallbackValue('');
  });

  group('ConversationThreadCubit', () {
    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'load success emits messages',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) => c.load(),
      expect: () => [
        isA<ConversationThreadState>().having(
          (s) => s.status,
          'status',
          ConversationThreadStatus.loading,
        ),
        isA<ConversationThreadState>()
            .having((s) => s.status, 'status', ConversationThreadStatus.success)
            .having((s) => s.messages, 'messages', [message]),
      ],
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'load success marks conversation read',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) => c.load(),
      wait: const Duration(milliseconds: 50),
      verify: (_) {
        verify(() => repository.markConversationRead('c1')).called(1);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'send trims body',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        when(
          () => repository.sendMessage('c1', 'x'),
        ).thenAnswer((_) async => const Success<String>('m2'));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        await c.send('  x  ');
      },
      verify: (_) {
        verify(() => repository.sendMessage('c1', 'x')).called(1);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'send does not call repository for whitespace-only body',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        await c.send('  \n  ');
      },
      verify: (_) {
        verifyNever(() => repository.sendMessage(any(), any()));
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'send success triggers reload',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        when(
          () => repository.sendMessage('c1', 'hi'),
        ).thenAnswer((_) async => const Success<String>('m2'));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        await c.send('hi');
      },
      verify: (_) {
        verify(() => repository.getConversation('c1')).called(2);
        verify(() => repository.getMessages('c1')).called(2);
        verify(() => repository.sendMessage('c1', 'hi')).called(1);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'refresh reloads conversation and messages',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        when(() => repository.getMessages('c1')).thenAnswer(
          (_) async => Success<List<ChatMessage>>([message, message2]),
        );
        await c.refresh();
      },
      verify: (c) {
        verify(() => repository.getConversation('c1')).called(2);
        verify(() => repository.getMessages('c1')).called(2);
        expect(c.state.messages, [message, message2]);
        expect(c.state.refreshFailureKind, isNull);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'refresh message failure sets refreshFailureKind and preserves messages',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        when(() => repository.getMessages('c1')).thenAnswer(
          (_) async =>
              const FailureResult<List<ChatMessage>>(ServerFailure('offline')),
        );
        await c.refresh();
      },
      verify: (c) {
        expect(c.state.status, ConversationThreadStatus.success);
        expect(c.state.messages, [message]);
        expect(c.state.refreshFailureKind, MessagingFailureKind.serverRejected);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'send failure exposes typed failure kind',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        when(() => repository.sendMessage('c1', any())).thenAnswer(
          (_) async => const FailureResult<String>(
            ServerFailure('message body is too long'),
          ),
        );
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        await c.send('nope');
      },
      verify: (c) {
        expect(
          c.state.lastSendFailureKind,
          MessagingFailureKind.messageValidation,
        );
        expect(c.state.sending, isFalse);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'silentRefresh success updates conversation and messages without loading',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        when(() => repository.getMessages('c1')).thenAnswer(
          (_) async => Success<List<ChatMessage>>([message, message2]),
        );
        await c.silentRefresh();
      },
      verify: (c) {
        expect(c.state.status, ConversationThreadStatus.success);
        expect(c.state.messages, [message, message2]);
        expect(c.state.refreshFailureKind, isNull);
      },
    );

    blocTest<ConversationThreadCubit, ConversationThreadState>(
      'silentRefresh failure leaves state and does not set refreshFailureKind',
      build: () {
        when(
          () => repository.getConversation('c1'),
        ).thenAnswer((_) async => Success(conversation));
        when(
          () => repository.getMessages('c1'),
        ).thenAnswer((_) async => Success<List<ChatMessage>>([message]));
        return ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
      },
      act: (c) async {
        await c.load();
        when(() => repository.getConversation('c1')).thenAnswer(
          (_) async =>
              const FailureResult<Conversation>(ServerFailure('offline')),
        );
        await c.silentRefresh();
      },
      verify: (c) {
        expect(c.state.status, ConversationThreadStatus.success);
        expect(c.state.messages, [message]);
        expect(c.state.refreshFailureKind, isNull);
      },
    );

    test(
      'silentRefresh skips while another silentRefresh awaits network',
      () async {
        final gate = Completer<void>();
        var convCalls = 0;
        var msgCalls = 0;

        when(() => repository.getConversation('c1')).thenAnswer((_) async {
          convCalls++;
          if (convCalls == 2) await gate.future;
          return Success(conversation);
        });
        when(() => repository.getMessages('c1')).thenAnswer((_) async {
          msgCalls++;
          if (msgCalls == 1) {
            return Success<List<ChatMessage>>([message]);
          }
          return Success<List<ChatMessage>>([message, message2]);
        });

        final cubit = ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
        addTearDown(cubit.close);

        await cubit.load();
        expect(convCalls, 1);
        expect(msgCalls, 1);

        final first = cubit.silentRefresh();
        await Future<void>.delayed(Duration.zero);
        await cubit.silentRefresh();

        expect(convCalls, 2);

        gate.complete();
        await first;

        expect(convCalls, 2);
        expect(msgCalls, 2);
        expect(cubit.state.messages, [message, message2]);
      },
    );

    test(
      'silentRefresh skips while send post-reload fetch is in flight',
      () async {
        final gate = Completer<void>();
        var convCalls = 0;
        var msgCalls = 0;

        when(() => repository.getConversation('c1')).thenAnswer((_) async {
          convCalls++;
          if (convCalls == 2) await gate.future;
          return Success(conversation);
        });
        when(() => repository.getMessages('c1')).thenAnswer((_) async {
          msgCalls++;
          if (msgCalls == 1) {
            return Success<List<ChatMessage>>([message]);
          }
          return Success<List<ChatMessage>>([message, message2]);
        });
        when(
          () => repository.sendMessage('c1', 'hi'),
        ).thenAnswer((_) async => const Success<String>('m2'));

        final cubit = ConversationThreadCubit(
          repository: repository,
          conversationId: 'c1',
        );
        addTearDown(cubit.close);

        await cubit.load();
        expect(convCalls, 1);

        final sendFuture = cubit.send('hi');
        await Future<void>.delayed(Duration.zero);

        await cubit.silentRefresh();

        expect(convCalls, 2);

        gate.complete();
        await sendFuture;

        expect(convCalls, 2);
        expect(msgCalls, 2);
        expect(cubit.state.messages, [message, message2]);
      },
    );
  });
}
