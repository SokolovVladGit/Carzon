import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/messaging_unread_summary_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late _MockMessagingRepository repository;

  final auth = AuthState.authenticated(
    AuthUser(id: 'u', email: 'u@example.com'),
  );

  setUp(() {
    repository = _MockMessagingRepository();
  });

  group('MessagingUnreadSummaryCubit', () {
    blocTest<MessagingUnreadSummaryCubit, MessagingUnreadSummaryState>(
      'unauthenticated maps to loaded count zero without error phase',
      build: () => MessagingUnreadSummaryCubit(repository),
      act: (c) => c.sync(const AuthState.unauthenticated()),
      expect: () => [
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.loaded,
        ).having((s) => s.unreadConversationCount, 'count', 0).having(
          (s) => s.hasLoadError,
          'hasLoadError',
          isFalse,
        ),
      ],
      verify: (_) {
        verifyNever(() => repository.getUnreadConversationCount());
      },
    );

    blocTest<MessagingUnreadSummaryCubit, MessagingUnreadSummaryState>(
      'authenticated success with count > 0 emits loaded',
      build: () {
        when(
          () => repository.getUnreadConversationCount(),
        ).thenAnswer((_) async => const Success(3));
        return MessagingUnreadSummaryCubit(repository);
      },
      act: (c) => c.sync(auth),
      expect: () => [
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.loading,
        ),
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.loaded,
        ).having((s) => s.unreadConversationCount, 'count', 3).having(
          (s) => s.hasLoadError,
          'hasLoadError',
          isFalse,
        ),
      ],
    );

    blocTest<MessagingUnreadSummaryCubit, MessagingUnreadSummaryState>(
      'authenticated success with count 0 emits definitive loaded zero',
      build: () {
        when(
          () => repository.getUnreadConversationCount(),
        ).thenAnswer((_) async => const Success(0));
        return MessagingUnreadSummaryCubit(repository);
      },
      act: (c) => c.sync(auth),
      expect: () => [
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.loading,
        ),
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.loaded,
        ).having((s) => s.unreadConversationCount, 'count', 0).having(
          (s) => s.shouldShowUnreadIndicator,
          'shouldShowUnreadIndicator',
          isFalse,
        ),
      ],
    );

    blocTest<MessagingUnreadSummaryCubit, MessagingUnreadSummaryState>(
      'repository failure emits failure phase not loaded zero',
      build: () {
        when(() => repository.getUnreadConversationCount()).thenAnswer(
          (_) async => const FailureResult(NetworkFailure('temporary')),
        );
        return MessagingUnreadSummaryCubit(repository);
      },
      act: (c) => c.sync(auth),
      expect: () => [
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.loading,
        ),
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.failure,
        ).having((s) => s.unreadConversationCount, 'count', 0).having(
          (s) => s.hasLoadError,
          'hasLoadError',
          isTrue,
        ),
      ],
    );

    blocTest<MessagingUnreadSummaryCubit, MessagingUnreadSummaryState>(
      'repository failure preserves prior successful unread count',
      build: () {
        when(() => repository.getUnreadConversationCount()).thenAnswer(
          (_) async => const FailureResult(NetworkFailure('temporary')),
        );
        return MessagingUnreadSummaryCubit(repository);
      },
      seed: () => const MessagingUnreadSummaryState(
        phase: MessagingUnreadSummaryPhase.loaded,
        unreadConversationCount: 4,
      ),
      act: (c) => c.sync(auth),
      expect: () => [
        isA<MessagingUnreadSummaryState>().having(
          (s) => s.phase,
          'phase',
          MessagingUnreadSummaryPhase.loading,
        ),
        isA<MessagingUnreadSummaryState>()
            .having(
              (s) => s.phase,
              'phase',
              MessagingUnreadSummaryPhase.failure,
            )
            .having((s) => s.unreadConversationCount, 'count', 4)
            .having((s) => s.shouldShowUnreadIndicator, 'indicator', isTrue),
      ],
    );
  });
}
