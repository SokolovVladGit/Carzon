import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/bloc/reset_password_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/reset_password_state.dart';
import 'package:carzon/features/auth/presentation/pages/reset_password_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockResetCubit extends MockCubit<ResetPasswordState>
    implements ResetPasswordCubit {}

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
}
