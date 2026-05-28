import 'package:carzon/features/listings/domain/browse_state_for_alert_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/filter_alert_catalog_criteria_compare.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listingDiscoveryCriteriaEqualIgnoringSort', () {
    test('two browse snapshots mirror each other symmetrically', () {
      const feed = ListingsState(
        make: 'Toyota',
        regionFilter: MarketRegionFilter.transnistria,
      );
      final first = listingDiscoveryCriteriaFromBrowseStateForAlert(feed);
      final second = listingDiscoveryCriteriaFromBrowseStateForAlert(feed);

      expect(listingDiscoveryCriteriaEqualIgnoringSort(first, second), isTrue);
    });

    test('differs only by sort ordering', () {
      final base = ListingDiscoveryCriteria(
        make: 'BMW',
        marketRegion: MarketRegion.transnistria,
        sort: ListingSortOption.lowestMileageFirst,
      );

      expect(
        listingDiscoveryCriteriaEqualIgnoringSort(
          base,
          ListingDiscoveryCriteria(
            make: base.make,
            marketRegion: base.marketRegion,
            sort: ListingSortOption.priceHighToLow,
          ),
        ),
        isTrue,
      );
    });

    test('narrows Toyota vs Mazda feeds', () {
      const toyotaCrit = ListingDiscoveryCriteria(make: 'Toyota');
      const mazdaCrit = ListingDiscoveryCriteria(make: 'Mazda');

      expect(
        listingDiscoveryCriteriaEqualIgnoringSort(toyotaCrit, mazdaCrit),
        isFalse,
      );
    });
  });
}
