import 'dart:convert';

import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/listing_discovery_criteria_json.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('listingDiscoveryCriteriaToJson / fromJson', () {
    void assertRoundTrip(ListingDiscoveryCriteria input) {
      final encoded = listingDiscoveryCriteriaToJson(input);
      final decoded =
          listingDiscoveryCriteriaFromJson(Map<String, dynamic>.from(encoded));
      expect(decoded, input);
    }

    test('round-trips structured automotive criteria', () {
      assertRoundTrip(
        const ListingDiscoveryCriteria(
          search: 'bmw x5',
          make: 'BMW',
          model: 'X5',
          minYear: 2015,
          maxYear: 2022,
          minPrice: 5000,
          maxPrice: 20000,
          maxMileage: 130000,
          city: 'Кишинёв',
          marketRegion: MarketRegion.moldova,
          bodyType: ListingBodyType.suv,
          typeIn: [ListingType.sale],
          sort: ListingSortOption.priceLowToHigh,
          priceCurrencyFilter: ListingPriceCurrencyFilter.usd,
        ),
      );
    });

    test('stable sort order for typeIn in JSON fingerprint', () {
      const saleFirst = ListingDiscoveryCriteria(
        typeIn: [ListingType.sale, ListingType.exchange],
      );
      const exchangeFirst = ListingDiscoveryCriteria(
        typeIn: [ListingType.exchange, ListingType.sale],
      );
      expect(
        jsonEncode(listingDiscoveryCriteriaToJson(saleFirst)),
        jsonEncode(listingDiscoveryCriteriaToJson(exchangeFirst)),
      );
    });

    test('returns null for wrong schemaVersion', () {
      expect(
        listingDiscoveryCriteriaFromJson(<String, dynamic>{
          ListingDiscoveryCriteriaJsonSchema.schemaVersionKey: 999,
          'sort': 'newest_first',
        }),
        isNull,
      );
    });

    test('drops unknown ListingType wires and ignores invalid typeIn elements', () {
      final decoded = listingDiscoveryCriteriaFromJson(<String, dynamic>{
        ListingDiscoveryCriteriaJsonSchema.schemaVersionKey: 1,
        'typeIn': ['sale', 'alien_offer', 'exchange', 42],
      });
      expect(decoded!.typeIn, [ListingType.exchange, ListingType.sale]);
    });

    test('unknown bodyType wire becomes null (safe)', () {
      final decoded = listingDiscoveryCriteriaFromJson(<String, dynamic>{
        ListingDiscoveryCriteriaJsonSchema.schemaVersionKey: 1,
        'bodyType': 'death_star',
      });
      expect(decoded!.bodyType, isNull);
    });

    test('bogus sort folds to newestFirst', () {
      final decoded = listingDiscoveryCriteriaFromJson(<String, dynamic>{
        ListingDiscoveryCriteriaJsonSchema.schemaVersionKey: 1,
        'sort': '__no_such_sort__',
      });
      expect(decoded!.sort, ListingSortOption.newestFirst);
    });

    test('EUR price currency maps through round-trip', () {
      assertRoundTrip(
        const ListingDiscoveryCriteria(
          priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
        ),
      );
    });

    test('exchange-only listing semantics round-trip', () {
      assertRoundTrip(
        const ListingDiscoveryCriteria(typeIn: [ListingType.exchange]),
      );
    });
  });
}
