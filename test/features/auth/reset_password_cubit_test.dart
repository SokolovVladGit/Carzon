import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/usecases/update_password.dart';
import 'package:carzon/features/auth/presentation/bloc/reset_password_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/reset_password_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  group('ResetPasswordCubit', () {
    late _MockRepo repo;
    late UpdatePassword useCase;

    setUp(() {
      repo = _MockRepo();
      useCase = UpdatePassword(repo);
    });

    blocTest<ResetPasswordCubit, ResetPasswordState>(
      'emits submitting then success on repository success',
      build: () {
        when(
          () => repo.updatePassword(any()),
        ).thenAnswer((_) async => const Success(null));
        return ResetPasswordCubit(updatePassword: useCase);
      },
      act: (c) =>
          c.submit(newPassword: 'newpass1', confirmPassword: 'newpass1'),
      expect: () => const [
        ResetPasswordState.submitting(),
        ResetPasswordState.success(),
      ],
      verify: (_) {
        verify(() => repo.updatePassword('newpass1')).called(1);
      },
    );

    blocTest<ResetPasswordCubit, ResetPasswordState>(
      'emits generic failure copy on repository failure',
      build: () {
        when(() => repo.updatePassword(any())).thenAnswer(
          (_) async => const FailureResult(AuthFailure('no session')),
        );
        return ResetPasswordCubit(updatePassword: useCase);
      },
      act: (c) =>
          c.submit(newPassword: 'newpass1', confirmPassword: 'newpass1'),
      expect: () => const [
        ResetPasswordState.submitting(),
        ResetPasswordState.failure(ResetPasswordFailureKind.updateFailed),
      ],
    );

    blocTest<ResetPasswordCubit, ResetPasswordState>(
      'rejects mismatched passwords without calling repository',
      build: () => ResetPasswordCubit(updatePassword: useCase),
      act: (c) =>
          c.submit(newPassword: 'newpass1', confirmPassword: 'different'),
      expect: () => const [
        ResetPasswordState.failure(ResetPasswordFailureKind.mismatch),
      ],
      verify: (_) {
        verifyNever(() => repo.updatePassword(any()));
      },
    );

    blocTest<ResetPasswordCubit, ResetPasswordState>(
      'rejects passwords shorter than the minimum length',
      build: () => ResetPasswordCubit(updatePassword: useCase),
      act: (c) => c.submit(newPassword: 'abc', confirmPassword: 'abc'),
      expect: () => const [
        ResetPasswordState.failure(ResetPasswordFailureKind.passwordTooShort),
      ],
      verify: (_) {
        verifyNever(() => repo.updatePassword(any()));
      },
    );

    blocTest<ResetPasswordCubit, ResetPasswordState>(
      'rejects an empty new password',
      build: () => ResetPasswordCubit(updatePassword: useCase),
      act: (c) => c.submit(newPassword: '', confirmPassword: ''),
      expect: () => const [
        ResetPasswordState.failure(ResetPasswordFailureKind.emptyPassword),
      ],
    );
  });
}
