import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/usecases/get_current_user.dart';
import 'package:carzon/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:carzon/features/auth/domain/usecases/sign_out.dart';
import 'package:carzon/features/auth/domain/usecases/sign_up_with_password.dart';
import 'package:carzon/features/auth/presentation/auth_callback_navigation.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/bloc/reset_password_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/reset_password_state.dart';
import 'package:carzon/features/auth/presentation/pages/reset_password_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockResetCubit extends MockCubit<ResetPasswordState>
    implements ResetPasswordCubit {}

class _MockRepo extends Mock implements AuthRepository {}

Widget _wrap(AuthCubit auth) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: auth,
      child: const ResetPasswordPage(),
    ),
  );
}

void main() {
  late _MockAuthCubit auth;
  late _MockResetCubit reset;
  final l10n = ruStrings();

  const user = AuthUser(id: 'u1', email: 'a@b.c');

  setUp(() async {
    await sl.reset();
    auth = _MockAuthCubit();
    reset = _MockResetCubit();
    when(() => reset.state).thenReturn(const ResetPasswordState.idle());
    whenListen(
      reset,
      const Stream<ResetPasswordState>.empty(),
      initialState: const ResetPasswordState.idle(),
    );
    sl.registerFactory<ResetPasswordCubit>(() => reset);
  });

  tearDown(() async {
    await sl.reset();
  });

  void stubAuth(AuthState state) {
    when(() => auth.state).thenReturn(state);
    whenListen(auth, Stream<AuthState>.value(state), initialState: state);
  }

  testWidgets(
    'shows the guarded state with clear copy when no recovery session exists',
    (tester) async {
      stubAuth(const AuthState.unauthenticated());

      await tester.pumpWidget(_wrap(auth));

      expect(find.text(l10n.resetPasswordNoSession), findsOneWidget);
      expect(
        find.widgetWithText(TextFormField, l10n.resetPasswordNew),
        findsNothing,
      );
    },
  );

  testWidgets('renders the form when in a password-recovery session', (
    tester,
  ) async {
    stubAuth(const AuthState.passwordRecovery(user));

    await tester.pumpWidget(_wrap(auth));

    expect(
      find.widgetWithText(TextFormField, l10n.resetPasswordNew),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextFormField, l10n.resetPasswordConfirmNew),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, l10n.resetPasswordSubmit),
      findsOneWidget,
    );
  });

  testWidgets('rejects mismatched confirmation without calling cubit.submit', (
    tester,
  ) async {
    stubAuth(const AuthState.passwordRecovery(user));

    await tester.pumpWidget(_wrap(auth));

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.resetPasswordNew),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.resetPasswordConfirmNew),
      'different',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.resetPasswordSubmit),
    );
    await tester.pump();

    expect(find.text(l10n.validationPasswordsDoNotMatch), findsOneWidget);
    verifyNever(
      () => reset.submit(
        newPassword: any(named: 'newPassword'),
        confirmPassword: any(named: 'confirmPassword'),
      ),
    );
  });

  testWidgets('rejects a too-short password without calling cubit.submit', (
    tester,
  ) async {
    stubAuth(const AuthState.passwordRecovery(user));

    await tester.pumpWidget(_wrap(auth));

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.resetPasswordNew),
      'abc',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.resetPasswordConfirmNew),
      'abc',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.resetPasswordSubmit),
    );
    await tester.pump();

    expect(find.text(l10n.validationPasswordMin), findsOneWidget);
    verifyNever(
      () => reset.submit(
        newPassword: any(named: 'newPassword'),
        confirmPassword: any(named: 'confirmPassword'),
      ),
    );
  });

  testWidgets('valid form: submit delegates to the reset-password cubit', (
    tester,
  ) async {
    stubAuth(const AuthState.passwordRecovery(user));
    when(
      () => reset.submit(
        newPassword: any(named: 'newPassword'),
        confirmPassword: any(named: 'confirmPassword'),
      ),
    ).thenAnswer((_) async {});

    await tester.pumpWidget(_wrap(auth));

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.resetPasswordNew),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.resetPasswordConfirmNew),
      'newpass1',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.resetPasswordSubmit),
    );
    await tester.pump();

    verify(
      () => reset.submit(newPassword: 'newpass1', confirmPassword: 'newpass1'),
    ).called(1);
  });

  testWidgets('Back clears recovery latch and routes to sign-in', (
    tester,
  ) async {
    stubAuth(const AuthState.passwordRecovery(user));
    when(auth.clearPasswordRecovery).thenReturn(null);

    late GoRouter router;
    router = GoRouter(
      initialLocation: AppRoutes.resetPassword,
      routes: [
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => const Text('sign-in', key: Key('sign-in-route')),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (_, _) => BlocProvider<AuthCubit>.value(
            value: auth,
            child: const ResetPasswordPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    verify(auth.clearPasswordRecovery).called(1);
    expect(find.byKey(const Key('sign-in-route')), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
  });

  testWidgets('successful reset signs out and leaves for sign-in', (
    tester,
  ) async {
    stubAuth(const AuthState.passwordRecovery(user));
    when(() => auth.completePasswordRecovery()).thenAnswer((_) async => true);
    final resetStates = StreamController<ResetPasswordState>.broadcast();
    addTearDown(resetStates.close);
    whenListen(
      reset,
      resetStates.stream,
      initialState: const ResetPasswordState.idle(),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.resetPassword,
      routes: [
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => const Text('sign-in', key: Key('sign-in-route')),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (_, _) => BlocProvider<AuthCubit>.value(
            value: auth,
            child: const ResetPasswordPage(),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        routerConfig: router,
      ),
    );
    await tester.pump();

    resetStates.add(const ResetPasswordState.success());
    await tester.pumpAndSettle();

    verify(() => auth.completePasswordRecovery()).called(1);
    verifyNever(auth.clearPasswordRecovery);
    expect(find.byKey(const Key('sign-in-route')), findsOneWidget);
  });

  testWidgets('failed recovery sign-out stays on reset and keeps the latch', (
    tester,
  ) async {
    stubAuth(const AuthState.passwordRecovery(user));
    when(() => auth.completePasswordRecovery()).thenAnswer((_) async => false);
    final resetStates = StreamController<ResetPasswordState>.broadcast();
    addTearDown(resetStates.close);
    whenListen(
      reset,
      resetStates.stream,
      initialState: const ResetPasswordState.idle(),
    );

    await tester.pumpWidget(_wrap(auth));
    await tester.pump();

    resetStates.add(const ResetPasswordState.success());
    await tester.pump();
    await tester.pump();

    verify(() => auth.completePasswordRecovery()).called(1);
    verifyNever(auth.clearPasswordRecovery);
    expect(find.text(l10n.signOutFailedRetry), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.resetPasswordSubmit),
      findsOneWidget,
    );
  });

  testWidgets(
    'signedIn after abandoning reset stays authenticated and off /reset-password',
    (tester) async {
      final repo = _MockRepo();
      final authStream = StreamController<AuthUser?>.broadcast();
      final recoveryStream = StreamController<void>.broadcast();
      addTearDown(() async {
        await authStream.close();
        await recoveryStream.close();
      });
      when(() => repo.authStateChanges).thenAnswer((_) => authStream.stream);
      when(
        () => repo.passwordRecoveryEvents,
      ).thenAnswer((_) => recoveryStream.stream);
      when(
        () => repo.getCurrentUser(),
      ).thenAnswer((_) async => const Success<AuthUser?>(null));

      final liveAuth = AuthCubit(
        repository: repo,
        getCurrentUser: GetCurrentUser(repo),
        signInWithPassword: SignInWithPassword(repo),
        signUpWithPassword: SignUpWithPassword(repo),
        signOut: SignOut(repo),
      );
      addTearDown(liveAuth.close);
      await liveAuth.bootstrap();

      late GoRouter router;
      router = GoRouter(
        initialLocation: AppRoutes.listings,
        routes: [
          GoRoute(
            path: AppRoutes.listings,
            builder: (_, _) => const Text('home', key: Key('home-route')),
          ),
          GoRoute(
            path: AppRoutes.signIn,
            builder: (_, _) => const Text('sign-in', key: Key('sign-in-route')),
          ),
          GoRoute(
            path: AppRoutes.resetPassword,
            builder: (_, _) => BlocProvider<AuthCubit>.value(
              value: liveAuth,
              child: const ResetPasswordPage(),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
        ),
      );
      await tester.pump();

      recoveryStream.add(null);
      await tester.pump();
      openPasswordResetIfRecovery(router, liveAuth.state);
      await tester.pumpAndSettle();
      expect(liveAuth.state.status, AuthStatus.passwordRecovery);
      expect(find.byType(ResetPasswordPage), findsOneWidget);

      await tester.tap(find.byType(AppBackButton));
      await tester.pumpAndSettle();

      expect(liveAuth.state.status, isNot(AuthStatus.passwordRecovery));
      expect(find.byKey(const Key('sign-in-route')), findsOneWidget);

      authStream.add(user);
      await tester.pump();
      openPasswordResetIfRecovery(router, liveAuth.state);
      await tester.pumpAndSettle();

      expect(liveAuth.state.status, AuthStatus.authenticated);
      expect(find.byKey(const Key('sign-in-route')), findsOneWidget);
      expect(find.byType(ResetPasswordPage), findsNothing);
      expect(router.routeInformationProvider.value.uri.path, AppRoutes.signIn);
    },
  );
}
