import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/pages/sign_up_page.dart';
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
      child: const SignUpPage(),
    ),
  );
}

void main() {
  late _MockAuthCubit cubit;
  final l10n = ruStrings();

  setUpAll(() {
    registerFallbackValue('');
  });

  setUp(() {
    cubit = _MockAuthCubit();
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );
  });

  testWidgets(
    'shows email, password, confirm password, Create account and Sign in',
    (tester) async {
      await tester.pumpWidget(_wrap(cubit));

      expect(find.byType(AuthEditorialHeader), findsOneWidget);
      expect(
        find.byKey(const ValueKey('auth_editorial_title')),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(FilledButton, l10n.signUpSubmit),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, l10n.authFieldEmail),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, l10n.authFieldPassword),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextFormField, l10n.authFieldConfirmPassword),
        findsOneWidget,
      );
      expect(
        find.widgetWithText(TextButton, l10n.signUpHaveAccount),
        findsOneWidget,
      );
      expect(find.widgetWithText(TextButton, l10n.legalLink), findsOneWidget);
    },
  );

  testWidgets('password mismatch: submit does not call AuthCubit.signUp', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(cubit));

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.authFieldEmail),
      'a@b.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.authFieldPassword),
      'secret1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.authFieldConfirmPassword),
      'different',
    );

    await tester.tap(find.widgetWithText(FilledButton, l10n.signUpSubmit));
    await tester.pump();

    expect(find.text(l10n.validationPasswordsDoNotMatch), findsOneWidget);
    verifyNever(
      () => cubit.signUp(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    );
  });

  testWidgets(
    'valid form: submit calls AuthCubit.signUp with trimmed email + password',
    (tester) async {
      when(
        () => cubit.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async {});

      await tester.pumpWidget(_wrap(cubit));

      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.authFieldEmail),
        '  seller@example.com  ',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.authFieldPassword),
        'secret1',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, l10n.authFieldConfirmPassword),
        'secret1',
      );

      await tester.tap(find.widgetWithText(FilledButton, l10n.signUpSubmit));
      await tester.pump();

      verify(
        () => cubit.signUp(email: 'seller@example.com', password: 'secret1'),
      ).called(1);
    },
  );

  testWidgets(
    'needsEmailConfirmation: shows the check-your-email message via SnackBar',
    (tester) async {
      when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
      whenListen(
        cubit,
        Stream<AuthState>.fromIterable(const [
          AuthState.authenticating(),
          AuthState.needsEmailConfirmation(),
        ]),
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(_wrap(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text(l10n.signUpConfirmEmail), findsOneWidget);
    },
  );
}
