import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/utils/compare_tray_visual_policy.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_floating_tray.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_layer.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_overlay.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_dock_shield.dart'
    show CompareTrayCapsuleBackplate;
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

CompareListingSnapshot _snapshot(String id) => CompareListingSnapshot(
  listingId: id,
  addedAt: DateTime.utc(2026, 5, 1),
  coverImageUrl: 'https://example.com/$id.jpg',
  make: 'BMW',
  model: '3',
);

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

  Future<void> pumpHost(
    WidgetTester tester, {
    required CompareTrayVisualPolicy policy,
  }) async {
    final router = GoRouter(
      initialLocation: AppRoutes.listings,
      routes: [
        GoRoute(
          path: AppRoutes.listings,
          builder: (_, _) => const Scaffold(
            body: ColoredBox(
              color: Color(0xFFFF00FF),
              child: Center(child: Text('feed')),
            ),
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
            visualPolicy: policy,
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('audit: fly disabled still shows tray on add/remove', (
    tester,
  ) async {
    await cubit.addSnapshot(_snapshot('a'));
    await pumpHost(tester, policy: CompareTrayVisualPolicy.auditNoFly);

    expect(find.byType(CompareFlyToTrayOverlaySlot), findsNothing);
    expect(find.byType(CompareFloatingTray), findsOneWidget);

    await cubit.addSnapshot(_snapshot('b'));
    await tester.pump();
    await cubit.remove('b');
    await tester.pumpAndSettle();

    expect(find.byType(CompareFlyToTrayOverlay), findsNothing);
    expect(find.byType(CompareFloatingTray), findsOneWidget);
  });

  testWidgets('audit: solid thumbnails use no Image widgets', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    await pumpHost(tester, policy: CompareTrayVisualPolicy.auditSolidThumbs);

    expect(find.byType(Image), findsNothing);
    expect(find.byType(CompareFloatingTray), findsOneWidget);
  });

  testWidgets('audit: no AnimatedSwitcher on tray host', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    await pumpHost(tester, policy: CompareTrayVisualPolicy.production);

    expect(find.byType(AnimatedSwitcher), findsNothing);
  });

  testWidgets('production tray uses compact capsule backplate', (tester) async {
    await cubit.addSnapshot(_snapshot('a'));
    await pumpHost(tester, policy: CompareTrayVisualPolicy.production);

    expect(
      find.byKey(CompareTrayCapsuleBackplate.backplateKey),
      findsOneWidget,
    );
    expect(find.byType(SizedBox), findsWidgets);

    final backplateBox = tester.renderObject<RenderBox>(
      find.byKey(CompareTrayCapsuleBackplate.backplateKey),
    );
    final screenBox = tester.renderObject<RenderBox>(find.byType(Stack).first);
    expect(backplateBox.size.width, lessThan(screenBox.size.width * 0.98));
    expect(backplateBox.size.height, lessThan(CompareFloatingTray.height + 24));
  });
}
