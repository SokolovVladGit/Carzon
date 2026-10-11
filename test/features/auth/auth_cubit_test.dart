import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
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
  group('AuthCubit', () {
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
      'emits authenticated on successful sign in',
      build: () {
        when(
          () => repo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Success(user));
        return cubit;
      },
      act: (c) => c.signIn(email: 'a@b.c', password: 'secret1'),
      expect: () => const [
        AuthState.authenticating(),
        AuthState.authenticated(user),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'signIn: network Failure maps to networkConnectivity',
      build: () {
        when(
          () => repo.signInWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const FailureResult<AuthUser>(NetworkFailure('no route')),
        );
        return cubit;
      },
      act: (c) => c.signIn(email: 'a@b.c', password: 'secret1'),
      expect: () => const [
        AuthState.authenticating(),
        AuthState.error(AuthErrorKind.networkConnectivity),
      ],
    );

    test('duplicate signIn while authenticating is ignored', () async {
      final gate = Completer<void>();
      when(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await gate.future;
        return const Success(user);
      });

      final first = cubit.signIn(email: 'a@b.c', password: 'secret1');
      await Future<void>.value();
      expect(cubit.state.status, AuthStatus.authenticating);

      final second = cubit.signIn(email: 'a@b.c', password: 'secret1');
      gate.complete();
      await first;
      await second;

      verify(
        () => repo.signInWithPassword(email: 'a@b.c', password: 'secret1'),
      ).called(1);
    });

    blocTest<AuthCubit, AuthState>(
      'signUp: emits authenticated when repository returns a user '
      '(session issued)',
      build: () {
        when(
          () => repo.signUpWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Success<AuthUser?>(user));
        return cubit;
      },
      act: (c) => c.signUp(email: 'a@b.c', password: 'secret1'),
      expect: () => const [
        AuthState.authenticating(),
        AuthState.authenticated(user),
      ],
    );

    test('duplicate signUp while authenticating is ignored', () async {
      final gate = Completer<void>();
      when(
        () => repo.signUpWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {
        await gate.future;
        return const Success<AuthUser?>(user);
      });

      final first = cubit.signUp(email: 'a@b.c', password: 'secret1');
      await Future<void>.value();
      expect(cubit.state.status, AuthStatus.authenticating);

      final second = cubit.signUp(email: 'a@b.c', password: 'secret1');
      gate.complete();
      await first;
      await second;

      verify(
        () => repo.signUpWithPassword(email: 'a@b.c', password: 'secret1'),
      ).called(1);
    });

    blocTest<AuthCubit, AuthState>(
      'signUp: emits needsEmailConfirmation when repository returns null '
      '(no session)',
      build: () {
        when(
          () => repo.signUpWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer((_) async => const Success<AuthUser?>(null));
        return cubit;
      },
      act: (c) => c.signUp(email: 'a@b.c', password: 'secret1'),
      expect: () => const [
        AuthState.authenticating(),
        AuthState.needsEmailConfirmation(),
      ],
    );

    blocTest<AuthCubit, AuthState>(
      'signUp: emits error kind on repository failure so the widget '
      'layer can show a localized snackbar',
      build: () {
        when(
          () => repo.signUpWithPassword(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ),
        ).thenAnswer(
          (_) async =>
              const FailureResult<AuthUser?>(AuthFailure('already exists')),
        );
        return cubit;
      },
      act: (c) => c.signUp(email: 'a@b.c', password: 'secret1'),
      expect: () => const [
        AuthState.authenticating(),
        AuthState.error(AuthErrorKind.signUpEmailTaken),
      ],
    );
  });

  group('AuthCubit password recovery', () {
    late _MockRepo repo;
    late StreamController<AuthUser?> authStream;
    late StreamController<void> recoveryStream;
    late AuthCubit cubit;

    const user = AuthUser(id: 'u1', email: 'a@b.c');

    setUp(() {
      repo = _MockRepo();
      authStream = StreamController<AuthUser?>.broadcast();
      recoveryStream = StreamController<void>.broadcast();
      when(() => repo.authStateChanges).thenAnswer((_) => authStream.stream);
      when(
        () => repo.passwordRecoveryEvents,
      ).thenAnswer((_) => recoveryStream.stream);
      when(
        () => repo.getCurrentUser(),
      ).thenAnswer((_) async => const Success<AuthUser?>(null));
      when(() => repo.signOut()).thenAnswer((_) async => const Success(null));

      cubit = AuthCubit(
        repository: repo,
        getCurrentUser: GetCurrentUser(repo),
        signInWithPassword: SignInWithPassword(repo),
        signUpWithPassword: SignUpWithPassword(repo),
        signOut: SignOut(repo),
      );
    });

    tearDown(() async {
      await cubit.close();
      await authStream.close();
      await recoveryStream.close();
    });

    test('signup confirmation and token refresh stay authenticated', () async {
      await cubit.bootstrap();

      authStream.add(user);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.user, user);
    });

    test('recovery event latches passwordRecovery and later auth events '
        'do not demote it', () async {
      await cubit.bootstrap();

      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AuthStatus.passwordRecovery);

      // A normal `signedIn` / `tokenRefreshed` event that Supabase
      // often fires alongside the recovery session must NOT push the
      // cubit back to `authenticated` — the reset-password page is
      // gated on `passwordRecovery`.
      authStream.add(user);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AuthStatus.passwordRecovery);
      expect(cubit.state.user, user);
    });

    test(
      'clearPasswordRecovery returns to authenticated when a user exists',
      () async {
        await cubit.bootstrap();
        recoveryStream.add(null);
        await Future<void>.delayed(Duration.zero);
        authStream.add(user);
        await Future<void>.delayed(Duration.zero);

        cubit.clearPasswordRecovery();

        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.user, user);

        // After clearing, subsequent normal auth events route normally
        // again (no latch).
        authStream.add(null);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, AuthStatus.unauthenticated);
      },
    );

    test(
      'abandoned recovery then signedIn is authenticated, not passwordRecovery',
      () async {
        await cubit.bootstrap();
        recoveryStream.add(null);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, AuthStatus.passwordRecovery);

        cubit.clearPasswordRecovery();
        expect(cubit.state.status, AuthStatus.unauthenticated);

        authStream.add(user);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, AuthStatus.authenticated);
        expect(cubit.state.user, user);

        cubit.clearPasswordRecovery();
        expect(cubit.state.status, AuthStatus.authenticated);
      },
    );

    test('signOut exits the recovery latch', () async {
      await cubit.bootstrap();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);

      await cubit.signOut();

      expect(cubit.state.status, AuthStatus.unauthenticated);

      // Further normal events should no longer stay stuck on recovery.
      authStream.add(user);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.status, AuthStatus.authenticated);
    });

    test(
      'markUnauthenticatedAfterAccountDeletion clears session without signOut',
      () {
        cubit.emit(const AuthState.authenticated(user));
        cubit.markUnauthenticatedAfterAccountDeletion();
        expect(cubit.state.status, AuthStatus.unauthenticated);
        expect(cubit.state.publicFeedRefreshNonce, 1);
      },
    );

    test(
      'completePasswordRecovery signs out and stays unauthenticated',
      () async {
        await cubit.bootstrap();
        recoveryStream.add(null);
        await Future<void>.delayed(Duration.zero);
        authStream.add(user);
        await Future<void>.delayed(Duration.zero);

        final ended = await cubit.completePasswordRecovery();

        expect(ended, isTrue);
        expect(cubit.state.status, AuthStatus.unauthenticated);
        expect(cubit.state.user, isNull);
        verify(() => repo.signOut()).called(1);

        authStream.add(user);
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.status, AuthStatus.authenticated);
      },
    );

    test(
      'completePasswordRecovery keeps recovery when sign-out fails',
      () async {
        when(() => repo.signOut()).thenAnswer(
          (_) async => const FailureResult<void>(AuthFailure('network')),
        );
        await cubit.bootstrap();
        recoveryStream.add(null);
        await Future<void>.delayed(Duration.zero);
        authStream.add(user);
        await Future<void>.delayed(Duration.zero);

        final ended = await cubit.completePasswordRecovery();

        expect(ended, isFalse);
        expect(cubit.state.status, AuthStatus.passwordRecovery);
        expect(cubit.state.user, user);
      },
    );

    test('late signIn failure cannot overwrite recovery', () async {
      final gate = Completer<Result<AuthUser>>();
      when(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => gate.future);
      await cubit.bootstrap();

      final pending = cubit.signIn(email: 'a@b.c', password: 'secret1');
      await Future<void>.value();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);
      gate.complete(const FailureResult(AuthFailure('invalid login')));
      await pending;

      expect(cubit.state.status, AuthStatus.passwordRecovery);
    });

    test('late signIn success cannot overwrite recovery', () async {
      final gate = Completer<Result<AuthUser>>();
      when(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => gate.future);
      await cubit.bootstrap();

      final pending = cubit.signIn(email: 'a@b.c', password: 'secret1');
      await Future<void>.value();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);
      gate.complete(const Success(user));
      await pending;

      expect(cubit.state.status, AuthStatus.passwordRecovery);
    });

    test('late signUp success cannot overwrite recovery', () async {
      final gate = Completer<Result<AuthUser?>>();
      when(
        () => repo.signUpWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) => gate.future);
      await cubit.bootstrap();

      final pending = cubit.signUp(email: 'a@b.c', password: 'secret1');
      await Future<void>.value();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);
      gate.complete(const Success<AuthUser?>(user));
      await pending;

      expect(cubit.state.status, AuthStatus.passwordRecovery);
    });

    test('Google sign-in does not start during password recovery', () async {
      when(
        () => repo.signInWithGoogle(),
      ).thenAnswer((_) async => const Success(user));
      await cubit.bootstrap();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);

      await cubit.signInWithGoogle();

      expect(cubit.state.status, AuthStatus.passwordRecovery);
      verifyNever(() => repo.signInWithGoogle());
    });

    test('late Google success cannot overwrite recovery', () async {
      final gate = Completer<Result<AuthUser>>();
      when(() => repo.signInWithGoogle()).thenAnswer((_) => gate.future);
      await cubit.bootstrap();

      final pending = cubit.signInWithGoogle();
      await Future<void>.value();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);
      gate.complete(const Success(user));
      await pending;

      expect(cubit.state.status, AuthStatus.passwordRecovery);
    });

    test('late Apple completion cannot overwrite recovery', () async {
      final gate = Completer<Result<AuthUser>>();
      when(() => repo.signInWithApple()).thenAnswer((_) => gate.future);
      await cubit.bootstrap();

      final pending = cubit.signInWithApple();
      await Future<void>.value();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);
      gate.complete(const FailureResult(AuthCancelledFailure()));
      await pending;

      expect(cubit.state.status, AuthStatus.passwordRecovery);
    });

    test('signIn still authenticates after recovery is cleared', () async {
      when(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Success(user));
      await cubit.bootstrap();
      recoveryStream.add(null);
      await Future<void>.delayed(Duration.zero);
      cubit.clearPasswordRecovery();

      await cubit.signIn(email: 'a@b.c', password: 'secret1');

      expect(cubit.state.status, AuthStatus.authenticated);
      expect(cubit.state.user, user);
    });

    test(
      'markUnauthenticatedAfterAccountDeletion increments public feed refresh nonce',
      () {
        cubit.emit(const AuthState.authenticated(user));
        cubit.markUnauthenticatedAfterAccountDeletion();
        cubit.markUnauthenticatedAfterAccountDeletion();
        expect(cubit.state.publicFeedRefreshNonce, 2);
      },
    );
  });
}
