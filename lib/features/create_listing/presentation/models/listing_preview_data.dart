import 'package:flutter/foundation.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/listing_submit_title.dart';
import '../../../listings/domain/validation/listing_vin.dart';

/// Legacy stand-in. Preview UI must not render this as primary content.
const String kListingPreviewMissingValue = '—';

/// Pre-publication snapshot for [ListingPreviewCard].
///
/// Presentation only — not a persisted [Listing]. Spec fields are Carzon
/// form/domain values, never localized provider strings.
@immutable
class ListingPreviewData {
  const ListingPreviewData({
    this.coverBytes,
    required this.make,
    required this.model,
    this.variant,
    this.year,
    required this.submissionTitle,
    this.priceAmount,
    required this.currency,
    this.mileageKm,
    required this.marketRegion,
    this.city,
    required this.listingType,
    this.hasValidVin = false,
    this.bodyType,
    this.fuelType,
    this.transmissionType,
    this.drivetrain,
    this.engineDisplacementLiters,
    this.enginePowerHp,
  });

  final Uint8List? coverBytes;
  final String make;
  final String model;
  final String? variant;
  final int? year;
  final String submissionTitle;
  final num? priceAmount;
  final ListingCurrency currency;
  final int? mileageKm;
  final MarketRegion marketRegion;
  final String? city;
  final ListingType listingType;
  final bool hasValidVin;
  final ListingBodyType? bodyType;
  final ListingFuelType? fuelType;
  final ListingTransmissionType? transmissionType;
  final ListingDrivetrain? drivetrain;
  final double? engineDisplacementLiters;
  final int? enginePowerHp;

  bool get hasCover => coverBytes != null && coverBytes!.isNotEmpty;
}

/// Joins present fragments with middle dots. Drops empty parts.
String listingPreviewJoin(Iterable<String?> parts) {
  return [
    for (final part in parts)
      if (part != null && part.trim().isNotEmpty) part.trim(),
  ].join(' · ');
}

double? listingPreviewDisplacementLiters(double? raw) {
  if (raw == null || !raw.isFinite || raw <= 0 || raw > 30) return null;
  return raw;
}

num? parseListingPreviewPrice(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final n = num.tryParse(trimmed);
  if (n == null || n <= 0) return null;
  return n;
}

int? parseListingPreviewMileage(String raw) {
  final trimmed = raw.trim();
  if (trimmed.isEmpty) return null;
  final n = int.tryParse(trimmed);
  if (n == null || n < 0) return null;
  return n;
}

/// Builds preview state with the same title helper used on Publish.
ListingPreviewData listingPreviewDataFromCreateForm({
  required AppLocalizations l10n,
  Uint8List? coverBytes,
  required String make,
  required String model,
  String? variant,
  int? year,
  required String priceText,
  required ListingCurrency currency,
  required String mileageText,
  required MarketRegion marketRegion,
  required String city,
  required ListingType listingType,
  String vinText = '',
  ListingBodyType? bodyType,
  ListingFuelType? fuelType,
  ListingTransmissionType? transmissionType,
  ListingDrivetrain? drivetrain,
  double? engineDisplacementLiters,
  int? enginePowerHp,
}) {
  final yearForTitle = year != null && year > 0 ? year : 0;
  return ListingPreviewData(
    coverBytes: coverBytes,
    make: make.trim(),
    model: model.trim(),
    variant: variant?.trim().isEmpty ?? true ? null : variant!.trim(),
    year: yearForTitle == 0 ? null : yearForTitle,
    submissionTitle: resolvedListingTitleForSubmit(
      trimmedUserTitle: '',
      make: make,
      model: model,
      year: yearForTitle,
      l10n: l10n,
      variant: variant,
    ),
    priceAmount: parseListingPreviewPrice(priceText),
    currency: currency,
    mileageKm: parseListingPreviewMileage(mileageText),
    marketRegion: marketRegion,
    city: city.trim().isEmpty ? null : city.trim(),
    listingType: listingType,
    hasValidVin:
        !ListingVin.isBlankInput(vinText) &&
        ListingVin.isOptionalInputValid(vinText),
    bodyType: bodyType,
    fuelType: fuelType,
    transmissionType: transmissionType,
    drivetrain: drivetrain,
    engineDisplacementLiters: listingPreviewDisplacementLiters(
      engineDisplacementLiters,
    ),
    enginePowerHp: listingPreviewEnginePowerHp(enginePowerHp),
  );
}

/// Guards engine power to the same bounds the publish RPC accepts (0, 3000].
int? listingPreviewEnginePowerHp(int? raw) {
  if (raw == null || raw <= 0 || raw > 3000) return null;
  return raw;
}
