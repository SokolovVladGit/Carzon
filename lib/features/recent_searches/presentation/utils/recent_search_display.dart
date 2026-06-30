import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/domain/listing_discovery_state_sync.dart';
import '../../../listings/presentation/utils/discovery_feed_chip_labels.dart';

/// Localized title/subtitle for a recent search row.
class RecentSearchDisplay {
  const RecentSearchDisplay({required this.title, this.subtitle});

  final String title;
  final String? subtitle;
}

/// Builds a compact localized label for [criteria] in recent-search lists.
RecentSearchDisplay buildRecentSearchDisplay(
  AppLocalizations l10n,
  ListingDiscoveryCriteria criteria,
) {
  final state = listingsStateFromDiscoveryCriteria(criteria);
  final search = criteria.search?.trim();
  final hasSearch = search != null && search.isNotEmpty;

  final chips = listingsDiscoveryChips(state, l10n);
  final subtitleParts = chips
      .where((chip) => chip.kind != ListingsDiscoveryChipKind.search)
      .map((chip) => chip.flat)
      .where((label) => label.trim().isNotEmpty)
      .toList(growable: false);

  final title = hasSearch
      ? l10n.recentSearchesSearchOnlyLabel(search)
      : l10n.recentSearchesFiltersOnlyLabel;

  final subtitle = subtitleParts.isEmpty ? null : subtitleParts.join(' · ');

  return RecentSearchDisplay(title: title, subtitle: subtitle);
}
