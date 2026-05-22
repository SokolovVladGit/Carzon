import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/widgets/app_back_button.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/utils/compare_navigation.dart';
import 'package:carzon/features/compare/presentation/pages/compare_page.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_floating_tray.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_host.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

class _MemoryCompareRepository implements CompareRepository {
  List<CompareItem> items = const [];

  @override
  Future<void> clear() async => items = const [];

  @override
  Future<List<CompareItem>> loadItems() async => items;

  @override
  Future<void> saveItems(List<CompareItem> value) async => items = value;
}

void main() {
  late _MemoryCompareRepository repo;
  late CompareCubit cubit;
  late CompareFlyToTrayController flyController;
  late CompareTrayFeedbackController feedbackController;

  setUp(() {
    resetCompareTrayNavigationGuardForTests();
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

  Future<GoRouter> pumpTrayNavigationHarness(
    WidgetTester tester, {
    required String initialLocation,
    required Widget homeChild,
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => Scaffold(
            key: const ValueKey('listings-home'),
            body: homeChild,
          ),
        ),
        GoRoute(
          path: AppRoutes.favorites,
          builder: (_, _) => const Scaffold(
            key: ValueKey('favorites-home'),
            body: Text('favorites'),
          ),
        ),
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => const Scaffold(
            key: ValueKey('compare-screen'),
            body: ComparePage(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);

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
    return router;
  }

  testWidgets('tray tap pushes compare and back returns to listings', (
    tester,
  ) async {
    await cubit.addSnapshot(
      CompareListingSnapshot(
        listingId: 'a',
        addedAt: DateTime.utc(2026, 5, 1),
        make: 'BMW',
        model: '3',
      ),
    );

    final router = await pumpTrayNavigationHarness(
      tester,
      initialLocation: AppRoutes.listings,
      homeChild: const Text('feed-body'),
    );

    expect(find.byKey(const ValueKey('listings-home')), findsOneWidget);
    expect(router.canPop(), isFalse);

    await tester.tap(find.byType(CompareFloatingTray));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('compare-screen')), findsOneWidget);
    expect(router.canPop(), isTrue);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listings-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-home')), findsNothing);
    expect(find.text('feed-body'), findsOneWidget);
  });

  testWidgets('tray from favorites pushes compare and back returns to favorites', (
    tester,
  ) async {
    await cubit.addSnapshot(
      CompareListingSnapshot(
        listingId: 'b',
        addedAt: DateTime.utc(2026, 5, 1),
        make: 'Audi',
        model: 'A4',
      ),
    );

    final router = await pumpTrayNavigationHarness(
      tester,
      initialLocation: AppRoutes.favorites,
      homeChild: const SizedBox.shrink(),
    );

    await tester.tap(find.byType(CompareFloatingTray));
    await tester.pumpAndSettle();
    expect(router.canPop(), isTrue);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('favorites-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('menu-home')), findsNothing);
  });

  testWidgets('rapid tray taps push compare only once', (tester) async {
    await cubit.addSnapshot(
      CompareListingSnapshot(
        listingId: 'a',
        addedAt: DateTime.utc(2026, 5, 1),
        make: 'BMW',
        model: '3',
      ),
    );

    final router = await pumpTrayNavigationHarness(
      tester,
      initialLocation: AppRoutes.listings,
      homeChild: const Text('feed-body'),
    );

    await tester.tap(find.byType(CompareFloatingTray));
    await tester.tap(find.byType(CompareFloatingTray));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('compare-screen')), findsOneWidget);

    await tester.tap(find.byType(AppBackButton));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('listings-home')), findsOneWidget);
    expect(router.canPop(), isFalse);
  });
}
