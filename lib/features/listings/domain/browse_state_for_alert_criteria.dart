import 'entities/listing_discovery_criteria.dart';

import '../presentation/bloc/listings_state.dart';

import 'listing_discovery_state_sync.dart';

/// Builds persisted filter-alert criteria from the current catalog [state].
///
/// Includes **search text** from the feed header (`[ListingsState.search]`), unlike
/// [listingDiscoveryCriteriaFromFilterApply] which only carries sheet fields and
/// must merge search separately via `preservedSearch`.
///
/// Reuses [listingDiscoveryCriteriaFromListingsState] so browse and alerts stay aligned.
///
/// **Sort:** Returned criteria include [ListingDiscoveryCriteria.sort] for JSON symmetry
/// with last-applied discovery and legacy clients. Postgres
/// `listing_matches_saved_discovery_criteria` **does not** read `sort`; it only affects
/// feed ordering. Prefer [browseStateEligibleForFilterAlertSnapshot] before persisting —
/// sort-only deviations are rejected so callers avoid match-the-whole-feed semantics.
ListingDiscoveryCriteria listingDiscoveryCriteriaFromBrowseStateForAlert(
  ListingsState state,
) {
  return listingDiscoveryCriteriaFromListingsState(state);
}

/// Whether this catalog snapshot should be persisted as filter-alert criteria.
///
/// Blocks:
/// * Default catalog ([isDefaultListingsDiscoveryState]) — would mirror the baseline feed.
/// * **Sort-only** changes: matchers ignore sort, which would equal the full default regional feed.
bool browseStateEligibleForFilterAlertSnapshot(ListingsState state) {
  if (isDefaultListingsDiscoveryState(state)) {
    return false;
  }
  final ignoringSort = state.copyWith(clearSort: true); // resets to newestFirst
  return !isDefaultListingsDiscoveryState(ignoringSort);
}
