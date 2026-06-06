import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/usecases/request_password_reset.dart';
import 'package:carzon/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/forgot_password_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  group('ForgotPasswordCubit', () {
    late _MockRepo repo;
    late RequestPasswordReset useCase;

    setUp(() {
      repo = _MockRepo();
      useCase = RequestPasswordReset(repo);
    });

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits submitting then success on repository success',
      build: () {
        when(
          () => repo.requestPasswordReset(any()),
        ).thenAnswer((_) async => const Success(null));
        return ForgotPasswordCubit(requestPasswordReset: useCase);
      },
      act: (c) => c.submit('seller@example.com'),
      expect: () => const [
        ForgotPasswordState.submitting(),
        ForgotPasswordState.success(),
      ],
      verify: (_) {
        verify(() => repo.requestPasswordReset('seller@example.com')).called(1);
      },
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'trims whitespace before delegating to the repository',
      build: () {
        when(
          () => repo.requestPasswordReset(any()),
        ).thenAnswer((_) async => const Success(null));
        return ForgotPasswordCubit(requestPasswordReset: useCase);
      },
      act: (c) => c.submit('  seller@example.com  '),
      verify: (_) {
        verify(() => repo.requestPasswordReset('seller@example.com')).called(1);
      },
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits submitting then failure with generic copy on repository failure',
      build: () {
        when(
          () => repo.requestPasswordReset(any()),
        ).thenAnswer((_) async => const FailureResult(ServerFailure('boom')));
        return ForgotPasswordCubit(requestPasswordReset: useCase);
      },
      act: (c) => c.submit('seller@example.com'),
      expect: () => const [
        ForgotPasswordState.submitting(),
        ForgotPasswordState.failure(ForgotPasswordFailureKind.requestFailed),
      ],
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits failure without calling repository when email is empty',
      build: () => ForgotPasswordCubit(requestPasswordReset: useCase),
      act: (c) => c.submit('   '),
      expect: () => const [
        ForgotPasswordState.failure(ForgotPasswordFailureKind.emptyEmail),
      ],
      verify: (_) {
        verifyNever(() => repo.requestPasswordReset(any()));
      },
    );

    test('duplicate submit while request is in flight is ignored', () async {
      final gate = Completer<void>();
      when(() => repo.requestPasswordReset(any())).thenAnswer((_) async {
        await gate.future;
        return const Success(null);
      });
      final cubit = ForgotPasswordCubit(requestPasswordReset: useCase);

      final first = cubit.submit('seller@example.com');
      await Future<void>.value();
      expect(cubit.state.status, ForgotPasswordStatus.submitting);

      final second = cubit.submit('seller@example.com');
      gate.complete();
      await first;
      await second;

      verify(() => repo.requestPasswordReset('seller@example.com')).called(1);
      await cubit.close();
    });
  });
}
