import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/pages/sign_in_page.dart';
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
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
  });

  testWidgets('renders a Create account link below the Sign in button',
      (tester) async {
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

    expect(
      find.widgetWithText(TextButton, l10n.legalLink),
      findsOneWidget,
    );
  });

  testWidgets('renders a Forgot password link', (tester) async {
    await tester.pumpWidget(_wrap(cubit));

    expect(
      find.widgetWithText(TextButton, l10n.signInForgotPassword),
      findsOneWidget,
    );
  });
}
