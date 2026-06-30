import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';
import 'listing_details_header_titles.dart';

/// Builds the `mailto:` URI used by the in-app "Report listing" action
/// on `ListingDetailsPage`.
///
/// This helper is intentionally pure and UI-layer only: it does not
/// touch Supabase, the network, or any async API. It exists in
/// `presentation/utils/` alongside `contact_format.dart` because a
/// mailto action is purely a UI launcher format.
///
/// Localization:
///   * Subject prefix and body template are taken from [l10n], so the
///     email the reporter sees opens in the same language as the rest
///     of the app. Listing data (id, title, make, model, year, city) is
///     not translated — it is user-entered content.
///   * The market region label is taken from [AppLocalizations], so it
///     matches what the buyer sees on the listing details page.
///
/// Privacy:
///   * The body contains ONLY public listing information that is
///     already visible to any anonymous visitor via the public feed
///     (title, id, make/model/year, city, market region).
///   * The helper DOES NOT include the seller's email, seller auth id,
///     seller phone, seller telegram handle, or any buyer identity.
///
/// Encoding:
///   * Spaces are percent-encoded (`%20`) via [Uri.encodeComponent],
///     not `+`, so the result matches RFC 6068 and is accepted by both
///     native mail clients and web mailto handlers.
///   * Newlines in the body are preserved as `%0A` so the recipient
///     sees a structured report template.
Uri buildReportListingMailto({
  required AppLocalizations l10n,
  required Listing listing,
  required String recipientEmail,
}) {
  final trimmedEmail = recipientEmail.trim();
  if (trimmedEmail.isEmpty) {
    throw ArgumentError.value(
      recipientEmail,
      'recipientEmail',
      'recipient email cannot be empty',
    );
  }

  final regionLabel = switch (listing.marketRegion) {
    MarketRegion.transnistria => l10n.regionTransnistria,
    MarketRegion.moldova => l10n.regionMoldova,
  };

  final subject = '${l10n.reportSubjectPrefix} — ${listing.id}';

  final buffer = StringBuffer()
    ..writeln(l10n.reportBodyIntro)
    ..writeln()
    ..writeln('${l10n.reportBodyFieldTitle}: ${listing.title}')
    ..writeln('${l10n.reportBodyFieldListingId}: ${listing.id}')
    ..writeln(
      '${l10n.reportBodyFieldMmy}: '
      '${listingDetailsVehicleIdentityLine(listing.make, listing.model)} '
      '${listing.year}',
    )
    ..writeln('${l10n.reportBodyFieldCity}: ${listing.city}')
    ..writeln('${l10n.reportBodyFieldRegion}: $regionLabel')
    ..writeln()
    ..writeln(l10n.reportBodyPrompt)
    ..writeln();

  final encodedSubject = Uri.encodeComponent(subject);
  final encodedBody = Uri.encodeComponent(buffer.toString());

  return Uri.parse(
    'mailto:$trimmedEmail?subject=$encodedSubject&body=$encodedBody',
  );
}
