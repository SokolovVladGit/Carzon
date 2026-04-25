import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/profile/presentation/pages/profile_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

Widget _wrap(Widget child, AuthCubit cubit) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: BlocProvider<AuthCubit>.value(value: cubit, child: child),
  );
}

void main() {
  late _MockAuthCubit cubit;
  final l10n = ruStrings();

  setUp(() {
    cubit = _MockAuthCubit();
  });

  testWidgets(
      'unauthenticated: shows the sign-in prompt and a Sign in button',
      (tester) async {
    when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.unauthenticated(),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));

    expect(find.text(l10n.profileSignInRequired), findsOneWidget);
    expect(
      find.widgetWithText(FilledButton, l10n.signInSubmit),
      findsOneWidget,
    );
    // Navigation actions and Sign out must NOT appear when logged out.
    expect(find.text(l10n.profileSignOut), findsNothing);
    expect(find.text(l10n.profileMyListings), findsNothing);
  });

  testWidgets(
      'authenticated: shows full name, email, navigation actions, and Sign out',
      (tester) async {
    const user = AuthUser(
      id: 'u1',
      email: 'seller@example.com',
      fullName: 'Ana Popescu',
    );
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));

    expect(find.text('Ana Popescu'), findsOneWidget);
    expect(find.text('seller@example.com'), findsOneWidget);
    expect(find.widgetWithText(ListTile, l10n.profileMyListings), findsOneWidget);
    expect(find.widgetWithText(ListTile, l10n.profileFavorites), findsOneWidget);
    expect(
      find.widgetWithText(ListTile, l10n.profileCreateListing),
      findsOneWidget,
    );
    expect(find.widgetWithText(ListTile, l10n.profileLegal), findsOneWidget);
    expect(
      find.widgetWithText(OutlinedButton, l10n.profileSignOut),
      findsOneWidget,
    );
  });

  testWidgets(
      'authenticated without full name: falls back to showing just the email',
      (tester) async {
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));

    expect(find.text('seller@example.com'), findsOneWidget);
  });

  testWidgets('Sign out button calls AuthCubit.signOut', (tester) async {
    const user = AuthUser(id: 'u1', email: 'seller@example.com');
    when(() => cubit.state).thenReturn(const AuthState.authenticated(user));
    when(() => cubit.signOut()).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await tester.pumpWidget(_wrap(const ProfilePage(), cubit));
    await tester.tap(
      find.widgetWithText(OutlinedButton, l10n.profileSignOut),
    );
    await tester.pump();

    verify(() => cubit.signOut()).called(1);
  });
}
