import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/listing_discovery_state_sync.dart';
import '../bloc/listings_state.dart';
import '../widgets/filters/listings_filter_apply_result.dart';

/// Maps an applied filter result into [ListingDiscoveryCriteria].
///
/// [ListingsFilterApplyResult.search] is the draft search. [preservedSearch]
/// is a fallback for callers that still merge an external snippet (sheet bell
/// first frame) when the result search is blank.
ListingDiscoveryCriteria listingDiscoveryCriteriaFromFilterApply(
  ListingsFilterApplyResult result, {
  String? preservedSearch,
}) {
  String? resolvedSearch() {
    final fromResult = result.search?.trim();
    if (fromResult != null && fromResult.isNotEmpty) return fromResult;
    final fallback = preservedSearch?.trim();
    if (fallback != null && fallback.isNotEmpty) return fallback;
    return null;
  }

  if (result.cleared) {
    return listingDiscoveryCriteriaFromListingsState(const ListingsState());
  }
  return listingDiscoveryCriteriaFromListingsState(
    ListingsState(
      search: resolvedSearch(),
      make: result.make,
      model: result.model,
      minYear: result.minYear,
      maxYear: result.maxYear,
      minPrice: result.minPrice,
      maxPrice: result.maxPrice,
      maxMileage: result.maxMileage,
      city: result.city,
      typeFilter: result.typeFilter,
      sortOption: result.sort,
      regionFilter: result.region ?? MarketRegionFilter.both,
      bodyTypeFilter: result.bodyType,
      fuelTypeFilter: result.fuelType,
      transmissionTypeFilter: result.transmissionType,
      drivetrainFilter: result.drivetrain,
      priceCurrencyFilter: result.priceCurrencyFilter,
    ),
  );
}
