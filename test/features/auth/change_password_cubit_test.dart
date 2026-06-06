import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:carzon/features/auth/domain/usecases/update_password.dart';
import 'package:carzon/features/auth/presentation/bloc/change_password_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/change_password_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  group('ChangePasswordCubit', () {
    late _MockRepo repo;
    late ChangePasswordCubit cubit;
    const user = AuthUser(id: 'u1', email: 'seller@example.com');

    setUp(() {
      repo = _MockRepo();
      cubit = ChangePasswordCubit(
        signInWithPassword: SignInWithPassword(repo),
        updatePassword: UpdatePassword(repo),
      );
      when(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Success(user));
      when(
        () => repo.updatePassword(any()),
      ).thenAnswer((_) async => const Success(null));
    });

    tearDown(() => cubit.close());

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'success reauthenticates then updates password',
      build: () => cubit,
      act: (c) => c.submit(
        email: 'seller@example.com',
        currentPassword: 'oldpass1',
        newPassword: 'newpass1',
        confirmPassword: 'newpass1',
      ),
      expect: () => const [
        ChangePasswordState.submitting(),
        ChangePasswordState.success(),
      ],
      verify: (_) {
        verify(
          () => repo.signInWithPassword(
            email: 'seller@example.com',
            password: 'oldpass1',
          ),
        ).called(1);
        verify(() => repo.updatePassword('newpass1')).called(1);
      },
    );

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'current password failure does not update password',
      setUp: () {
        when(
          () => repo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const FailureResult<AuthUser>(AuthFailure('invalid credentials')),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(
        email: 'seller@example.com',
        currentPassword: 'wrong',
        newPassword: 'newpass1',
        confirmPassword: 'newpass1',
      ),
      expect: () => const [
        ChangePasswordState.submitting(),
        ChangePasswordState.failure(
          ChangePasswordFailureKind.currentPasswordInvalid,
        ),
      ],
      verify: (_) {
        verifyNever(() => repo.updatePassword(any()));
      },
    );

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'mismatched confirmation is rejected before auth calls',
      build: () => cubit,
      act: (c) => c.submit(
        email: 'seller@example.com',
        currentPassword: 'oldpass1',
        newPassword: 'newpass1',
        confirmPassword: 'different',
      ),
      expect: () => const [
        ChangePasswordState.failure(ChangePasswordFailureKind.mismatch),
      ],
      verify: (_) {
        verifyNever(
          () => repo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
        verifyNever(() => repo.updatePassword(any()));
      },
    );

    blocTest<ChangePasswordCubit, ChangePasswordState>(
      'empty current password is rejected before auth calls',
      build: () => cubit,
      act: (c) => c.submit(
        email: 'seller@example.com',
        currentPassword: '',
        newPassword: 'newpass1',
        confirmPassword: 'newpass1',
      ),
      expect: () => const [
        ChangePasswordState.failure(
          ChangePasswordFailureKind.emptyCurrentPassword,
        ),
      ],
      verify: (_) {
        verifyNever(
          () => repo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        );
      },
    );

    test('duplicate submit while update is in flight is ignored', () async {
      final gate = Completer<void>();
      when(() => repo.updatePassword(any())).thenAnswer((_) async {
        await gate.future;
        return const Success(null);
      });

      final first = cubit.submit(
        email: 'seller@example.com',
        currentPassword: 'oldpass1',
        newPassword: 'newpass1',
        confirmPassword: 'newpass1',
      );
      await Future<void>.value();
      expect(cubit.state.status, ChangePasswordStatus.submitting);

      final second = cubit.submit(
        email: 'seller@example.com',
        currentPassword: 'oldpass1',
        newPassword: 'newpass1',
        confirmPassword: 'newpass1',
      );
      gate.complete();
      await first;
      await second;

      verify(
        () => repo.signInWithPassword(
          email: 'seller@example.com',
          password: 'oldpass1',
        ),
      ).called(1);
      verify(() => repo.updatePassword('newpass1')).called(1);
    });
  });
}
