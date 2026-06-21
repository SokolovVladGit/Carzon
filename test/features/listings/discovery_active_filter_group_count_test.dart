import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/discovery_feed_chip_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  ListingsState vanillaAllRegions() => const ListingsState(
    status: ListingsStatus.success,
    regionFilter: MarketRegionFilter.both,
  );

  test(
    'listingsDiscoveryActiveFilterGroupCount matches chip labels cardinality',
    () {
      final l10n = ruStrings();
      final states = [
        vanillaAllRegions(),
        vanillaAllRegions().copyWith(make: 'Skoda'),
        vanillaAllRegions().copyWith(make: 'Skoda', model: ' Octavia '),
        vanillaAllRegions().copyWith(minYear: 2018, maxYear: 2022),
        vanillaAllRegions().copyWith(minYear: null, maxYear: 2024),
        vanillaAllRegions().copyWith(minPrice: 1000, maxPrice: null),
        vanillaAllRegions().copyWith(
          priceCurrencyFilter: ListingPriceCurrencyFilter.usd,
        ),
        vanillaAllRegions().copyWith(maxMileage: 150000),
        vanillaAllRegions().copyWith(city: '  Tiraspol  '),
        vanillaAllRegions().copyWith(regionFilter: MarketRegionFilter.moldova),
        vanillaAllRegions().copyWith(
          regionFilter: MarketRegionFilter.transnistria,
        ),
        vanillaAllRegions().copyWith(bodyTypeFilter: ListingBodyType.suv),
        vanillaAllRegions().copyWith(fuelTypeFilter: ListingFuelType.hybrid),
        vanillaAllRegions().copyWith(
          transmissionTypeFilter: ListingTransmissionType.automatic,
        ),
        vanillaAllRegions().copyWith(drivetrainFilter: ListingDrivetrain.awd),
        vanillaAllRegions().copyWith(typeFilter: ListingTypeFilter.exchange),
        vanillaAllRegions().copyWith(
          sortOption: ListingSortOption.priceLowToHigh,
        ),
        vanillaAllRegions().copyWith(
          search: ' diesel ',
          make: 'VW',
          minPrice: 1,
          maxPrice: 2,
          sortOption: ListingSortOption.priceHighToLow,
          regionFilter: MarketRegionFilter.moldova,
        ),
      ];
      for (final s in states) {
        expect(
          listingsDiscoveryActiveFilterGroupCount(s),
          listingsDiscoveryChipLabels(s, l10n).length,
          reason: '$s',
        );
      }
    },
  );

  test('defaults yield 0 groups', () {
    expect(listingsDiscoveryActiveFilterGroupCount(vanillaAllRegions()), 0);
  });

  test('single make yields 1', () {
    expect(
      listingsDiscoveryActiveFilterGroupCount(
        vanillaAllRegions().copyWith(make: 'Skoda'),
      ),
      1,
    );
  });

  test('concurrent groups count exceeds 9 (parity with chip cardinality)', () {
    final l10n = ruStrings();
    final s = vanillaAllRegions().copyWith(
      search: 't',
      make: 'Toyota',
      model: 'Corolla',
      minYear: 2010,
      maxYear: 2020,
      minPrice: 1000,
      maxPrice: 15000,
      maxMileage: 90000,
      city: 'Bender',
      regionFilter: MarketRegionFilter.transnistria,
      bodyTypeFilter: ListingBodyType.sedan,
      typeFilter: ListingTypeFilter.sale,
      sortOption: ListingSortOption.lowestMileageFirst,
    );
    final count = listingsDiscoveryActiveFilterGroupCount(s);
    expect(count, listingsDiscoveryChipLabels(s, l10n).length);
    expect(count, greaterThan(9));
  });
}
