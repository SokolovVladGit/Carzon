import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_floating_tray.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_dock_shield.dart'
    show CompareTrayCapsuleBackplate;
import 'package:carzon/features/compare/presentation/widgets/compare_tray_host.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MemoryCompareRepository implements CompareRepository {
  List<CompareItem> items = const [];

  @override
  Future<void> clear() async => items = const [];

  @override
  Future<List<CompareItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<CompareItem> value) async => items = value;
}

CompareListingSnapshot _snapshot(String id) => CompareListingSnapshot(
  listingId: id,
  addedAt: DateTime.utc(2026, 5, 1),
  make: 'BMW',
  model: '3',
);

void main() {
  final ru = ruStrings();
  late _MemoryCompareRepository repo;
  late CompareCubit cubit;
  late CompareFlyToTrayController flyController;
  late CompareTrayFeedbackController feedbackController;

  setUp(() {
    repo = _MemoryCompareRepository();
    cubit = CompareCubit(repository: repo);
    flyController = CompareFlyToTrayController();
    feedbackController = CompareTrayFeedbackController();
  });

  tearDown(() async {
    flyController.cancel();
    feedbackController.dispose();
    await cubit.close();
  });

  Future<void> pumpHost(
    WidgetTester tester, {
    required GoRouter router,
  }) async {
    await tester.pumpWidget(
      BlocProvider<CompareCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          routerConfig: router,
          builder: (context, child) => CompareTrayHost(
            router: router,
            flyController: flyController,
            feedbackController: feedbackController,
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  GoRouter buildRouter({String initialLocation = AppRoutes.listings}) {
    return GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => const Scaffold(
            key: ValueKey('compare-route'),
            body: Text('compare-screen'),
          ),
        ),
        GoRoute(
          path: '/listings/:id',
          builder: (_, _) => const Scaffold(body: Text('details')),
        ),
      ],
    );
  }

  testWidgets('visible tray has no AnimatedSwitcher and uses dock shield', (
    tester,
  ) async {
    await cubit.addSnapshot(_snapshot('a'));
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    expect(find.byType(AnimatedSwitcher), findsNothing);
    expect(find.byKey(CompareTrayCapsuleBackplate.backplateKey), findsOneWidget);
    expect(find.byType(CompareFloatingTray), findsOneWidget);
  });

  testWidgets('tray hidden when compare set is empty', (tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    expect(find.byType(CompareFloatingTray), findsNothing);
    expect(find.byKey(CompareTrayCapsuleBackplate.backplateKey), findsNothing);
  });

  testWidgets('tray visible when one vehicle in compare set', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    expect(find.byType(CompareFloatingTray), findsOneWidget);
    expect(find.text(ru.compareTrayOneVehicle), findsOneWidget);
  });

  testWidgets('tray hidden on compare route', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    final router = buildRouter(initialLocation: AppRoutes.compare);
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    expect(find.byType(CompareFloatingTray), findsNothing);
  });

  testWidgets('tray visible on listing details route', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    final router = buildRouter(initialLocation: '/listings/listing-1');
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    expect(find.byType(CompareFloatingTray), findsOneWidget);
  });

  testWidgets('tap tray navigates to compare', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    await tester.tap(find.byType(CompareFloatingTray));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('compare-route')), findsOneWidget);
  });

  testWidgets(
    'rapid count changes during tray transition do not duplicate fly target key',
    (tester) async {
      await cubit.addSnapshot(_snapshot('a'));
      final router = buildRouter();
      addTearDown(router.dispose);
      await pumpHost(tester, router: router);

      await cubit.addSnapshot(_snapshot('b'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 140));

      await cubit.addSnapshot(_snapshot('c'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(find.byType(CompareFloatingTray), findsOneWidget);
      expect(flyController.trayFlyTargetKey.currentContext, isNotNull);
    },
  );

  testWidgets('adding second vehicle keeps one tray during transition', (
    tester,
  ) async {
    await cubit.addSnapshot(_snapshot('a'));
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    await cubit.addSnapshot(_snapshot('b'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(find.byType(CompareFloatingTray), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(ru.compareTrayVehicleCount(2)), findsOneWidget);
  });

  testWidgets('removing vehicle keeps one tray during transition', (
    tester,
  ) async {
    await cubit.addSnapshot(_snapshot('a'));
    await cubit.addSnapshot(_snapshot('b'));
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);

    await cubit.remove('b');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 140));

    expect(find.byType(CompareFloatingTray), findsOneWidget);
    await tester.pumpAndSettle();
    expect(find.text(ru.compareTrayOneVehicle), findsOneWidget);
  });

  testWidgets('tray dismisses after clearing comparison', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    final router = buildRouter();
    addTearDown(router.dispose);
    await pumpHost(tester, router: router);
    expect(find.byType(CompareFloatingTray), findsOneWidget);

    await cubit.clear();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.byType(CompareFloatingTray), findsNothing);
  });
}
