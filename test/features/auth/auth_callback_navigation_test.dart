import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/auth_callback_navigation.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  GoRouter router() {
    return GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Text('home', key: Key('home-route')),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          builder: (_, _) => const Text('sign-in', key: Key('sign-in-route')),
        ),
        GoRoute(
          path: AppRoutes.resetPassword,
          builder: (_, _) => const Text('reset', key: Key('reset-route')),
        ),
      ],
    );
  }

  test('recovery intent is stored before the navigator mounts', () {
    final goRouter = router();

    openPasswordResetIfRecovery(goRouter, const AuthState.passwordRecovery());

    expect(
      goRouter.routeInformationProvider.value.uri.path,
      AppRoutes.resetPassword,
    );

    openPasswordResetIfRecovery(goRouter, const AuthState.passwordRecovery());
    expect(
      goRouter.routeInformationProvider.value.uri.path,
      AppRoutes.resetPassword,
    );
  });

  testWidgets('a pre-mount recovery route is visible on the first frame', (
    tester,
  ) async {
    final goRouter = router();
    openPasswordResetIfRecovery(goRouter, const AuthState.passwordRecovery());

    await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));

    expect(find.byKey(const Key('reset-route')), findsOneWidget);
  });

  test('authenticated and confirmation states do not open reset', () {
    final goRouter = router();

    openPasswordResetIfRecovery(
      goRouter,
      const AuthState.authenticated(AuthUser(id: 'u1', email: 'a@b.c')),
    );
    openPasswordResetIfRecovery(
      goRouter,
      const AuthState.needsEmailConfirmation(),
    );

    expect(
      goRouter.routeInformationProvider.value.uri.path,
      AppRoutes.listings,
    );
  });

  testWidgets('a recovery event while the app is mounted opens reset', (
    tester,
  ) async {
    final goRouter = router();
    await tester.pumpWidget(MaterialApp.router(routerConfig: goRouter));
    expect(find.byKey(const Key('home-route')), findsOneWidget);

    openPasswordResetIfRecovery(goRouter, const AuthState.passwordRecovery());
    await tester.pump();
    await tester.pump();

    expect(find.byKey(const Key('reset-route')), findsOneWidget);
  });
}
