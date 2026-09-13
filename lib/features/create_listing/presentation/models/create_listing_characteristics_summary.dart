import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';
import 'listing_preview_data.dart';

/// Builds the always-visible Characteristics summary line from the current
/// authoritative Create Listing form state.
///
/// Presentation only. Reuses the existing localized taxonomy/value formatters
/// and never invents values — unknown fields are omitted rather than defaulted.
/// Drivetrain is intentionally excluded here because it is surfaced as its own
/// always-visible row and Smart Fill cannot determine it.
String createListingCharacteristicsSummary(
  AppLocalizations l10n, {
  ListingBodyType? bodyType,
  ListingFuelType? fuelType,
  double? engineDisplacementLiters,
  int? enginePowerHp,
  ListingTransmissionType? transmissionType,
}) {
  return listingPreviewJoin([
    if (bodyType != null) formatListingBodyType(l10n, bodyType),
    if (fuelType != null) formatListingFuelType(l10n, fuelType),
    if (engineDisplacementLiters != null)
      formatEngineDisplacementForDisplay(l10n, engineDisplacementLiters),
    if (enginePowerHp != null) formatEnginePowerHpDisplay(l10n, enginePowerHp),
    if (transmissionType != null)
      formatListingTransmissionType(l10n, transmissionType),
  ]);
}
