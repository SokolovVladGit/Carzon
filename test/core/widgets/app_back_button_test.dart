import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Builds a minimal two-screen `go_router` harness. The `/` screen
/// navigates to `/second` via the provided [navigate] callback, and
/// `/second` renders an [AppBackButton]. Tests can exercise both the
/// pushed-stack path (back pops to `/`) and the direct-landing path
/// (back uses the fallback route).
MaterialApp _harness({
  required String initialLocation,
  required void Function(BuildContext context) navigateToSecond,
  String fallback = '/',
}) {
  final router = GoRouter(
    initialLocation: initialLocation,
    routes: [
      GoRoute(
        path: '/',
        builder: (_, _) => Scaffold(
          body: Builder(
            builder: (context) => Center(
              child: ElevatedButton(
                onPressed: () => navigateToSecond(context),
                child: const Text('go-to-second'),
              ),
            ),
          ),
        ),
      ),
      GoRoute(
        path: '/second',
        builder: (_, _) => Scaffold(
          appBar: AppBar(
            leading: AppBackButton(fallback: fallback),
            title: const Text('second'),
          ),
        ),
      ),
      GoRoute(
        path: '/fallback-landing',
        builder: (_, _) =>
            const Scaffold(body: Center(child: Text('fallback-landing'))),
      ),
    ],
  );
  return MaterialApp.router(routerConfig: router);
}

void main() {
  group('AppBackButton', () {
    testWidgets('pops when a back stack exists (pushed route)', (tester) async {
      await tester.pumpWidget(
        _harness(
          initialLocation: '/',
          navigateToSecond: (context) => context.push('/second'),
        ),
      );

      await tester.tap(find.text('go-to-second'));
      await tester.pumpAndSettle();
      expect(find.text('second'), findsOneWidget);

      await tester.tap(find.byType(BackButtonIcon));
      await tester.pumpAndSettle();

      expect(find.text('second'), findsNothing);
      expect(find.text('go-to-second'), findsOneWidget);
    });

    testWidgets(
      'navigates to fallback when there is no back stack (deep-link)',
      (tester) async {
        await tester.pumpWidget(
          _harness(
            initialLocation: '/second',
            navigateToSecond: (_) {},
            fallback: '/fallback-landing',
          ),
        );
        expect(find.text('second'), findsOneWidget);

        await tester.tap(find.byType(BackButtonIcon));
        await tester.pumpAndSettle();

        expect(find.text('second'), findsNothing);
        expect(find.text('fallback-landing'), findsOneWidget);
      },
    );

    testWidgets('renders a visible back arrow icon button', (tester) async {
      await tester.pumpWidget(
        _harness(initialLocation: '/second', navigateToSecond: (_) {}),
      );

      expect(find.byType(AppBackButton), findsOneWidget);
      expect(find.byType(BackButtonIcon), findsOneWidget);
      expect(find.byType(IconButton), findsWidgets);
    });
  });
}
