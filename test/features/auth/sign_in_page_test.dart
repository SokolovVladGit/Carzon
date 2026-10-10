import 'package:bloc_test/bloc_test.dart';
import 'dart:async';

import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/social/social_auth_availability.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/pages/sign_in_page.dart';
import 'package:carzon/features/auth/presentation/widgets/auth_editorial_header.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

const _iosConfigured = SocialAuthAvailability(
  googleEnabled: true,
  appleEnabled: true,
);

const _iosGoogleUnavailable = SocialAuthAvailability(
  googleEnabled: false,
  appleEnabled: true,
);

const _androidUnconfigured = SocialAuthAvailability(
  googleEnabled: false,
  appleEnabled: false,
);

Widget _wrap(AuthCubit cubit, {SocialAuthAvailability? availability}) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: cubit,
      child: SignInPage(availability: availability ?? _androidUnconfigured),
    ),
  );
}

void main() {
  late _MockAuthCubit cubit;
  final l10n = ruStrings();

  setUp(() {
    cubit = _MockAuthCubit();
    when(
      () => cubit.signIn(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    when(() => cubit.signInWithGoogle()).thenAnswer((_) async {});
    when(() => cubit.signInWithApple()).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
  });

  testWidgets('renders editorial auth header branding block', (tester) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(find.byType(AuthEditorialHeader), findsOneWidget);
    expect(
      find.byKey(const ValueKey('auth_editorial_eyebrow')),
      findsOneWidget,
    );
    expect(find.text(l10n.signInEyebrow), findsOneWidget);
    expect(find.text(l10n.signInTitle), findsOneWidget);
    expect(find.text(l10n.signInSubtitle), findsNothing);
    expect(find.byKey(const ValueKey('auth_editorial_subtitle')), findsNothing);
  });

  testWidgets('renders email and password fields with primary sign-in action', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(find.byType(TextFormField), findsNWidgets(2));
    expect(
      find.widgetWithText(FilledButton, l10n.signInSubmit),
      findsOneWidget,
    );
  });

  testWidgets('renders a Create account link below the Sign in button', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(
      find.widgetWithText(FilledButton, l10n.signInSubmit),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(TextButton, l10n.signInCreateAccount),
      findsOneWidget,
    );
  });

  testWidgets('does not render a Terms & Privacy link', (tester) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(find.widgetWithText(TextButton, l10n.legalLink), findsNothing);
  });

  testWidgets('renders a Forgot password link', (tester) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(
      find.widgetWithText(TextButton, l10n.signInForgotPassword),
      findsOneWidget,
    );
  });

  testWidgets('auth fields and primary button remain tappable', (tester) async {
    await tester.pumpWidget(_wrap(cubit));

    await tester.enterText(
      find.byType(TextFormField).first,
      'user@example.com',
    );
    await tester.enterText(find.byType(TextFormField).last, 'secret12');
    await tester.tap(find.widgetWithText(FilledButton, l10n.signInSubmit));
    await tester.pump();

    verify(
      () => cubit.signIn(email: 'user@example.com', password: 'secret12'),
    ).called(1);
  });

  testWidgets('no layout exceptions on compact viewport (320×568 logical)', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(_wrap(cubit));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('iOS configured shows Google, Apple, and separator', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(cubit, availability: _iosConfigured));

    expect(find.byKey(const ValueKey('sign_in_google_button')), findsOneWidget);
    expect(find.byKey(const ValueKey('sign_in_apple_button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sign_in_social_separator')),
      findsOneWidget,
    );
    expect(find.text(l10n.signInContinueGoogle), findsOneWidget);
    expect(find.text(l10n.signInContinueApple), findsOneWidget);
    expect(find.text(l10n.signInSocialSeparator), findsOneWidget);
  });

  testWidgets('iOS without Google keeps Apple and separator', (tester) async {
    await tester.pumpWidget(_wrap(cubit, availability: _iosGoogleUnavailable));

    expect(find.byKey(const ValueKey('sign_in_google_button')), findsNothing);
    expect(find.byKey(const ValueKey('sign_in_apple_button')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('sign_in_social_separator')),
      findsOneWidget,
    );
  });

  testWidgets('Android unconfigured hides dead Google button and separator', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(find.byKey(const ValueKey('sign_in_google_button')), findsNothing);
    expect(find.byKey(const ValueKey('sign_in_apple_button')), findsNothing);
    expect(
      find.byKey(const ValueKey('sign_in_social_separator')),
      findsNothing,
    );
    expect(find.text(l10n.signInSubmit), findsOneWidget);
    expect(find.text(l10n.signInSubtitle), findsNothing);
    expect(find.widgetWithText(TextButton, l10n.legalLink), findsNothing);
  });

  testWidgets('social loading disables provider buttons', (tester) async {
    when(() => cubit.state).thenReturn(const AuthState.authenticating());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticating(),
    );

    await tester.pumpWidget(_wrap(cubit, availability: _iosConfigured));

    final google = tester.widget<OutlinedButton>(
      find.byKey(const ValueKey('sign_in_google_button')),
    );
    final apple = tester.widget<FilledButton>(
      find.byKey(const ValueKey('sign_in_apple_button')),
    );
    expect(google.onPressed, isNull);
    expect(apple.onPressed, isNull);
  });

  testWidgets('successful social auth routes to Home', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.c');
    final states = StreamController<AuthState>();
    addTearDown(states.close);
    whenListen(
      cubit,
      states.stream,
      initialState: const AuthState.unauthenticated(),
    );

    final router = GoRouter(
      initialLocation: AppRoutes.signIn,
      routes: [
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => BlocProvider<AuthCubit>.value(
            value: cubit,
            child: const SignInPage(availability: _iosConfigured),
          ),
        ),
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Text('home', key: Key('home-route')),
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
    states.add(const AuthState.authenticated(user));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('home-route')), findsOneWidget);
  });
}
