import '../../../../l10n/app_localizations.dart';
import 'listing_formatters.dart';

/// Total views label for the primary metadata chip.
String listingDetailsMetadataViewsLabel(
  AppLocalizations l10n, {
  required int totalViews,
}) {
  return l10n.listingDetailsMetadataViews(totalViews);
}

/// Today views label for the accent chip; `null` when hidden (0 or unavailable).
String? listingDetailsMetadataTodayLabel(
  AppLocalizations l10n, {
  required int? todayViews,
}) {
  if (todayViews == null || todayViews <= 0) return null;
  return l10n.listingDetailsMetadataViewsToday(todayViews);
}

/// Compact localized added date for the subtle metadata chip.
String listingDetailsMetadataAddedDateLabel(
  AppLocalizations l10n, {
  required DateTime createdAt,
}) {
  return formatListingAddedDate(l10n, createdAt);
}
