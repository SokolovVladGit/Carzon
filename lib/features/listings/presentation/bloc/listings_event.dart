import 'package:equatable/equatable.dart';

import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/entities/listing_currency.dart';
import '../../domain/entities/listing_sort_option.dart';
import '../utils/discovery_feed_chip_labels.dart';
import 'listings_state.dart';

sealed class ListingsEvent extends Equatable {
  const ListingsEvent();

  @override
  List<Object?> get props => [];
}

class ListingsRequested extends ListingsEvent {
  const ListingsRequested();
}

class ListingsRefreshed extends ListingsEvent {
  const ListingsRefreshed();
}

class ListingsNextPageRequested extends ListingsEvent {
  const ListingsNextPageRequested({this.isExplicitRetry = false});

  /// When `true`, retries the failed next page after
  /// [ListingsStatus.paginationFailure]. Scroll-triggered requests leave
  /// this `false` so accidental auto-retries are ignored.
  final bool isExplicitRetry;

  @override
  List<Object?> get props => [isExplicitRetry];
}

class ListingsRegionFilterChanged extends ListingsEvent {
  const ListingsRegionFilterChanged(this.filter);
  final MarketRegionFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Home feed body-type chip row. `null` clears the filter (show all).
class ListingsBodyTypeFilterChanged extends ListingsEvent {
  const ListingsBodyTypeFilterChanged(this.bodyType);
  final ListingBodyType? bodyType;

  @override
  List<Object?> get props => [bodyType];
}

/// Fired when the search text is submitted from the inline search field.
/// Leaves all other filters untouched.
class ListingsSearchChanged extends ListingsEvent {
  const ListingsSearchChanged(this.search);
  final String? search;

  @override
  List<Object?> get props => [search];
}

/// Fired when the user applies the filters bottom sheet and replaces non-search
/// dimensions at once.
///
/// **Browse:** Applying the baseline (vanilla sheet) emits
/// [ListingsFilterApplyResult.clear] from the form so callers clear search +
/// persisted last-applied snapshot like [ListingsFiltersCleared].
///
/// Inline search stays unchanged when non-vanilla constraints are applied.
class ListingsFiltersApplied extends ListingsEvent {
  const ListingsFiltersApplied({
    required this.make,
    required this.model,
    required this.minYear,
    required this.maxYear,
    required this.minPrice,
    required this.maxPrice,
    required this.maxMileage,
    required this.city,
    required this.typeFilter,
    required this.sort,
    required this.regionFilter,
    required this.bodyType,
    required this.fuelType,
    required this.transmissionType,
    required this.drivetrain,
    required this.priceCurrencyFilter,
  });

  final String? make;
  final String? model;
  final int? minYear;
  final int? maxYear;
  final num? minPrice;
  final num? maxPrice;
  final int? maxMileage;
  final String? city;
  final ListingTypeFilter typeFilter;
  final ListingSortOption sort;
  final MarketRegionFilter regionFilter;
  final ListingBodyType? bodyType;
  final ListingFuelType? fuelType;
  final ListingTransmissionType? transmissionType;
  final ListingDrivetrain? drivetrain;
  final ListingPriceCurrencyFilter priceCurrencyFilter;

  @override
  List<Object?> get props => [
    make,
    model,
    minYear,
    maxYear,
    minPrice,
    maxPrice,
    maxMileage,
    city,
    typeFilter,
    sort,
    regionFilter,
    bodyType,
    fuelType,
    transmissionType,
    drivetrain,
    priceCurrencyFilter,
  ];
}

/// Clears every user-facing discovery dimension (including region and inline
/// search) back to the default catalog experience.
class ListingsFiltersCleared extends ListingsEvent {
  const ListingsFiltersCleared();
}

/// Applies a full discovery snapshot before fetch (cold restore from local
/// last-applied criteria or equivalent hydration).
class ListingsHydratedFromDiscovery extends ListingsEvent {
  const ListingsHydratedFromDiscovery(this.criteria);
  final ListingDiscoveryCriteria criteria;

  @override
  List<Object?> get props => [criteria];
}

/// Removes one active discovery chip / filter dimension from the feed.
class ListingsDiscoveryFilterRemoved extends ListingsEvent {
  const ListingsDiscoveryFilterRemoved(this.kind);
  final ListingsDiscoveryChipKind kind;

  @override
  List<Object?> get props => [kind];
}
