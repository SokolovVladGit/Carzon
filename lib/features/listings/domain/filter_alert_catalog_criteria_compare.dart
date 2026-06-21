import 'entities/listing.dart';
import 'entities/listing_discovery_criteria.dart';

import 'browse_state_for_alert_criteria.dart';
import 'listing_discovery_state_sync.dart';

/// Whether [criteria] narrows Postgres filter-alert matching (sort ignored server-side).
bool discoveryCriteriaEligibleForFilterAlertPersist(
  ListingDiscoveryCriteria criteria,
) {
  final synth = listingsStateFromDiscoveryCriteria(criteria);
  return browseStateEligibleForFilterAlertSnapshot(synth);
}

String? _nz(String? s) {
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

bool _listingTypeSemanticsEqual(List<ListingType>? a, List<ListingType>? b) {
  if (identical(a, b)) return true;

  final aEmpty = a == null || a.isEmpty;
  final bEmpty = b == null || b.isEmpty;
  if (aEmpty && bEmpty) return true;
  if (aEmpty || bEmpty) return false;

  final sa = {for (final t in a) t.name};
  final sb = {for (final t in b) t.name};
  if (sa.length != sb.length) return false;
  for (final k in sa) {
    if (!sb.contains(k)) return false;
  }
  return true;
}

/// Equality for UX + catalog bell: same narrowed matching as Postgres would see;
/// **[sort] is ignored** (`listing_matches_saved_discovery_criteria` does not read it).
bool listingDiscoveryCriteriaEqualIgnoringSort(
  ListingDiscoveryCriteria a,
  ListingDiscoveryCriteria b,
) {
  if (_nz(a.search) != _nz(b.search)) return false;
  if (_nz(a.make) != _nz(b.make)) return false;
  if (_nz(a.model) != _nz(b.model)) return false;
  if (_nz(a.city) != _nz(b.city)) return false;
  if (a.minYear != b.minYear) return false;
  if (a.maxYear != b.maxYear) return false;
  if (a.minPrice != b.minPrice) return false;
  if (a.maxPrice != b.maxPrice) return false;
  if (a.maxMileage != b.maxMileage) return false;
  final ar = a.marketRegion?.name.trim();
  final br = b.marketRegion?.name.trim();
  if (ar != br) return false;
  if (a.bodyType != b.bodyType) return false;
  if (a.fuelType != b.fuelType) return false;
  if (a.transmissionType != b.transmissionType) return false;
  if (a.drivetrain != b.drivetrain) return false;
  if (a.priceCurrencyFilter != b.priceCurrencyFilter) return false;
  if (!_listingTypeSemanticsEqual(a.typeIn, b.typeIn)) return false;
  return true;
}
