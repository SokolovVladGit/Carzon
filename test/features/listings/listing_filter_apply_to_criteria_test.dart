import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/listing_filter_apply_to_criteria.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_apply_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('maps apply result to criteria and preserves search', () {
    const result = ListingsFilterApplyResult.apply(
      make: 'BMW',
      model: null,
      minYear: null,
      maxYear: null,
      minPrice: null,
      maxPrice: 20000,
      maxMileage: null,
      city: 'Кишинёв',
      typeFilter: ListingTypeFilter.any,
      sort: ListingSortOption.newestFirst,
      region: MarketRegionFilter.moldova,
      bodyType: ListingBodyType.suv,
      fuelType: ListingFuelType.hybrid,
      transmissionType: ListingTransmissionType.automatic,
      drivetrain: ListingDrivetrain.rwd,
      priceCurrencyFilter: ListingPriceCurrencyFilter.usd,
    );
    final c = listingDiscoveryCriteriaFromFilterApply(
      result,
      preservedSearch: '  xdrive  ',
    );
    expect(c.search, 'xdrive');
    expect(c.make, 'BMW');
    expect(c.city, 'Кишинёв');
    expect(c.marketRegion, MarketRegion.moldova);
    expect(c.bodyType, ListingBodyType.suv);
    expect(c.fuelType, ListingFuelType.hybrid);
    expect(c.transmissionType, ListingTransmissionType.automatic);
    expect(c.drivetrain, ListingDrivetrain.rwd);
    expect(c.maxPrice, 20000);
    expect(c.priceCurrencyFilter, ListingPriceCurrencyFilter.usd);
  });

  test(
    'clear result maps baseline; preservedSearch applies only to search',
    () {
      const result = ListingsFilterApplyResult.clear();
      final c = listingDiscoveryCriteriaFromFilterApply(
        result,
        preservedSearch: '  diesel  ',
      );
      expect(c.search, 'diesel');
      expect(c.make, isNull);
      expect(c.minPrice, isNull);
    },
  );
}
