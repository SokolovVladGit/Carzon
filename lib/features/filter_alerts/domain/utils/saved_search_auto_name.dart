import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../recent_searches/presentation/utils/recent_search_display.dart';

/// Builds a short auto-name for a new saved search (max 80 chars).
String buildSavedSearchAutoName(
  AppLocalizations l10n,
  ListingDiscoveryCriteria criteria,
) {
  final display = buildRecentSearchDisplay(l10n, criteria);
  final parts = <String>[display.title];
  final subtitle = display.subtitle?.trim();
  if (subtitle != null && subtitle.isNotEmpty) {
    parts.add(subtitle);
  }
  var name = parts.join(' · ').trim();
  if (name.isEmpty) {
    name = l10n.savedSearchFallbackName;
  }
  const maxLen = 80;
  if (name.length > maxLen) {
    name = '${name.substring(0, maxLen - 1)}…';
  }
  return name;
}
