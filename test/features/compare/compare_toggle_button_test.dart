import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/compare/presentation/widgets/compare_toggle_button.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

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

Listing _listing({String id = 'l1'}) => Listing(
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

void main() {
  final ru = ruStrings();
  late _MemoryCompareRepository repo;
  late CompareCubit cubit;

  setUp(() {
    repo = _MemoryCompareRepository();
    cubit = CompareCubit(repository: repo);
  });

  tearDown(() => cubit.close());

  Widget harness({required Widget child, required Listing listing}) {
    return MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider.value(
        value: cubit,
        child: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('tap adds listing without success snackbar', (tester) async {
    final listing = _listing();
    await tester.pumpWidget(
      harness(
        listing: listing,
        child: CompareToggleButton.fromListing(listing),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('compare_toggle_l1')));
    await tester.pump();
    await tester.pump();

    expect(cubit.state.containsListing('l1'), isTrue);
    expect(find.text(ru.compareAddedMessage), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('selected tap removes without success snackbar', (tester) async {
    final listing = _listing();
    await cubit.addSnapshot(CompareListingSnapshot.fromListing(listing));

    await tester.pumpWidget(
      harness(
        listing: listing,
        child: CompareToggleButton.fromListing(listing),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('compare_toggle_l1')));
    await tester.pump();
    await tester.pump();

    expect(cubit.state.containsListing('l1'), isFalse);
    expect(find.text(ru.compareRemovedMessage), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('when full and not in compare blocks add without snackbar', (
    tester,
  ) async {
    for (var i = 0; i < 3; i++) {
      await cubit.addSnapshot(
        CompareListingSnapshot.fromListing(_listing(id: 'x$i')),
      );
    }
    final listing = _listing(id: 'new');
    await tester.pumpWidget(
      harness(
        listing: listing,
        child: CompareToggleButton.fromListing(listing),
      ),
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('compare_toggle_new')));
    await tester.pump();
    await tester.pump();

    expect(cubit.state.count, 3);
    expect(cubit.state.containsListing('new'), isFalse);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
    'when full but already in compare tapping removes without snackbar',
    (tester) async {
      for (var i = 0; i < 3; i++) {
        await cubit.addSnapshot(
          CompareListingSnapshot.fromListing(_listing(id: 'x$i')),
        );
      }
      final inSet = _listing(id: 'x0');
      await tester.pumpWidget(
        harness(listing: inSet, child: CompareToggleButton.fromListing(inSet)),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('compare_toggle_x0')));
      await tester.pump();
      await tester.pump();

      expect(cubit.state.containsListing('x0'), isFalse);
      expect(find.text(ru.compareRemovedMessage), findsNothing);
    },
  );
}
