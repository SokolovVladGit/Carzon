import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/compare/presentation/utils/compare_fly_to_tray_logic.dart';
import 'package:carzon/features/compare/presentation/utils/compare_fly_to_tray_runner.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

void main() {
  testWidgets('requestCompareFlyToTray does not crash without source key', (
    tester,
  ) async {
    final controller = CompareFlyToTrayController();
    addTearDown(controller.cancel);

    final router = GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );

    final context = tester.element(find.text('home'));
    requestCompareFlyToTray(
      context: context,
      controller: controller,
      sourceKey: null,
      imageUrl: null,
      itemWasAdded: true,
      trayWasHiddenBeforeAdd: true,
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(controller.isAnimating, isFalse);
  });

  testWidgets('requestCompareFlyToTray runs on listing details when tray is laid out', (
    tester,
  ) async {
    final controller = CompareFlyToTrayController();
    addTearDown(controller.cancel);
    final sourceKey = GlobalKey();

    final router = GoRouter(
      initialLocation: '/listings/abc',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (context, _) => MediaQuery(
            data: const MediaQueryData(disableAnimations: false),
            child: Scaffold(
              body: SizedBox(
                key: sourceKey,
                width: 100,
                height: 80,
                child: ElevatedButton(
                  onPressed: () => requestCompareFlyToTray(
                    context: context,
                    controller: controller,
                    sourceKey: sourceKey,
                    imageUrl: 'https://example.com/a.jpg',
                    itemWasAdded: true,
                    trayWasHiddenBeforeAdd: false,
                  ),
                  child: const Text('trigger_fly'),
                ),
              ),
            ),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context).copyWith(disableAnimations: false),
          child: SizedBox.expand(
          child: Stack(
            children: [
              if (child != null) child!,
              Positioned(
              left: 18,
              right: 18,
              bottom: 82,
              child: KeyedSubtree(
                key: controller.trayFlyTargetKey,
                child: const SizedBox(height: 68, width: 200),
              ),
              ),
            ],
          ),
        ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(measureGlobalRect(sourceKey), isNotNull);
    expect(measureGlobalRect(controller.trayFlyTargetKey), isNotNull);

    await tester.tap(find.text('trigger_fly'));
    await tester.pump();
    await tester.pump();

    expect(controller.isAnimating, isTrue);
  });
}
