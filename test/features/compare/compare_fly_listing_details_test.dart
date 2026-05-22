import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_floating_tray.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_fly_to_tray_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_toggle_button.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_feedback_controller.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_tray_host.dart';
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

Listing _listing() => Listing(
  id: 'l1',
  title: 'Test',
  make: 'BMW',
  model: '3',
  year: 2018,
  priceEur: 15000,
  mileageKm: 80000,
  type: ListingType.sale,
  city: 'Chișinău',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 4, 1),
  sellerId: 's1',
  coverImageUrl: 'https://example.com/cover.jpg',
);

void main() {
  final ru = ruStrings();

  testWidgets('adding compare on listing details shows tray above contact bar', (
    tester,
  ) async {
    final repo = _MemoryCompareRepository();
    final cubit = CompareCubit(repository: repo);
    final flyController = CompareFlyToTrayController();
    final feedbackController = CompareTrayFeedbackController();
    addTearDown(() async {
      flyController.cancel();
      feedbackController.dispose();
      await cubit.close();
    });

    final listing = _listing();
    final router = GoRouter(
      initialLocation: '/listings/l1',
      routes: [
        GoRoute(
          path: '/listings/:id',
          builder: (_, _) => Scaffold(
            bottomNavigationBar: const SizedBox(
              height: 70,
              key: ValueKey('mock_contact_bar'),
            ),
            body: Center(
              child: CompareToggleButton.fromListing(
                listing,
                density: CompareToggleDensity.hero,
              ),
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
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CompareToggleButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pumpAndSettle();

    expect(cubit.state.containsListing('l1'), isTrue);
    expect(find.text(ru.compareAddedMessage), findsNothing);
    expect(find.byType(CompareFloatingTray), findsOneWidget);
    expect(flyController.isAnimating, isFalse);
  });
}
