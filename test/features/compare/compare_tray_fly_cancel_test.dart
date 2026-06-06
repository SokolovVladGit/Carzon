import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_overlay.dart';
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

  testWidgets('route change to compare cancels active fly animation', (
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

    final router = GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Scaffold(body: Text('home')),
        ),
        GoRoute(
          path: AppRoutes.compare,
          builder: (_, _) => const Scaffold(body: Text('compare')),
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

    flyController.play(
      const CompareFlyAnimationPayload(
        sourceRect: Rect.fromLTWH(40, 40, 100, 80),
        traySlotRect: Rect.fromLTWH(18, 400, 300, 68),
      ),
    );
    await tester.pump();
    expect(flyController.isAnimating, isTrue);

    router.go(AppRoutes.compare);
    await tester.pump();
    await tester.pump();

    expect(flyController.isAnimating, isFalse);
    expect(flyController.active, isNull);
    expect(find.byType(CompareFlyToTrayOverlay), findsNothing);
  });
}
