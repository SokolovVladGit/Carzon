import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/menu/presentation/pages/menu_page.dart';
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
    'unauthenticated: renders Sign in CTA and does not surface sign-out',
    (tester) async {
      when(() => cubit.state).thenReturn(const AuthState.unauthenticated());
      whenListen(
        cubit,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.unauthenticated(),
      );

      await tester.pumpWidget(_wrap(const MenuPage(), cubit));

      expect(find.text(l10n.commonSignIn), findsOneWidget);
      expect(find.text(l10n.profileSignOut), findsNothing);
      // The menu destinations are always visible so users can browse
      // legal/content surfaces even when logged out.
      expect(find.text(l10n.profileMyListings), findsOneWidget);
      expect(find.text(l10n.menuAccount), findsOneWidget);
      expect(find.text(l10n.profileLegal), findsOneWidget);
    },
  );

  testWidgets('authenticated: renders identity header and sign-out action', (
    tester,
  ) async {
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

    await tester.pumpWidget(_wrap(const MenuPage(), cubit));

    expect(find.text('Ana Popescu'), findsOneWidget);
    expect(find.text('seller@example.com'), findsOneWidget);
    expect(find.byKey(const ValueKey('menu_sign_out_action')), findsOneWidget);
    expect(find.text(l10n.profileSignOut), findsOneWidget);
    expect(find.text(l10n.commonSignIn), findsNothing);
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

    await tester.pumpWidget(_wrap(const MenuPage(), cubit));
    final signOutFinder = find.byKey(const ValueKey('menu_sign_out_action'));
    await tester.ensureVisible(signOutFinder);
    await tester.pumpAndSettle();
    await tester.tap(signOutFinder);
    await tester.pump();

    verify(() => cubit.signOut()).called(1);
  });
}
