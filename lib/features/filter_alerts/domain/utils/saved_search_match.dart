import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/domain/filter_alert_catalog_criteria_compare.dart';
import '../entities/saved_search.dart';

/// Returns the first saved search whose criteria matches [criteria] ignoring sort.
SavedSearch? findSavedSearchMatchingCriteria(
  Iterable<SavedSearch> savedSearches,
  ListingDiscoveryCriteria criteria,
) {
  for (final row in savedSearches) {
    if (listingDiscoveryCriteriaEqualIgnoringSort(criteria, row.criteria)) {
      return row;
    }
  }
  return null;
}

/// Client-side duplicate guard before create RPC.
bool savedSearchesContainMatchingCriteria(
  Iterable<SavedSearch> savedSearches,
  ListingDiscoveryCriteria criteria,
) {
  return findSavedSearchMatchingCriteria(savedSearches, criteria) != null;
}
