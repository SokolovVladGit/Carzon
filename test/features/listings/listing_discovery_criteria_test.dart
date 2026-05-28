import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ListingDiscoveryCriteria', () {
    test(
      'defaults match unfiltered feed dimensions (besides pagination/status)',
      () {
        const c = ListingDiscoveryCriteria();
        expect(
          c.hasNonRegionConstraints(),
          isFalse,
          reason: 'empty criteria should read as no user filters',
        );
        final q = c.toListingsQuery(
          page: 2,
          pageSize: AppConstants.defaultPageSize,
          status: ListingStatus.active,
        );
        expect(q.search, isNull);
        expect(q.make, isNull);
        expect(q.model, isNull);
        expect(q.minYear, isNull);
        expect(q.maxYear, isNull);
        expect(q.minPrice, isNull);
        expect(q.maxPrice, isNull);
        expect(q.maxMileage, isNull);
        expect(q.city, isNull);
        expect(q.marketRegion, isNull);
        expect(q.bodyType, isNull);
        expect(q.typeIn, isNull);
        expect(q.sort, ListingSortOption.newestFirst);
        expect(q.page, 2);
        expect(q.pageSize, AppConstants.defaultPageSize);
        expect(q.status, ListingStatus.active);
        expect(q.priceCurrency, isNull);
      },
    );

    test('priceCurrencyFilter maps to ListingsQuery.priceCurrency', () {
      const c = ListingDiscoveryCriteria(
        priceCurrencyFilter: ListingPriceCurrencyFilter.usd,
      );
      final q = c.toListingsQuery(
        page: 0,
        pageSize: 20,
        status: ListingStatus.active,
      );
      expect(q.priceCurrency, ListingCurrency.usd);
    });

    test(
      'hasNonRegionConstraints is true when price currency is constrained',
      () {
        const c = ListingDiscoveryCriteria(
          priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
        );
        expect(c.hasNonRegionConstraints(), isTrue);
      },
    );

    test('priceCurrency any omits currency predicate on query', () {
      const c = ListingDiscoveryCriteria(
        priceCurrencyFilter: ListingPriceCurrencyFilter.any,
      );
      final q = c.toListingsQuery(
        page: 0,
        pageSize: 20,
        status: ListingStatus.active,
      );
      expect(q.priceCurrency, isNull);
    });

    test('hasNonRegionConstraints is true when sort differs from default', () {
      const c = ListingDiscoveryCriteria(
        sort: ListingSortOption.priceLowToHigh,
      );
      expect(c.hasNonRegionConstraints(), isTrue);
    });

    test('trims text dimensions in ListingsQuery mapping', () {
      const c = ListingDiscoveryCriteria(
        search: '  alpha ',
        make: ' BMW ',
        model: ' x5 ',
        city: ' chisinau ',
        sort: ListingSortOption.newestYearFirst,
      );
      final q = c.toListingsQuery(
        page: 0,
        pageSize: 10,
        status: ListingStatus.active,
      );
      expect(q.search, 'alpha');
      expect(q.make, 'BMW');
      expect(q.model, 'x5');
      expect(q.city, 'chisinau');
      expect(q.sort, ListingSortOption.newestYearFirst);
    });

    test('maps numeric bounds into query', () {
      const c = ListingDiscoveryCriteria(
        minYear: 2015,
        maxYear: 2020,
        minPrice: 1000,
        maxPrice: 5000,
        maxMileage: 150000,
        marketRegion: MarketRegion.moldova,
        bodyType: ListingBodyType.suv,
      );
      final q = c.toListingsQuery(
        page: 0,
        pageSize: 20,
        status: ListingStatus.active,
      );
      expect(q.minYear, 2015);
      expect(q.maxYear, 2020);
      expect(q.minPrice, 1000);
      expect(q.maxPrice, 5000);
      expect(q.maxMileage, 150000);
      expect(q.marketRegion, MarketRegion.moldova);
      expect(q.bodyType, ListingBodyType.suv);
      expect(q.priceCurrency, isNull);
    });
  });
}
