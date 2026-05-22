import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_state.dart';
import 'package:carzon/features/compare/presentation/utils/compare_tray_feedback_runner.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_floating_tray.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_toggle_button.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_host.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_limit_feedback.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
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

Listing _listing({required String id}) => Listing(
  id: id,
  title: 'Test',
  make: 'Audi',
  model: 'A4',
  year: 2020,
  priceEur: 10000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Chișinău',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 5, 1),
  status: ListingStatus.active,
  sellerId: 's1',
);

CompareListingSnapshot _snapshot(String id) => CompareListingSnapshot(
  listingId: id,
  addedAt: DateTime.utc(2026, 5, 1),
  make: 'Audi',
  model: 'A4',
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

  Future<void> pumpHostWithToggle(
    WidgetTester tester, {
    required Listing blockedListing,
    GlobalKey? flySourceKey,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => Scaffold(
            body: Center(
              child: CompareToggleButton.fromListing(
                blockedListing,
                flySourceKey: flySourceKey,
              ),
            ),
          ),
        ),
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => const Scaffold(
            key: ValueKey('compare-route'),
            body: Text('compare-screen'),
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
  }

  Future<void> fillCompareSet() async {
    for (var i = 0; i < CompareState.maxItems; i++) {
      await cubit.addSnapshot(_snapshot('x$i'));
    }
  }

  testWidgets('blocked add shows tray limit feedback without snackbar', (
    tester,
  ) async {
    await fillCompareSet();
    final listing = _listing(id: 'new');
    await pumpHostWithToggle(tester, blockedListing: listing);

    await tester.tap(find.byKey(const ValueKey('compare_toggle_new')));
    await tester.pump();
    await tester.pump();

    expect(cubit.state.count, 3);
    expect(cubit.state.containsListing('new'), isFalse);
    expect(find.byType(SnackBar), findsNothing);
    expect(find.text(ru.compareTrayMaxLimitTitle), findsOneWidget);
    expect(find.text(ru.compareTrayMaxLimitHint), findsOneWidget);
    expect(find.byType(CompareTrayLimitFeedback), findsOneWidget);
    expect(find.byType(CompareFloatingTray), findsNothing);

    await tester.pump(kCompareTrayMaxLimitFeedbackDuration);
    await tester.pump();
  });

  testWidgets('limit feedback auto-dismisses and tray returns', (tester) async {
    await fillCompareSet();
    await pumpHostWithToggle(tester, blockedListing: _listing(id: 'new'));

    showCompareTrayMaxLimitFeedback(controller: feedbackController);
    await tester.pump();
    expect(find.byType(CompareTrayLimitFeedback), findsOneWidget);

    await tester.pump(kCompareTrayMaxLimitFeedbackDuration);
    await tester.pump();

    expect(find.byType(CompareTrayLimitFeedback), findsNothing);
    expect(find.byType(CompareFloatingTray), findsOneWidget);
  });

  testWidgets('tap tray navigates after limit feedback dismissed', (
    tester,
  ) async {
    await cubit.addSnapshot(_snapshot('only'));
    final router = GoRouter(
      initialLocation: AppRoutes.listings,
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

    showCompareTrayMaxLimitFeedback(controller: feedbackController);
    await tester.pump();
    await tester.pump(kCompareTrayMaxLimitFeedbackDuration);
    await tester.pump();

    await tester.tap(find.byType(CompareFloatingTray));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('compare-route')), findsOneWidget);
  });

  testWidgets('blocked add does not start fly animation', (tester) async {
    final sourceKey = GlobalKey();
    await fillCompareSet();
    await pumpHostWithToggle(
      tester,
      blockedListing: _listing(id: 'new'),
      flySourceKey: sourceKey,
    );

    await tester.tap(find.byKey(const ValueKey('compare_toggle_new')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(flyController.isAnimating, isFalse);

    await tester.pump(kCompareTrayMaxLimitFeedbackDuration);
    await tester.pump();
  });
}
