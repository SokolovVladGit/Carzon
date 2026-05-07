import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/features/auth/presentation/bloc/forgot_password_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/forgot_password_state.dart';
import 'package:carzon/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockForgotCubit extends MockCubit<ForgotPasswordState>
    implements ForgotPasswordCubit {}

void main() {
  late _MockForgotCubit cubit;
  final l10n = ruStrings();

  setUp(() async {
    await sl.reset();
    cubit = _MockForgotCubit();
    when(() => cubit.state).thenReturn(const ForgotPasswordState.idle());
    whenListen(
      cubit,
      const Stream<ForgotPasswordState>.empty(),
      initialState: const ForgotPasswordState.idle(),
    );
    sl.registerFactory<ForgotPasswordCubit>(() => cubit);
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders email field, submit button, and back navigation', (
    tester,
  ) async {
    await pumpLocalizedWidget(tester, const ForgotPasswordPage());

    expect(
      find.widgetWithText(TextFormField, l10n.authFieldEmail),
      findsOneWidget,
    );
    expect(
      find.widgetWithText(FilledButton, l10n.forgotPasswordSubmit),
      findsOneWidget,
    );
    expect(find.widgetWithText(TextButton, l10n.backToSignIn), findsOneWidget);
  });

  testWidgets('submitting a valid email calls the cubit', (tester) async {
    when(() => cubit.submit(any())).thenAnswer((_) async {});

    await pumpLocalizedWidget(tester, const ForgotPasswordPage());

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.authFieldEmail),
      '  seller@example.com  ',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.forgotPasswordSubmit),
    );
    await tester.pump();

    verify(() => cubit.submit('  seller@example.com  ')).called(1);
  });

  testWidgets('does not call the cubit when the email is missing', (
    tester,
  ) async {
    await pumpLocalizedWidget(tester, const ForgotPasswordPage());

    await tester.tap(
      find.widgetWithText(FilledButton, l10n.forgotPasswordSubmit),
    );
    await tester.pump();

    expect(find.text(l10n.validationEmailRequired), findsOneWidget);
    verifyNever(() => cubit.submit(any()));
  });

  testWidgets('success state shows non-enumerating confirmation copy', (
    tester,
  ) async {
    when(() => cubit.state).thenReturn(const ForgotPasswordState.success());
    whenListen(
      cubit,
      Stream<ForgotPasswordState>.fromIterable(const [
        ForgotPasswordState.success(),
      ]),
      initialState: const ForgotPasswordState.success(),
    );

    await pumpLocalizedWidget(tester, const ForgotPasswordPage());

    expect(find.text(l10n.forgotPasswordSuccess), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.backToSignIn),
      findsOneWidget,
    );
  });
}
