import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/social/social_auth_error_mapper.dart';
import 'package:carzon/features/auth/domain/usecases/get_current_user.dart';
import 'package:carzon/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:carzon/features/auth/domain/usecases/sign_out.dart';
import 'package:carzon/features/auth/domain/usecases/sign_up_with_password.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockRepo repo;
  late AuthCubit cubit;
  const user = AuthUser(id: 'u1', email: 'a@b.c');

  setUp(() {
    repo = _MockRepo();
    when(() => repo.authStateChanges).thenAnswer((_) => const Stream.empty());
    when(
      () => repo.passwordRecoveryEvents,
    ).thenAnswer((_) => const Stream<void>.empty());
    cubit = AuthCubit(
      repository: repo,
      getCurrentUser: GetCurrentUser(repo),
      signInWithPassword: SignInWithPassword(repo),
      signUpWithPassword: SignUpWithPassword(repo),
      signOut: SignOut(repo),
    );
  });

  tearDown(() => cubit.close());

  blocTest<AuthCubit, AuthState>(
    'Google success becomes authenticated',
    build: () {
      when(
        () => repo.signInWithGoogle(),
      ).thenAnswer((_) async => const Success(user));
      return cubit;
    },
    act: (c) => c.signInWithGoogle(),
    expect: () => const [
      AuthState.authenticating(),
      AuthState.authenticated(user),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Google cancellation returns to unauthenticated without an error',
    build: () {
      when(
        () => repo.signInWithGoogle(),
      ).thenAnswer((_) async => const FailureResult(AuthCancelledFailure()));
      return cubit;
    },
    act: (c) => c.signInWithGoogle(),
    expect: () => const [
      AuthState.authenticating(),
      AuthState.unauthenticated(),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'Apple success becomes authenticated',
    build: () {
      when(
        () => repo.signInWithApple(),
      ).thenAnswer((_) async => const Success(user));
      return cubit;
    },
    act: (c) => c.signInWithApple(),
    expect: () => const [
      AuthState.authenticating(),
      AuthState.authenticated(user),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'identity collision maps to identityAlreadyExists',
    build: () {
      when(() => repo.signInWithGoogle()).thenAnswer(
        (_) async => const FailureResult(
          AuthFailure(SocialAuthMessages.identityAlreadyExists),
        ),
      );
      return cubit;
    },
    act: (c) => c.signInWithGoogle(),
    expect: () => const [
      AuthState.authenticating(),
      AuthState.error(AuthErrorKind.identityAlreadyExists),
    ],
  );

  blocTest<AuthCubit, AuthState>(
    'duplicate social taps are ignored while authenticating',
    build: () {
      when(() => repo.signInWithGoogle()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return const Success(user);
      });
      return cubit;
    },
    act: (c) async {
      await Future.wait<void>([c.signInWithGoogle(), c.signInWithGoogle()]);
    },
    expect: () => const [
      AuthState.authenticating(),
      AuthState.authenticated(user),
    ],
    verify: (_) => verify(() => repo.signInWithGoogle()).called(1),
  );
}
