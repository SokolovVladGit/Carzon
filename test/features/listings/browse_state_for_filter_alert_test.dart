import 'package:carzon/features/listings/domain/browse_state_for_alert_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/listing_discovery_criteria_json.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listingDiscoveryCriteriaFromBrowseStateForAlert', () {
    test('maps search plus every sheet-backed dimension into criteria', () {
      const state = ListingsState(
        search: '  hybrid  ',
        make: 'Toyota',
        model: 'Prius',
        city: 'Кишинёв',
        minYear: 2018,
        maxYear: 2022,
        minPrice: 5000,
        maxPrice: 12000,
        maxMileage: 95000,
        typeFilter: ListingTypeFilter.exchange,
        regionFilter: MarketRegionFilter.both,
        bodyTypeFilter: ListingBodyType.hatchback,
        sortOption: ListingSortOption.lowestMileageFirst,
        priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
      );

      final c = listingDiscoveryCriteriaFromBrowseStateForAlert(state);

      expect(c.search, state.search);
      expect(c.make, state.make);
      expect(c.model, state.model);
      expect(c.city, state.city);
      expect(c.minYear, 2018);
      expect(c.maxYear, 2022);
      expect(c.minPrice, 5000);
      expect(c.maxPrice, 12000);
      expect(c.maxMileage, 95000);
      expect(
        c.marketRegion,
        isNull,
      ); // Both → unconstrained regions in SQL JSON
      expect(c.bodyType, ListingBodyType.hatchback);
      expect(
        c.typeIn,
        containsAll(<ListingType>[ListingType.exchange, ListingType.both]),
      );
      expect(c.priceCurrencyFilter, ListingPriceCurrencyFilter.eur);
      expect(c.sort, ListingSortOption.lowestMileageFirst);

      final json = listingDiscoveryCriteriaToJson(c);
      expect(json['search'], state.search);
      expect(json['sort'], 'lowest_mileage_first');
    });

    test('null search stays null when absent', () {
      const state = ListingsState(
        make: 'BMW',
        regionFilter: MarketRegionFilter.transnistria,
      );
      final c = listingDiscoveryCriteriaFromBrowseStateForAlert(state);
      expect(c.search, isNull);
      expect(c.make, 'BMW');
    });

    test(
      'sort is carried for codec parity even though Postgres matcher ignores it',
      () {
        const state = ListingsState(
          search: 'v8',
          sortOption: ListingSortOption.priceLowToHigh,
          regionFilter: MarketRegionFilter.moldova,
        );
        final c = listingDiscoveryCriteriaFromBrowseStateForAlert(state);
        expect(c.sort, ListingSortOption.priceLowToHigh);
        expect(listingDiscoveryCriteriaToJson(c)['sort'], 'price_low_to_high');
        // Narrowing predicates still come from search + region moldova — not asserting SQL here.
      },
    );
  });

  group('browseStateEligibleForFilterAlertSnapshot', () {
    test('rejects baseline default catalog snapshot', () {
      expect(
        browseStateEligibleForFilterAlertSnapshot(const ListingsState()),
        isFalse,
      );
    });

    test('rejects sort-only deviation from baseline', () {
      expect(
        browseStateEligibleForFilterAlertSnapshot(
          const ListingsState(sortOption: ListingSortOption.priceLowToHigh),
        ),
        isFalse,
      );
    });

    test('allows search-only on otherwise default baseline', () {
      expect(
        browseStateEligibleForFilterAlertSnapshot(
          const ListingsState(search: 'sedan'),
        ),
        isTrue,
      );
    });

    test('allows non-sort constraint with default sort option', () {
      expect(
        browseStateEligibleForFilterAlertSnapshot(
          const ListingsState(make: 'Audi'),
        ),
        isTrue,
      );
    });

    test('allows region picker change Moldova-only with no extra filters', () {
      expect(
        browseStateEligibleForFilterAlertSnapshot(
          const ListingsState(regionFilter: MarketRegionFilter.moldova),
        ),
        isTrue,
      );
    });
  });
}
