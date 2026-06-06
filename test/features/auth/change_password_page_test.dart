import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/core/widgets/auth_required_prompt.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:carzon/features/auth/domain/usecases/update_password.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/auth/presentation/bloc/change_password_cubit.dart';
import 'package:carzon/features/auth/presentation/pages/change_password_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  late _MockAuthCubit authCubit;
  late _MockRepo repo;
  final l10n = ruStrings();
  const user = AuthUser(id: 'u1', email: 'seller@example.com');

  setUp(() async {
    await sl.reset();
    authCubit = _MockAuthCubit();
    repo = _MockRepo();
    when(
      () => repo.signInWithPassword(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async => const Success(user));
    when(
      () => repo.updatePassword(any()),
    ).thenAnswer((_) async => const Success(null));
    sl.registerFactory<ChangePasswordCubit>(
      () => ChangePasswordCubit(
        signInWithPassword: SignInWithPassword(repo),
        updatePassword: UpdatePassword(repo),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  Widget app(AuthState authState) {
    when(() => authCubit.state).thenReturn(authState);
    whenListen(
      authCubit,
      const Stream<AuthState>.empty(),
      initialState: authState,
    );
    final router = GoRouter(
      initialLocation: AppRoutes.changePassword,
      routes: [
        GoRoute(
          path: AppRoutes.changePassword,
          builder: (_, _) => BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const ChangePasswordPage(),
          ),
        ),
        GoRoute(
          path: AppRoutes.profile,
          builder: (_, _) => const Scaffold(body: Text('profile')),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => const Scaffold(body: Text('sign-in')),
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

  testWidgets('signed-out direct route shows AuthRequiredPrompt', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AuthState.unauthenticated()));
    await tester.pumpAndSettle();

    expect(find.byType(AuthRequiredPrompt), findsOneWidget);
    expect(find.text(l10n.profileSignInRequired), findsOneWidget);
  });

  testWidgets('signed-in page renders header card and form card', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AuthState.authenticated(user)));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('change_password_header_card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('change_password_form_card')),
      findsOneWidget,
    );
    expect(find.text(l10n.changePasswordIntro), findsOneWidget);
    expect(find.text(l10n.changePasswordSecurityNote), findsOneWidget);
  });

  testWidgets(
    'password fields are obscured by default and toggles reveal them',
    (tester) async {
      await tester.pumpWidget(app(const AuthState.authenticated(user)));
      await tester.pumpAndSettle();

      final currentField = find.widgetWithText(
        TextFormField,
        l10n.changePasswordCurrentPassword,
      );
      final newField = find.widgetWithText(
        TextFormField,
        l10n.changePasswordNewPassword,
      );
      final confirmField = find.widgetWithText(
        TextFormField,
        l10n.changePasswordConfirmPassword,
      );

      bool isObscured(Finder field) {
        return tester
            .widget<EditableText>(
              find.descendant(of: field, matching: find.byType(EditableText)),
            )
            .obscureText;
      }

      expect(isObscured(currentField), isTrue);
      expect(isObscured(newField), isTrue);
      expect(isObscured(confirmField), isTrue);

      await tester.tap(
        find.byKey(const ValueKey('change_password_current_visibility_toggle')),
      );
      await tester.tap(
        find.byKey(const ValueKey('change_password_new_visibility_toggle')),
      );
      await tester.tap(
        find.byKey(const ValueKey('change_password_confirm_visibility_toggle')),
      );
      await tester.pumpAndSettle();

      expect(isObscured(currentField), isFalse);
      expect(isObscured(newField), isFalse);
      expect(isObscured(confirmField), isFalse);

      await tester.tap(
        find.byKey(const ValueKey('change_password_current_visibility_toggle')),
      );
      await tester.pumpAndSettle();

      expect(isObscured(currentField), isTrue);
    },
  );

  testWidgets(
    'empty fields show validation errors and do not call auth layer',
    (tester) async {
      await tester.pumpWidget(app(const AuthState.authenticated(user)));
      await tester.pumpAndSettle();

      await tester.tap(
        find.widgetWithText(FilledButton, l10n.changePasswordSubmit),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.validationPasswordRequired), findsWidgets);
      verifyNever(
        () => repo.signInWithPassword(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
      verifyNever(() => repo.updatePassword(any()));
    },
  );

  testWidgets('password mismatch shows validation error', (tester) async {
    await tester.pumpWidget(app(const AuthState.authenticated(user)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordCurrentPassword),
      'oldpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordNewPassword),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordConfirmPassword),
      'different',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.changePasswordSubmit),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.validationPasswordsDoNotMatch), findsOneWidget);
    verifyNever(() => repo.updatePassword(any()));
  });

  testWidgets('successful password change shows success and clears fields', (
    tester,
  ) async {
    await tester.pumpWidget(app(const AuthState.authenticated(user)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordCurrentPassword),
      'oldpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordNewPassword),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordConfirmPassword),
      'newpass1',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.changePasswordSubmit),
    );
    await tester.pumpAndSettle();

    verify(
      () => repo.signInWithPassword(
        email: 'seller@example.com',
        password: 'oldpass1',
      ),
    ).called(1);
    verify(() => repo.updatePassword('newpass1')).called(1);
    expect(find.text(l10n.changePasswordSuccess), findsOneWidget);
    expect(find.text('oldpass1'), findsNothing);
    expect(find.text('newpass1'), findsNothing);
  });

  testWidgets('password change failure shows recoverable localized error', (
    tester,
  ) async {
    when(() => repo.updatePassword(any())).thenAnswer(
      (_) async => const FailureResult(AuthFailure('backend rejected')),
    );

    await tester.pumpWidget(app(const AuthState.authenticated(user)));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordCurrentPassword),
      'oldpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordNewPassword),
      'newpass1',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, l10n.changePasswordConfirmPassword),
      'newpass1',
    );
    await tester.tap(
      find.widgetWithText(FilledButton, l10n.changePasswordSubmit),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.changePasswordFailedRetry), findsOneWidget);
    expect(find.textContaining('backend rejected'), findsNothing);
  });
}
