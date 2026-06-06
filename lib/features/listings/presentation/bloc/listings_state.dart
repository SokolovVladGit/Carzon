import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_currency.dart';
import '../../domain/entities/listing_sort_option.dart';

enum ListingsStatus {
  initial,
  loading,
  loadingMore,
  success,
  failure,
  paginationFailure,
}

/// Presentation-level tri-state selector for the feed region filter.
/// Maps to [MarketRegion]? via [asMarketRegion] — `both` means no region
/// filter is applied.
enum MarketRegionFilter { transnistria, moldova, both }

extension MarketRegionFilterX on MarketRegionFilter {
  MarketRegion? get asMarketRegion {
    switch (this) {
      case MarketRegionFilter.transnistria:
        return MarketRegion.transnistria;
      case MarketRegionFilter.moldova:
        return MarketRegion.moldova;
      case MarketRegionFilter.both:
        return null;
    }
  }
}

/// Presentation-level selector for the feed listing-type filter.
///
/// Semantics:
///   - [any]      → no type filter
///   - [sale]     → include `sale` and `both` (exchange-ready listings
///                  willing to sell still match)
///   - [exchange] → include `exchange` and `both`
enum ListingTypeFilter { any, sale, exchange }

extension ListingTypeFilterX on ListingTypeFilter {
  /// Returns the set of [ListingType] values a listing may have to match
  /// this filter, or `null` when no type filter should be applied.
  List<ListingType>? get asListingTypes {
    switch (this) {
      case ListingTypeFilter.any:
        return null;
      case ListingTypeFilter.sale:
        return const [ListingType.sale, ListingType.both];
      case ListingTypeFilter.exchange:
        return const [ListingType.exchange, ListingType.both];
    }
  }
}

class ListingsState extends Equatable {
  const ListingsState({
    this.status = ListingsStatus.initial,
    this.items = const [],
    this.page = 0,
    this.hasReachedEnd = false,
    this.search,
    this.make,
    this.model,
    this.minYear,
    this.maxYear,
    this.minPrice,
    this.maxPrice,
    this.maxMileage,
    this.city,
    this.typeFilter = ListingTypeFilter.any,
    this.regionFilter = MarketRegionFilter.transnistria,
    this.bodyTypeFilter,
    this.sortOption = ListingSortOption.newestFirst,
    this.priceCurrencyFilter = ListingPriceCurrencyFilter.any,
    this.loadFailure,
  });

  final ListingsStatus status;
  final List<Listing> items;
  final int page;
  final bool hasReachedEnd;

  // Filter fields. `null` / `any` / `both` means "no filter for this field".
  final String? search;
  final String? make;
  final String? model;
  final int? minYear;
  final int? maxYear;
  final num? minPrice;
  final num? maxPrice;
  final int? maxMileage;
  final String? city;
  final ListingTypeFilter typeFilter;
  final MarketRegionFilter regionFilter;

  /// Home feed body-style filter. Null means all body types.
  final ListingBodyType? bodyTypeFilter;

  /// Optional constraint on `listings.price_currency`. [any] does not filter
  /// by currency; amount bounds still use `price_eur` only.
  final ListingPriceCurrencyFilter priceCurrencyFilter;

  /// Feed ordering (public active listings only).
  final ListingSortOption sortOption;

  final Failure? loadFailure;

  bool get hasActiveNonRegionFilters =>
      (search != null && search!.isNotEmpty) ||
      (make != null && make!.isNotEmpty) ||
      (model != null && model!.isNotEmpty) ||
      minYear != null ||
      maxYear != null ||
      minPrice != null ||
      maxPrice != null ||
      maxMileage != null ||
      (city != null && city!.isNotEmpty) ||
      typeFilter != ListingTypeFilter.any ||
      bodyTypeFilter != null ||
      sortOption != ListingSortOption.newestFirst ||
      priceCurrencyFilter != ListingPriceCurrencyFilter.any;

  /// Includes the region picker: the default feed is Transnistria-only; Moldova
  /// or "all regions" counts as an active choice for empty states and chrome.
  bool get hasActiveDiscoveryConstraints =>
      hasActiveNonRegionFilters ||
      regionFilter != MarketRegionFilter.transnistria;

  ListingsState copyWith({
    ListingsStatus? status,
    List<Listing>? items,
    int? page,
    bool? hasReachedEnd,
    String? search,
    String? make,
    String? model,
    int? minYear,
    int? maxYear,
    num? minPrice,
    num? maxPrice,
    int? maxMileage,
    String? city,
    ListingTypeFilter? typeFilter,
    MarketRegionFilter? regionFilter,
    ListingBodyType? bodyTypeFilter,
    ListingSortOption? sortOption,
    ListingPriceCurrencyFilter? priceCurrencyFilter,
    Failure? loadFailure,
    bool clearSearch = false,
    bool clearMake = false,
    bool clearModel = false,
    bool clearMinYear = false,
    bool clearMaxYear = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
    bool clearMaxMileage = false,
    bool clearCity = false,
    bool clearBodyType = false,
    bool clearSort = false,
    bool clearPriceCurrencyFilter = false,
    bool clearLoadFailure = false,
  }) {
    return ListingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      search: clearSearch ? null : (search ?? this.search),
      make: clearMake ? null : (make ?? this.make),
      model: clearModel ? null : (model ?? this.model),
      minYear: clearMinYear ? null : (minYear ?? this.minYear),
      maxYear: clearMaxYear ? null : (maxYear ?? this.maxYear),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      maxMileage: clearMaxMileage ? null : (maxMileage ?? this.maxMileage),
      city: clearCity ? null : (city ?? this.city),
      typeFilter: typeFilter ?? this.typeFilter,
      regionFilter: regionFilter ?? this.regionFilter,
      bodyTypeFilter: clearBodyType
          ? null
          : (bodyTypeFilter ?? this.bodyTypeFilter),
      sortOption: clearSort
          ? ListingSortOption.newestFirst
          : (sortOption ?? this.sortOption),
      priceCurrencyFilter: clearPriceCurrencyFilter
          ? ListingPriceCurrencyFilter.any
          : (priceCurrencyFilter ?? this.priceCurrencyFilter),
      loadFailure: clearLoadFailure ? null : (loadFailure ?? this.loadFailure),
    );
  }

  @override
  List<Object?> get props => [
    status,
    items,
    page,
    hasReachedEnd,
    search,
    make,
    model,
    minYear,
    maxYear,
    minPrice,
    maxPrice,
    maxMileage,
    city,
    typeFilter,
    regionFilter,
    bodyTypeFilter,
    priceCurrencyFilter,
    sortOption,
    loadFailure,
  ];
}
