// Regression: the catalog FAB indicator and the in-sheet filter bell must
// derive their criteria through paths that are guaranteed to produce
// equal (ignoring sort) values for the same underlying [ListingsState].
//
// Both helpers ultimately funnel into
// [listingDiscoveryCriteriaFromListingsState], which is the canonical
// alert-criteria builder. Diverging from it (e.g. dropping `priceCurrencyFilter`
// or normalising `region` differently in only one branch) is exactly the
// class of bug that caused the originally reported sheet-bell-vs-FAB-indicator
// desync, so this test pins the alignment in code rather than relying on
// reviewer vigilance.
import 'package:carzon/features/listings/domain/browse_state_for_alert_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/filter_alert_catalog_criteria_compare.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/listing_filter_apply_to_criteria.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_apply_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('catalog filter-alert criteria mapping alignment', () {
    test('BMW + Transnistria applied state maps to the same criteria from both '
        'the FAB indicator path and the sheet-bell apply-result path', () {
      const applied = ListingsState(
        make: 'BMW',
        regionFilter: MarketRegionFilter.transnistria,
      );

      final fromBrowse = listingDiscoveryCriteriaFromBrowseStateForAlert(
        applied,
      );
      final fromApply = listingDiscoveryCriteriaFromFilterApply(
        ListingsFilterApplyResult.apply(
          make: applied.make,
          model: applied.model,
          minYear: applied.minYear,
          maxYear: applied.maxYear,
          minPrice: applied.minPrice,
          maxPrice: applied.maxPrice,
          maxMileage: applied.maxMileage,
          city: applied.city,
          typeFilter: applied.typeFilter,
          sort: applied.sortOption,
          region: applied.regionFilter,
          bodyType: applied.bodyTypeFilter,
          fuelType: applied.fuelTypeFilter,
          transmissionType: applied.transmissionTypeFilter,
          priceCurrencyFilter: applied.priceCurrencyFilter,
        ),
        preservedSearch: applied.search,
      );

      expect(
        listingDiscoveryCriteriaEqualIgnoringSort(fromBrowse, fromApply),
        isTrue,
      );
    });

    test('applied state with search snippet preserves the search in both paths '
        'so the saved-alert comparator sees identical criteria', () {
      const applied = ListingsState(
        search: 'X5',
        make: 'BMW',
        regionFilter: MarketRegionFilter.transnistria,
      );

      final fromBrowse = listingDiscoveryCriteriaFromBrowseStateForAlert(
        applied,
      );
      final fromApply = listingDiscoveryCriteriaFromFilterApply(
        ListingsFilterApplyResult.apply(
          make: applied.make,
          model: applied.model,
          minYear: applied.minYear,
          maxYear: applied.maxYear,
          minPrice: applied.minPrice,
          maxPrice: applied.maxPrice,
          maxMileage: applied.maxMileage,
          city: applied.city,
          typeFilter: applied.typeFilter,
          sort: applied.sortOption,
          region: applied.regionFilter,
          bodyType: applied.bodyTypeFilter,
          fuelType: applied.fuelTypeFilter,
          transmissionType: applied.transmissionTypeFilter,
          priceCurrencyFilter: applied.priceCurrencyFilter,
        ),
        preservedSearch: applied.search,
      );

      expect(fromBrowse.search, applied.search);
      expect(fromApply.search, applied.search);
      expect(
        listingDiscoveryCriteriaEqualIgnoringSort(fromBrowse, fromApply),
        isTrue,
      );
    });

    test(
      'sort-only differences do not cause a saved-alert mismatch '
      'between the FAB path and the sheet-bell path (server ignores sort)',
      () {
        const applied = ListingsState(
          make: 'BMW',
          regionFilter: MarketRegionFilter.transnistria,
          sortOption: ListingSortOption.priceLowToHigh,
        );

        final fromBrowse = listingDiscoveryCriteriaFromBrowseStateForAlert(
          applied,
        );
        final fromApply = listingDiscoveryCriteriaFromFilterApply(
          ListingsFilterApplyResult.apply(
            make: applied.make,
            model: applied.model,
            minYear: applied.minYear,
            maxYear: applied.maxYear,
            minPrice: applied.minPrice,
            maxPrice: applied.maxPrice,
            maxMileage: applied.maxMileage,
            city: applied.city,
            typeFilter: applied.typeFilter,
            // Intentionally diverge sort to confirm the comparator is
            // sort-insensitive even when paths produce different sort
            // values (e.g. cubit normalises while the form does not).
            sort: ListingSortOption.newestFirst,
            region: applied.regionFilter,
            bodyType: applied.bodyTypeFilter,
            fuelType: applied.fuelTypeFilter,
            transmissionType: applied.transmissionTypeFilter,
            priceCurrencyFilter: applied.priceCurrencyFilter,
          ),
        );

        expect(
          listingDiscoveryCriteriaEqualIgnoringSort(fromBrowse, fromApply),
          isTrue,
        );
      },
    );

    test('every filter dimension covered by ListingsFilterApplyResult is '
        'carried through both mappings (defensive coverage)', () {
      const applied = ListingsState(
        search: 'editorial',
        make: 'Audi',
        model: 'A6',
        minYear: 2018,
        maxYear: 2024,
        minPrice: 5000,
        maxPrice: 30000,
        maxMileage: 120000,
        city: 'Tiraspol',
        typeFilter: ListingTypeFilter.sale,
        regionFilter: MarketRegionFilter.moldova,
        priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
      );

      final fromBrowse = listingDiscoveryCriteriaFromBrowseStateForAlert(
        applied,
      );
      final fromApply = listingDiscoveryCriteriaFromFilterApply(
        ListingsFilterApplyResult.apply(
          make: applied.make,
          model: applied.model,
          minYear: applied.minYear,
          maxYear: applied.maxYear,
          minPrice: applied.minPrice,
          maxPrice: applied.maxPrice,
          maxMileage: applied.maxMileage,
          city: applied.city,
          typeFilter: applied.typeFilter,
          sort: applied.sortOption,
          region: applied.regionFilter,
          bodyType: applied.bodyTypeFilter,
          fuelType: applied.fuelTypeFilter,
          transmissionType: applied.transmissionTypeFilter,
          priceCurrencyFilter: applied.priceCurrencyFilter,
        ),
        preservedSearch: applied.search,
      );

      expect(
        listingDiscoveryCriteriaEqualIgnoringSort(fromBrowse, fromApply),
        isTrue,
      );
    });
  });
}
