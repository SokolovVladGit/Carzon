import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/discovery_feed_chip_labels.dart';
import 'package:carzon/features/listings/presentation/widgets/listings_active_discovery_summary_strip.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

const _chipRowKey = ValueKey<String>('listingsActiveDiscoveryChipRow');

void main() {
  Widget wrap({
    required ListingsState state,
    required ValueChanged<ListingsDiscoveryChipKind> onFilterRemoved,
    ThemeData? theme,
    double? width,
  }) {
    final strip = ListingsActiveDiscoverySummaryStrip(
      state: state,
      onFilterRemoved: onFilterRemoved,
    );
    return MaterialApp(
      theme: theme ?? ThemeData.light(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('ru'),
      home: Scaffold(
        body: width == null ? strip : SizedBox(width: width, child: strip),
      ),
    );
  }

  Rect chipRowRect(WidgetTester tester) =>
      tester.getRect(find.byKey(_chipRowKey));

  Rect stripRect(WidgetTester tester) =>
      tester.getRect(find.byType(ListingsActiveDiscoverySummaryStrip));

  testWidgets('active chips render a close affordance per chip', (
    tester,
  ) async {
    final l10n = ruStrings();
    const state = ListingsState(
      search: 'Audi',
      make: 'Skoda',
      minYear: 2022,
      maxYear: 2025,
      minPrice: 3000,
      maxPrice: 4000,
    );

    await tester.pumpWidget(wrap(state: state, onFilterRemoved: (_) {}));
    await tester.pumpAndSettle();

    expect(find.text('Skoda'), findsOneWidget);
    expect(find.text('Audi'), findsOneWidget);
    expect(find.text('2022–2025'), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('discovery-chip-remove-search')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('discovery-chip-remove-make')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('discovery-chip-remove-year')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('discovery-chip-remove-priceRange')),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (w) =>
            w.key is ValueKey<String> &&
            (w.key! as ValueKey<String>).value.startsWith(
              'discovery-chip-remove-',
            ),
      ),
      findsNWidgets(listingsDiscoveryChips(state, l10n).length),
    );
  });

  testWidgets('tapping search chip close invokes search kind callback', (
    tester,
  ) async {
    ListingsDiscoveryChipKind? removed;
    const state = ListingsState(search: 'Audi', make: 'Skoda');

    await tester.pumpWidget(
      wrap(state: state, onFilterRemoved: (kind) => removed = kind),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('discovery-chip-remove-search')),
    );
    await tester.pumpAndSettle();

    expect(removed, ListingsDiscoveryChipKind.search);
  });

  testWidgets('tapping make chip close invokes make kind callback', (
    tester,
  ) async {
    ListingsDiscoveryChipKind? removed;
    const state = ListingsState(make: 'Skoda', minPrice: 1000, maxPrice: 2000);

    await tester.pumpWidget(
      wrap(state: state, onFilterRemoved: (kind) => removed = kind),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('discovery-chip-remove-make')),
    );
    await tester.pumpAndSettle();

    expect(removed, ListingsDiscoveryChipKind.make);
  });

  testWidgets('tapping year chip close invokes year kind callback', (
    tester,
  ) async {
    ListingsDiscoveryChipKind? removed;
    const state = ListingsState(make: 'Skoda', minYear: 2022, maxYear: 2025);

    await tester.pumpWidget(
      wrap(state: state, onFilterRemoved: (kind) => removed = kind),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('discovery-chip-remove-year')),
    );
    await tester.pumpAndSettle();

    expect(removed, ListingsDiscoveryChipKind.year);
  });

  testWidgets('tapping price chip close invokes priceRange kind callback', (
    tester,
  ) async {
    ListingsDiscoveryChipKind? removed;
    const state = ListingsState(
      make: 'Skoda',
      minYear: 2022,
      maxYear: 2025,
      minPrice: 3000,
      maxPrice: 4000,
      priceCurrencyFilter: ListingPriceCurrencyFilter.usd,
    );

    await tester.pumpWidget(
      wrap(state: state, onFilterRemoved: (kind) => removed = kind),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey<String>('discovery-chip-remove-priceRange')),
    );
    await tester.pumpAndSettle();

    expect(removed, ListingsDiscoveryChipKind.priceRange);
  });

  testWidgets('default state hides chip remove controls', (tester) async {
    await tester.pumpWidget(
      wrap(state: const ListingsState(), onFilterRemoved: (_) {}),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ListingsActiveDiscoverySummaryStrip), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('discovery-chip-remove-make')),
      findsNothing,
    );
  });

  testWidgets('close semantics uses remove-filter tooltip copy', (
    tester,
  ) async {
    final l10n = ruStrings();
    const state = ListingsState(make: 'Skoda');

    await tester.pumpWidget(wrap(state: state, onFilterRemoved: (_) {}));
    await tester.pumpAndSettle();

    final handle = tester.ensureSemantics();
    expect(
      find.bySemanticsLabel(
        '${l10n.listingsDiscoveryFilterRemoveTooltip}: '
        '${l10n.filterMake}: Skoda',
      ),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('close affordance renders in dark theme', (tester) async {
    const state = ListingsState(make: 'Skoda');

    await tester.pumpWidget(
      wrap(state: state, onFilterRemoved: (_) {}, theme: ThemeData.dark()),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('discovery-chip-remove-make')),
      findsOneWidget,
    );
  });

  testWidgets('one chip is centered in the available strip width', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(
        state: const ListingsState(make: 'Skoda'),
        onFilterRemoved: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final row = chipRowRect(tester);
    final strip = stripRect(tester);
    expect(row.width, lessThan(strip.width));
    expect(row.center.dx, closeTo(strip.center.dx, 1.5));
  });

  testWidgets('two chips are centered when they fit', (tester) async {
    await tester.pumpWidget(
      wrap(
        state: const ListingsState(make: 'Skoda', search: 'Octavia'),
        onFilterRemoved: (_) {},
      ),
    );
    await tester.pumpAndSettle();

    final row = chipRowRect(tester);
    final strip = stripRect(tester);
    expect(row.width, lessThan(strip.width));
    expect(row.center.dx, closeTo(strip.center.dx, 1.5));
  });

  testWidgets(
    'overflowing chips stay leading-aligned and horizontally scrollable',
    (tester) async {
      const overflowing = ListingsState(
        search: 'длинный поисковый запрос',
        make: 'Mercedes-Benz',
        model: 'G-Class',
        minYear: 2018,
        maxYear: 2024,
        minPrice: 15000,
        maxPrice: 45000,
        city: 'Тирасполь',
        bodyTypeFilter: ListingBodyType.suv,
      );
      await tester.pumpWidget(
        wrap(state: overflowing, onFilterRemoved: (_) {}, width: 320),
      );
      await tester.pumpAndSettle();

      final row = chipRowRect(tester);
      final strip = stripRect(tester);
      expect(row.width, greaterThan(strip.width));
      expect(row.left, closeTo(strip.left + 16, 2));

      final before = row.left;
      await tester.drag(
        find.descendant(
          of: find.byType(ListingsActiveDiscoverySummaryStrip),
          matching: find.byType(Scrollable),
        ),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();
      expect(chipRowRect(tester).left, lessThan(before - 8));
    },
  );

  testWidgets('removing chips can switch overflow to a centered row', (
    tester,
  ) async {
    const overflowing = ListingsState(
      search: 'длинный поисковый запрос',
      make: 'Mercedes-Benz',
      model: 'G-Class',
      minYear: 2018,
      maxYear: 2024,
      city: 'Тирасполь',
    );
    const oneChip = ListingsState(make: 'Skoda');

    await tester.pumpWidget(
      wrap(state: overflowing, onFilterRemoved: (_) {}, width: 320),
    );
    await tester.pumpAndSettle();
    expect(chipRowRect(tester).width, greaterThan(stripRect(tester).width));

    await tester.pumpWidget(
      wrap(state: oneChip, onFilterRemoved: (_) {}, width: 320),
    );
    await tester.pumpAndSettle();

    final row = chipRowRect(tester);
    final strip = stripRect(tester);
    expect(row.width, lessThan(strip.width));
    expect(row.center.dx, closeTo(strip.center.dx, 1.5));
  });
}
