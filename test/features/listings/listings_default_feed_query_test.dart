import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:flutter_test/flutter_test.dart';

/// Ensures the home feed’s default bloc state maps to a query with no
/// accidental optional filters (regression guard after Stage 1 discovery).
ListingsQuery _queryFromListingsState(ListingsState state) {
  return ListingDiscoveryCriteria(
    search: state.search,
    make: state.make,
    model: state.model,
    minYear: state.minYear,
    maxYear: state.maxYear,
    minPrice: state.minPrice,
    maxPrice: state.maxPrice,
    maxMileage: state.maxMileage,
    city: state.city,
    marketRegion: state.regionFilter.asMarketRegion,
    bodyType: state.bodyTypeFilter,
    typeIn: state.typeFilter.asListingTypes,
    sort: state.sortOption,
    priceCurrencyFilter: state.priceCurrencyFilter,
  ).toListingsQuery(
    page: 0,
    pageSize: AppConstants.defaultPageSize,
    status: ListingStatus.active,
  );
}

void main() {
  group('Default listings feed query', () {
    test(
      'initial ListingsState applies only active + default region + sort',
      () {
        const state = ListingsState();
        final q = _queryFromListingsState(state);
        expect(q.status, ListingStatus.active);
        expect(q.marketRegion, MarketRegion.transnistria);
        expect(q.sort, ListingSortOption.newestFirst);
        expect(q.search, isNull);
        expect(q.make, isNull);
        expect(q.model, isNull);
        expect(q.minYear, isNull);
        expect(q.maxYear, isNull);
        expect(q.minPrice, isNull);
        expect(q.maxPrice, isNull);
        expect(q.maxMileage, isNull);
        expect(q.city, isNull);
        expect(q.bodyType, isNull);
        expect(q.typeIn, isNull);
        expect(q.sellerId, isNull);
        expect(q.page, 0);
        expect(q.pageSize, AppConstants.defaultPageSize);
        expect(q.priceCurrency, isNull);
      },
    );

    test('ListingDiscoveryCriteria blank strings do not become filters', () {
      const c = ListingDiscoveryCriteria(
        search: '   ',
        make: '',
        model: ' ',
        city: '\t',
      );
      final q = c.toListingsQuery(
        page: 0,
        pageSize: 20,
        status: ListingStatus.active,
      );
      expect(q.search, isNull);
      expect(q.make, isNull);
      expect(q.model, isNull);
      expect(q.city, isNull);
    });
  });
}
