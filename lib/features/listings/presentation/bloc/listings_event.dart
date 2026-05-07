import 'package:equatable/equatable.dart';

import '../../domain/entities/listing.dart';
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
  const ListingsNextPageRequested();
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

/// Fired when the user applies the filters bottom sheet. Replaces the
/// make / year range / type filters at once. Search and region are left
/// untouched — they are controlled outside the sheet.
class ListingsFiltersApplied extends ListingsEvent {
  const ListingsFiltersApplied({
    required this.make,
    required this.minYear,
    required this.maxYear,
    required this.typeFilter,
  });

  final String? make;
  final int? minYear;
  final int? maxYear;
  final ListingTypeFilter typeFilter;

  @override
  List<Object?> get props => [make, minYear, maxYear, typeFilter];
}

/// Fired when the user clears all filters. Resets search, make, minYear,
/// maxYear, and typeFilter. Keeps the selected region — region is a
/// first-class marketplace dimension and stays intentional.
class ListingsFiltersCleared extends ListingsEvent {
  const ListingsFiltersCleared();
}
