import 'package:equatable/equatable.dart';

import '../../domain/entities/listing.dart';

enum ListingsStatus { initial, loading, loadingMore, success, failure }

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
    this.minYear,
    this.maxYear,
    this.typeFilter = ListingTypeFilter.any,
    this.regionFilter = MarketRegionFilter.transnistria,
    this.bodyTypeFilter,
    this.errorMessage,
  });

  final ListingsStatus status;
  final List<Listing> items;
  final int page;
  final bool hasReachedEnd;

  // Filter fields. `null` / `any` / `both` means "no filter for this field".
  final String? search;
  final String? make;
  final int? minYear;
  final int? maxYear;
  final ListingTypeFilter typeFilter;
  final MarketRegionFilter regionFilter;

  /// Home feed body-style filter. Null means all body types.
  final ListingBodyType? bodyTypeFilter;

  final String? errorMessage;

  bool get hasActiveNonRegionFilters =>
      (search != null && search!.isNotEmpty) ||
      (make != null && make!.isNotEmpty) ||
      minYear != null ||
      maxYear != null ||
      typeFilter != ListingTypeFilter.any ||
      bodyTypeFilter != null;

  ListingsState copyWith({
    ListingsStatus? status,
    List<Listing>? items,
    int? page,
    bool? hasReachedEnd,
    String? search,
    String? make,
    int? minYear,
    int? maxYear,
    ListingTypeFilter? typeFilter,
    MarketRegionFilter? regionFilter,
    ListingBodyType? bodyTypeFilter,
    String? errorMessage,
    bool clearSearch = false,
    bool clearMake = false,
    bool clearMinYear = false,
    bool clearMaxYear = false,
    bool clearBodyType = false,
  }) {
    return ListingsState(
      status: status ?? this.status,
      items: items ?? this.items,
      page: page ?? this.page,
      hasReachedEnd: hasReachedEnd ?? this.hasReachedEnd,
      search: clearSearch ? null : (search ?? this.search),
      make: clearMake ? null : (make ?? this.make),
      minYear: clearMinYear ? null : (minYear ?? this.minYear),
      maxYear: clearMaxYear ? null : (maxYear ?? this.maxYear),
      typeFilter: typeFilter ?? this.typeFilter,
      regionFilter: regionFilter ?? this.regionFilter,
      bodyTypeFilter: clearBodyType
          ? null
          : (bodyTypeFilter ?? this.bodyTypeFilter),
      errorMessage: errorMessage,
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
    minYear,
    maxYear,
    typeFilter,
    regionFilter,
    bodyTypeFilter,
    errorMessage,
  ];
}
