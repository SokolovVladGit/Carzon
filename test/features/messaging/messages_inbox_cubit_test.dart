import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/domain/entities/conversation.dart';
import 'package:carzon/features/messaging/domain/messaging_failure_kind.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messages_inbox_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messages_inbox_state.dart';
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
    lastMessagePreview: 'Hi',
    listingTitle: 'Volkswagen Golf',
  );

  final conversation2 = Conversation(
    id: 'c2',
    listingId: 'l2',
    buyerId: 'b1',
    sellerId: 's2',
    createdAt: t0,
    updatedAt: t0,
    lastMessagePreview: 'Yo',
    listingTitle: 'BMW 3 Series',
  );

  setUp(() {
    repository = _MockMessagingRepository();
  });

  group('MessagesInboxCubit', () {
    blocTest<MessagesInboxCubit, MessagesInboxState>(
      'refresh success emits conversations',
      build: () {
        when(
          () => repository.getConversations(),
        ).thenAnswer((_) async => Success<List<Conversation>>([conversation]));
        return MessagesInboxCubit(repository);
      },
      act: (c) => c.refresh(),
      expect: () => [
        isA<MessagesInboxState>().having(
          (s) => s.status,
          'status',
          MessagesInboxStatus.loading,
        ),
        isA<MessagesInboxState>()
            .having((s) => s.status, 'status', MessagesInboxStatus.success)
            .having((s) => s.conversations, 'conversations', [conversation]),
      ],
    );

    blocTest<MessagesInboxCubit, MessagesInboxState>(
      'refresh failure emits typed failure kind',
      build: () {
        when(() => repository.getConversations()).thenAnswer(
          (_) async => const FailureResult<List<Conversation>>(
            NetworkFailure('offline'),
          ),
        );
        return MessagesInboxCubit(repository);
      },
      act: (c) => c.refresh(),
      verify: (c) {
        expect(c.state.status, MessagesInboxStatus.failure);
        expect(c.state.failureKind, MessagingFailureKind.network);
      },
    );

    blocTest<MessagesInboxCubit, MessagesInboxState>(
      'silentRefresh success updates list without loading',
      build: () {
        when(
          () => repository.getConversations(),
        ).thenAnswer((_) async => Success<List<Conversation>>([conversation]));
        return MessagesInboxCubit(repository);
      },
      act: (c) async {
        await c.refresh();
        when(() => repository.getConversations()).thenAnswer(
          (_) async =>
              Success<List<Conversation>>([conversation, conversation2]),
        );
        await c.silentRefresh();
      },
      verify: (c) {
        expect(c.state.status, MessagesInboxStatus.success);
        expect(c.state.conversations, [conversation, conversation2]);
      },
    );

    blocTest<MessagesInboxCubit, MessagesInboxState>(
      'silentRefresh failure keeps prior success data',
      build: () {
        when(
          () => repository.getConversations(),
        ).thenAnswer((_) async => Success<List<Conversation>>([conversation]));
        return MessagesInboxCubit(repository);
      },
      act: (c) async {
        await c.refresh();
        when(() => repository.getConversations()).thenAnswer(
          (_) async => const FailureResult<List<Conversation>>(
            NetworkFailure('offline'),
          ),
        );
        await c.silentRefresh();
      },
      verify: (c) {
        expect(c.state.status, MessagesInboxStatus.success);
        expect(c.state.conversations, [conversation]);
        expect(c.state.failureKind, isNull);
      },
    );

    test('silentRefresh skips while visible refresh awaits', () async {
      final gate = Completer<void>();
      var calls = 0;
      when(() => repository.getConversations()).thenAnswer((_) async {
        calls++;
        if (calls == 1) await gate.future;
        return Success<List<Conversation>>([conversation]);
      });

      final cubit = MessagesInboxCubit(repository);
      addTearDown(cubit.close);

      final refreshFuture = cubit.refresh();
      await Future<void>.delayed(Duration.zero);

      await cubit.silentRefresh();

      expect(cubit.state.status, MessagesInboxStatus.loading);
      expect(calls, 1);

      gate.complete();
      await refreshFuture;

      expect(cubit.state.status, MessagesInboxStatus.success);
      expect(calls, 1);
    });

    test('second silentRefresh skips while first awaits', () async {
      final gate = Completer<void>();
      var calls = 0;
      when(() => repository.getConversations()).thenAnswer((_) async {
        calls++;
        if (calls == 2) await gate.future;
        return Success<List<Conversation>>([conversation]);
      });

      final cubit = MessagesInboxCubit(repository);
      addTearDown(cubit.close);

      await cubit.refresh();
      expect(calls, 1);

      final first = cubit.silentRefresh();
      await Future<void>.delayed(Duration.zero);
      await cubit.silentRefresh();

      expect(calls, 2);

      gate.complete();
      await first;

      expect(calls, 2);
    });
  });
}
