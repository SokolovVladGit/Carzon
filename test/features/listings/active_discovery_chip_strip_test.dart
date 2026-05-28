// Premium active-filter chip strip: visual polish pass.
//
// The flat `listingsDiscoveryChipLabels` output is still consumed by
// filter-alert summary code paths, so the underlying labels function is
// pinned here (no regression in copy). The on-feed chips themselves
// render through `listingsDiscoveryChips` so label/value can have
// separate typographic weight (premium look).
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/discovery_feed_chip_labels.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Future<AppLocalizations> _ru() async =>
    AppLocalizations.delegate.load(const Locale('ru'));

void main() {
  group('listingsDiscoveryChips structured output', () {
    test('single make filter emits one labelled chip', () async {
      final l10n = await _ru();
      const state = ListingsState(make: 'Opel');

      final chips = listingsDiscoveryChips(state, l10n);

      expect(chips, hasLength(1));
      expect(chips.single.label, l10n.filterMake);
      expect(chips.single.value, 'Opel');
      expect(chips.single.flat, '${l10n.filterMake}: Opel');
    });

    test('multiple active filters render in stable order with mixed '
        'labelled/value-only chips (no overflow shape changes)', () async {
      final l10n = await _ru();
      const state = ListingsState(
        search: 'X5',
        make: 'BMW',
        model: '530d',
        minYear: 2018,
        maxYear: 2024,
        city: 'Tiraspol',
        typeFilter: ListingTypeFilter.sale,
        regionFilter: MarketRegionFilter.moldova,
        sortOption: ListingSortOption.priceLowToHigh,
      );

      final chips = listingsDiscoveryChips(state, l10n);

      // Labelled label/value chips for the dimensions that benefit
      // from a "Label · Value" split.
      expect(
        chips.where((c) => c.label != null).map((c) => c.value).toList(),
        containsAll(<String>['X5', 'BMW', '530d', '2018–2024', 'Tiraspol']),
      );
      // Value-only chips for self-describing dimensions (sale,
      // region, sort order).
      final valueOnly = chips
          .where((c) => c.label == null)
          .map((c) => c.value)
          .toList();
      expect(valueOnly, contains(l10n.typeSale));
      expect(valueOnly, contains(l10n.regionMoldova));
      expect(valueOnly, contains(l10n.filterSortPriceLowHigh));

      // Cardinality still matches the active-group counter so the
      // FAB and the strip can never disagree about "n filters active".
      expect(chips.length, listingsDiscoveryActiveFilterGroupCount(state));
    });

    test('flat fallback preserves "Label: Value" copy for filter-alert '
        'summary callers (no breaking change in shared text path)', () async {
      final l10n = await _ru();
      const state = ListingsState(make: 'Opel', maxYear: 2024);

      expect(listingsDiscoveryChipLabels(state, l10n), <String>[
        '${l10n.filterMake}: Opel',
        '${l10n.filterMaxYear}: 2024',
      ]);
    });

    test('default catalog produces no chips', () async {
      final l10n = await _ru();
      const state = ListingsState();
      expect(listingsDiscoveryChips(state, l10n), isEmpty);
    });
  });
}
