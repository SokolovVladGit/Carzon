import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/listing_discovery_state_sync.dart';
import '../bloc/listings_state.dart';
import '../widgets/filters/listings_filter_apply_result.dart';

/// Maps an applied filter sheet result into [ListingDiscoveryCriteria].
///
/// Search is not edited in [ListingsFilterForm]. When rebuilding alert criteria,
/// preserve the backend snapshot's inline search via [preservedSearch].
ListingDiscoveryCriteria listingDiscoveryCriteriaFromFilterApply(
  ListingsFilterApplyResult result, {
  String? preservedSearch,
}) {
  if (result.cleared) {
    return listingDiscoveryCriteriaFromListingsState(
      ListingsState(
        search: preservedSearch == null || preservedSearch.trim().isEmpty
            ? null
            : preservedSearch.trim(),
      ),
    );
  }
  return listingDiscoveryCriteriaFromListingsState(
    ListingsState(
      search: preservedSearch == null || preservedSearch.trim().isEmpty
          ? null
          : preservedSearch.trim(),
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
      priceCurrencyFilter: result.priceCurrencyFilter,
    ),
  );
}
