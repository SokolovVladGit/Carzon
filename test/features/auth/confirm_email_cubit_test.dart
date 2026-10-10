import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/usecases/resend_signup_confirmation.dart';
import 'package:carzon/features/auth/presentation/bloc/confirm_email_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/confirm_email_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;
  late ConfirmEmailCubit cubit;

  setUp(() {
    repo = _MockRepo();
    cubit = ConfirmEmailCubit(
      email: '  user@example.com  ',
      resendSignupConfirmation: ResendSignupConfirmation(repo),
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  test('trims the address from the signup session', () {
    expect(cubit.email, 'user@example.com');
  });

  test('resend success', () async {
    when(
      () => repo.resendSignupConfirmation(any()),
    ).thenAnswer((_) async => const Success(null));

    await cubit.resend();

    expect(cubit.state.status, ConfirmEmailStatus.success);
    verify(() => repo.resendSignupConfirmation('user@example.com')).called(1);
  });

  test('resend failure', () async {
    when(
      () => repo.resendSignupConfirmation(any()),
    ).thenAnswer((_) async => const FailureResult(AuthFailure('network')));

    await cubit.resend();

    expect(cubit.state.status, ConfirmEmailStatus.failure);
    expect(cubit.state.failureKind, ConfirmEmailFailureKind.failed);
  });

  test('resend rate limit', () async {
    when(() => repo.resendSignupConfirmation(any())).thenAnswer(
      (_) async => const FailureResult(
        AuthFailure(
          'For security purposes, you can only request this after 60 seconds.',
        ),
      ),
    );

    await cubit.resend();

    expect(cubit.state.failureKind, ConfirmEmailFailureKind.rateLimited);
  });

  test('ignores a second resend while one is in flight', () async {
    when(() => repo.resendSignupConfirmation(any())).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 20));
      return const Success(null);
    });

    final first = cubit.resend();
    final second = cubit.resend();
    await Future.wait([first, second]);

    verify(() => repo.resendSignupConfirmation(any())).called(1);
  });
}
