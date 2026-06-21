import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';
import 'listing_details_header_titles.dart';
import 'listing_formatters.dart';

/// Pure formatter for the native "Share listing" sheet body.
///
/// Includes only public listing fields already visible on the details page.
/// Never emits seller contact, seller ids, VIN, or internal payloads.
String buildListingShareText(
  AppLocalizations l10n,
  Listing listing, {
  String? shareUrl,
}) {
  final header = ListingDetailsHeaderDisplay.fromListing(listing);
  final title = header.primaryLine.trim();
  final price = formatListingPriceFromListing(listing).trim();
  final location = _formatShareLocation(l10n, listing);

  final detailsParts = <String>[
    if (price.isNotEmpty) price,
    if (location != null && location.isNotEmpty) location,
  ];

  final trimmedUrl = shareUrl?.trim();
  final footer = (trimmedUrl != null && trimmedUrl.isNotEmpty)
      ? l10n.listingShareLinkLine(trimmedUrl)
      : '${l10n.listingShareOpenInCarzon}\n${l10n.listingShareFallbackLine(listing.id)}';

  return _joinShareLines([
    l10n.listingShareIntro,
    if (title.isNotEmpty) title,
    if (detailsParts.isNotEmpty) detailsParts.join(' · '),
    footer,
  ]);
}

String? _formatShareLocation(AppLocalizations l10n, Listing listing) {
  final city = listing.city.trim();
  final region = formatMarketRegion(l10n, listing.marketRegion).trim();
  if (city.isNotEmpty && region.isNotEmpty) return '$city, $region';
  if (city.isNotEmpty) return city;
  if (region.isNotEmpty) return region;
  return null;
}

String _joinShareLines(Iterable<String> lines) {
  return lines
      .map((line) => line.trim())
      .where((line) => line.isNotEmpty)
      .join('\n');
}
