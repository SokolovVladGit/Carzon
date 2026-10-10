import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/bloc/confirm_email_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/confirm_email_state.dart';
import 'package:carzon/features/auth/presentation/pages/confirm_email_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockConfirmEmailCubit extends MockCubit<ConfirmEmailState>
    implements ConfirmEmailCubit {}

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late _MockConfirmEmailCubit confirmCubit;
  late _MockAuthCubit authCubit;
  final l10n = ruStrings();
  const email = 'user@example.com';

  setUp(() async {
    await sl.reset();
    confirmCubit = _MockConfirmEmailCubit();
    authCubit = _MockAuthCubit();
    when(() => confirmCubit.email).thenReturn(email);
    when(() => confirmCubit.state).thenReturn(const ConfirmEmailState.idle());
    whenListen(
      confirmCubit,
      const Stream<ConfirmEmailState>.empty(),
      initialState: const ConfirmEmailState.idle(),
    );
    when(
      () => authCubit.state,
    ).thenReturn(const AuthState.needsEmailConfirmation());
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.needsEmailConfirmation(),
    );
    sl.registerFactoryParam<ConfirmEmailCubit, String, void>(
      (_, _) => confirmCubit,
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget app() {
    final router = GoRouter(
      initialLocation: AppRoutes.confirmEmailLocation(email),
      routes: [
        GoRoute(
          path: AppRoutes.confirmEmail,
          builder: (_, state) => BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: ConfirmEmailPage(
              email: state.uri.queryParameters['email'] ?? '',
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => const Text('sign-in', key: Key('sign-in-route')),
        ),
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Text('home', key: Key('home-route')),
        ),
      ],
    );
    return MaterialApp.router(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }

  testWidgets('shows the address, resend, and return to sign in', (
    tester,
  ) async {
    await tester.pumpWidget(app());

    expect(find.text(l10n.confirmEmailTitle), findsOneWidget);
    expect(find.text(email), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.confirmEmailResend),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, l10n.backToSignIn), findsOneWidget);
  });

  testWidgets('resend calls the cubit', (tester) async {
    when(() => confirmCubit.resend()).thenAnswer((_) async {});

    await tester.pumpWidget(app());
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.confirmEmailResend),
    );
    await tester.pump();

    verify(() => confirmCubit.resend()).called(1);
  });

  testWidgets('resend loading replaces the button label', (tester) async {
    when(
      () => confirmCubit.state,
    ).thenReturn(const ConfirmEmailState.submitting());
    whenListen(
      confirmCubit,
      const Stream<ConfirmEmailState>.empty(),
      initialState: const ConfirmEmailState.submitting(),
    );

    await tester.pumpWidget(app());

    expect(
      find.byKey(const Key('confirm-email-resend-loading')),
      findsOneWidget,
    );
    expect(find.text(l10n.confirmEmailResend), findsNothing);
  });

  testWidgets('resend success shows a snackbar', (tester) async {
    final states = StreamController<ConfirmEmailState>();
    addTearDown(states.close);
    whenListen(
      confirmCubit,
      states.stream,
      initialState: const ConfirmEmailState.idle(),
    );

    await tester.pumpWidget(app());
    states.add(const ConfirmEmailState.success());
    await tester.pump();

    expect(find.text(l10n.confirmEmailResendSuccess), findsOneWidget);
  });

  testWidgets('resend failure shows a snackbar', (tester) async {
    final states = StreamController<ConfirmEmailState>();
    addTearDown(states.close);
    whenListen(
      confirmCubit,
      states.stream,
      initialState: const ConfirmEmailState.idle(),
    );

    await tester.pumpWidget(app());
    states.add(const ConfirmEmailState.failure(ConfirmEmailFailureKind.failed));
    await tester.pump();

    expect(find.text(l10n.confirmEmailResendFailed), findsOneWidget);
  });

  testWidgets('resend rate limit shows a snackbar', (tester) async {
    final states = StreamController<ConfirmEmailState>();
    addTearDown(states.close);
    whenListen(
      confirmCubit,
      states.stream,
      initialState: const ConfirmEmailState.idle(),
    );

    await tester.pumpWidget(app());
    states.add(
      const ConfirmEmailState.failure(ConfirmEmailFailureKind.rateLimited),
    );
    await tester.pump();

    expect(find.text(l10n.confirmEmailResendRateLimited), findsOneWidget);
  });

  testWidgets('return to sign in leaves the confirmation page', (tester) async {
    await tester.pumpWidget(app());
    await tester.tap(find.widgetWithText(TextButton, l10n.backToSignIn));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('sign-in-route')), findsOneWidget);
  });

  testWidgets('a confirmed session leaves for home', (tester) async {
    final states = StreamController<AuthState>();
    addTearDown(states.close);
    whenListen(
      authCubit,
      states.stream,
      initialState: const AuthState.needsEmailConfirmation(),
    );

    await tester.pumpWidget(app());
    states.add(const AuthState.authenticated(AuthUser(id: 'u1', email: email)));
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('home-route')), findsOneWidget);
  });
}
