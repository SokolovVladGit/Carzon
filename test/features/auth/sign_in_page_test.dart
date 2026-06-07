import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/pages/sign_in_page.dart';
import 'package:carzon/features/auth/presentation/widgets/auth_editorial_header.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Widget _wrap(AuthCubit cubit) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(
      value: cubit,
      child: const SignInPage(),
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
    expect(find.text(l10n.signInSubtitle), findsOneWidget);
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

  testWidgets('renders a Terms & Privacy link', (tester) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(find.widgetWithText(TextButton, l10n.legalLink), findsOneWidget);
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
}
