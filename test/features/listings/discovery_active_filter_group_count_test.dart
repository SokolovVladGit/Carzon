import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/discovery_feed_chip_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  ListingsState vanillaTransnistria() => const ListingsState(
        status: ListingsStatus.success,
        regionFilter: MarketRegionFilter.transnistria,
      );

  test(
    'listingsDiscoveryActiveFilterGroupCount matches chip labels cardinality',
    () {
      final l10n = ruStrings();
      final states = [
        vanillaTransnistria(),
        vanillaTransnistria().copyWith(make: 'Skoda'),
        vanillaTransnistria().copyWith(
          make: 'Skoda',
          model: ' Octavia ',
        ),
        vanillaTransnistria().copyWith(minYear: 2018, maxYear: 2022),
        vanillaTransnistria().copyWith(minYear: null, maxYear: 2024),
        vanillaTransnistria().copyWith(minPrice: 1000, maxPrice: null),
        vanillaTransnistria().copyWith(
          priceCurrencyFilter: ListingPriceCurrencyFilter.usd,
        ),
        vanillaTransnistria().copyWith(maxMileage: 150000),
        vanillaTransnistria().copyWith(city: '  Tiraspol  '),
        vanillaTransnistria().copyWith(
          regionFilter: MarketRegionFilter.moldova,
        ),
        vanillaTransnistria().copyWith(regionFilter: MarketRegionFilter.both),
        vanillaTransnistria().copyWith(
          bodyTypeFilter: ListingBodyType.suv,
        ),
        vanillaTransnistria().copyWith(typeFilter: ListingTypeFilter.exchange),
        vanillaTransnistria().copyWith(
          sortOption: ListingSortOption.priceLowToHigh,
        ),
        vanillaTransnistria().copyWith(
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
    expect(listingsDiscoveryActiveFilterGroupCount(vanillaTransnistria()), 0);
  });

  test('single make yields 1', () {
    expect(
      listingsDiscoveryActiveFilterGroupCount(
        vanillaTransnistria().copyWith(make: 'Skoda'),
      ),
      1,
    );
  });

  test('concurrent groups count exceeds 9 (parity with chip cardinality)', () {
    final l10n = ruStrings();
    final s = vanillaTransnistria().copyWith(
      search: 't',
      make: 'Toyota',
      model: 'Corolla',
      minYear: 2010,
      maxYear: 2020,
      minPrice: 1000,
      maxPrice: 15000,
      maxMileage: 90000,
      city: 'Bender',
      regionFilter: MarketRegionFilter.both,
      bodyTypeFilter: ListingBodyType.sedan,
      typeFilter: ListingTypeFilter.sale,
      sortOption: ListingSortOption.lowestMileageFirst,
    );
    final count = listingsDiscoveryActiveFilterGroupCount(s);
    expect(count, listingsDiscoveryChipLabels(s, l10n).length);
    expect(count, greaterThan(9));
  });
}
