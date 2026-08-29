import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/account/presentation/cubit/delete_account_cubit.dart';
import 'package:carzon/features/account/presentation/cubit/delete_account_state.dart';
import 'package:carzon/features/account/presentation/pages/delete_account_page.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockDeleteAccountCubit extends MockCubit<DeleteAccountState>
    implements DeleteAccountCubit {}

const _deleteAccountListingsStubKey = ValueKey<String>(
  'delete_account_test_listings_stub',
);

GoRouter _deleteAccountTestRouter({required AuthCubit authCubit}) {
  return GoRouter(
    initialLocation: AppRoutes.deleteAccount,
    routes: [
      GoRoute(
        path: AppRoutes.listings,
        builder: (_, _) => const Scaffold(key: _deleteAccountListingsStubKey),
      ),
      GoRoute(
        path: AppRoutes.deleteAccount,
        builder: (_, _) => BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const DeleteAccountPage(),
        ),
      ),
    ],
  );
}

Widget _deleteAccountTestApp({required AuthCubit authCubit}) {
  return MaterialApp.router(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    routerConfig: _deleteAccountTestRouter(authCubit: authCubit),
  );
}

void main() {
  late _MockAuthCubit authCubit;
  late _MockDeleteAccountCubit deleteAccountCubit;
  final l10n = ruStrings();
  final roL10n = roStrings();

  const testUser = AuthUser(
    id: 'user-1',
    email: 'seller@example.com',
    fullName: 'Test Seller',
  );

  setUp(() {
    authCubit = _MockAuthCubit();
    deleteAccountCubit = _MockDeleteAccountCubit();
    when(() => authCubit.state).thenReturn(
      const AuthState(status: AuthStatus.authenticated, user: testUser),
    );
    when(() => authCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => deleteAccountCubit.state).thenReturn(const DeleteAccountState());
    when(
      () => deleteAccountCubit.stream,
    ).thenAnswer((_) => const Stream.empty());
    when(() => deleteAccountCubit.submit()).thenAnswer((_) async {});
    when(() => authCubit.markUnauthenticatedAfterAccountDeletion()).thenAnswer((
      _,
    ) {
      when(
        () => authCubit.state,
      ).thenReturn(const AuthState.unauthenticated(publicFeedRefreshNonce: 1));
    });

    if (sl.isRegistered<DeleteAccountCubit>()) {
      sl.unregister<DeleteAccountCubit>();
    }
    sl.registerFactory<DeleteAccountCubit>(() => deleteAccountCubit);
  });

  tearDown(() {
    if (sl.isRegistered<DeleteAccountCubit>()) {
      sl.unregister<DeleteAccountCubit>();
    }
  });

  testWidgets('Delete account page renders warnings', (tester) async {
    await tester.pumpWidget(_deleteAccountTestApp(authCubit: authCubit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.deleteAccountTitle), findsOneWidget);
    expect(find.text(l10n.deleteAccountWarningTitle), findsOneWidget);
    expect(find.text(l10n.deleteAccountWarningBody), findsOneWidget);
    expect(l10n.deleteAccountWarningBody, contains('псевдонимизированные'));
    expect(l10n.deleteAccountWarningBody, contains('хеш VIN'));
  });

  test(
    'RU and RO deletion disclosure names retained safety/cache categories',
    () {
      expect(l10n.deleteAccountWarningBody, contains('псевдонимизированные'));
      expect(l10n.deleteAccountWarningBody, contains('хеш VIN'));
      expect(l10n.deleteAccountWarningBody, contains('цен на топливо'));
      expect(roL10n.deleteAccountWarningBody, contains('pseudonimizate'));
      expect(roL10n.deleteAccountWarningBody, contains('hash-ul VIN'));
      expect(
        roL10n.deleteAccountWarningBody,
        contains('prețuri la combustibil'),
      );
    },
  );

  testWidgets('submit disabled until confirmation keyword typed', (
    tester,
  ) async {
    await tester.pumpWidget(_deleteAccountTestApp(authCubit: authCubit));
    await tester.pumpAndSettle();

    final submit = find.byKey(const ValueKey('delete_account_submit_button'));
    expect(tester.widget<FilledButton>(submit).onPressed, isNull);

    await tester.enterText(
      find.byKey(const ValueKey('delete_account_confirmation_field')),
      l10n.deleteAccountConfirmationKeyword,
    );
    await tester.pumpAndSettle();

    expect(tester.widget<FilledButton>(submit).onPressed, isNotNull);

    await tester.tap(submit);
    await tester.pumpAndSettle();

    verify(() => deleteAccountCubit.submit()).called(1);
  });

  testWidgets('successful delete syncs auth state and navigates to listings', (
    tester,
  ) async {
    whenListen(
      deleteAccountCubit,
      Stream.fromIterable([
        const DeleteAccountState(status: DeleteAccountStatus.success),
      ]),
      initialState: const DeleteAccountState(),
    );

    await tester.pumpWidget(_deleteAccountTestApp(authCubit: authCubit));
    await tester.pumpAndSettle();

    verify(() => authCubit.markUnauthenticatedAfterAccountDeletion()).called(1);
    verifyNever(() => authCubit.signOut());
    expect(find.byKey(_deleteAccountListingsStubKey), findsOneWidget);
  });

  testWidgets('confirmation keyword match is case-insensitive', (tester) async {
    await tester.pumpWidget(_deleteAccountTestApp(authCubit: authCubit));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('delete_account_confirmation_field')),
      l10n.deleteAccountConfirmationKeyword.toLowerCase(),
    );
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<FilledButton>(
            find.byKey(const ValueKey('delete_account_submit_button')),
          )
          .onPressed,
      isNotNull,
    );
  });
}
