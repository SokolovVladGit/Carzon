import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/domain/listing_discovery_state_sync.dart';
import '../../../listings/presentation/utils/discovery_feed_chip_labels.dart';
import '../../../listings/presentation/utils/listing_details_header_titles.dart';

/// Builds a user-facing card title from [criteria], independent of the
/// persisted [SavedSearch.name] (which may be generic or stale).
String buildSavedSearchDisplayTitle(
  AppLocalizations l10n,
  ListingDiscoveryCriteria criteria,
) {
  final make = criteria.make?.trim();
  final model = criteria.model?.trim();

  if (make != null && make.isNotEmpty && model != null && model.isNotEmpty) {
    return listingDetailsVehicleIdentityLine(make, model);
  }

  final state = listingsStateFromDiscoveryCriteria(criteria);
  final chips = listingsDiscoveryChips(state, l10n);

  String? chipValue(ListingsDiscoveryChipKind kind) {
    for (final chip in chips) {
      if (chip.kind == kind && chip.value.trim().isNotEmpty) {
        return chip.value.trim();
      }
    }
    return null;
  }

  if (make != null && make.isNotEmpty) {
    for (final kind in _secondaryTitleKinds) {
      final secondary = chipValue(kind);
      if (secondary != null) {
        return '$make · $secondary';
      }
    }
    return make;
  }

  final search = criteria.search?.trim();
  if (search != null && search.isNotEmpty) {
    return search;
  }

  final parts = <String>[];
  for (final kind in _titleOnlyKinds) {
    final value = chipValue(kind);
    if (value == null) continue;
    parts.add(value);
    if (parts.length >= 2) break;
  }
  if (parts.isNotEmpty) {
    return parts.join(' · ');
  }

  return l10n.savedSearchDisplayTitleFallback;
}

const _secondaryTitleKinds = <ListingsDiscoveryChipKind>[
  ListingsDiscoveryChipKind.priceRange,
  ListingsDiscoveryChipKind.bodyType,
  ListingsDiscoveryChipKind.city,
  ListingsDiscoveryChipKind.region,
  ListingsDiscoveryChipKind.maxMileage,
  ListingsDiscoveryChipKind.year,
  ListingsDiscoveryChipKind.fuelType,
  ListingsDiscoveryChipKind.transmissionType,
  ListingsDiscoveryChipKind.listingType,
];

const _titleOnlyKinds = <ListingsDiscoveryChipKind>[
  ListingsDiscoveryChipKind.bodyType,
  ListingsDiscoveryChipKind.city,
  ListingsDiscoveryChipKind.region,
  ListingsDiscoveryChipKind.priceRange,
  ListingsDiscoveryChipKind.maxMileage,
  ListingsDiscoveryChipKind.year,
  ListingsDiscoveryChipKind.fuelType,
  ListingsDiscoveryChipKind.transmissionType,
  ListingsDiscoveryChipKind.listingType,
  ListingsDiscoveryChipKind.search,
];
