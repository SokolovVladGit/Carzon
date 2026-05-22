import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/presentation/utils/listing_formatters.dart'
    as listing_fmt;
import '../../domain/entities/compare_listing_snapshot.dart';
import '../../domain/entities/compare_resolved_slot.dart';
import '../models/compare_spec_models.dart';

/// Formats listing/snapshot fields for the compare spec table.
class CompareSpecFormatters {
  CompareSpecFormatters(this.l10n);

  final AppLocalizations l10n;

  static const String missing = CompareSpecRow.missingToken;

  String formatVin(ListingVinStatus status) {
    return switch (status) {
      ListingVinStatus.formatValid => l10n.compareVinProvided,
      ListingVinStatus.notProvided => l10n.compareVinNotProvided,
    };
  }

  String formatPriceFromListing(Listing listing) =>
      listing_fmt.formatListingPriceFromListing(listing);

  String formatPriceFromSnapshot(CompareListingSnapshot snapshot) {
    if (snapshot.priceEur == null) return missing;
    return listing_fmt.formatListingPrice(
      snapshot.priceEur!,
      snapshot.priceCurrency,
    );
  }

  String formatMileage(Listing? listing) {
    if (listing == null) return missing;
    return listing_fmt.formatKm(listing.mileageKm);
  }

  String formatYear(Listing? listing, CompareListingSnapshot snapshot) {
    final year = listing?.year ?? snapshot.year;
    if (year == null) return missing;
    return year.toString();
  }

  String formatCityRegion(CompareResolvedSlot slot) {
    final listing = slot.listing;
    final snapshot = slot.item.snapshot;
    final city = (listing?.city ?? snapshot.city)?.trim();
    final regionRaw = listing?.marketRegion.name ?? snapshot.marketRegionRaw;
    MarketRegion? region;
    if (regionRaw != null) {
      try {
        region = MarketRegion.values.byName(regionRaw);
      } on ArgumentError {
        region = null;
      }
    }
    final parts = <String>[];
    if (city != null && city.isNotEmpty) parts.add(city);
    if (region != null) parts.add(listing_fmt.formatMarketRegion(l10n, region));
    if (parts.isEmpty) return missing;
    return parts.join(' · ');
  }

  String formatListingStatus(Listing? listing) {
    if (listing == null) return missing;
    return listing_fmt.formatStatus(l10n, listing.status);
  }

  String formatMake(Listing? listing, CompareListingSnapshot snapshot) {
    final make = (listing?.make ?? snapshot.make)?.trim();
    return (make == null || make.isEmpty) ? missing : make;
  }

  String formatModel(Listing? listing, CompareListingSnapshot snapshot) {
    final model = (listing?.model ?? snapshot.model)?.trim();
    return (model == null || model.isEmpty) ? missing : model;
  }

  String formatBody(Listing? listing) {
    if (listing?.bodyType == null) return missing;
    return listing_fmt.formatListingBodyType(l10n, listing!.bodyType!);
  }

  String formatVehicleType(Listing? listing) {
    if (listing == null) return missing;
    return listing_fmt.formatType(l10n, listing.type);
  }

  String formatRegistration(Listing? listing) {
    final reg = listing?.registration?.trim();
    if (reg == null || reg.isEmpty) return missing;
    return reg;
  }

  String formatFuel(Listing? listing) {
    if (listing?.fuelType == null) return missing;
    return listing_fmt.formatListingFuelType(l10n, listing!.fuelType!);
  }

  String formatEngine(Listing? listing) {
    if (listing == null) return missing;
    final parts = <String>[];
    if (listing.engineDisplacementLiters != null) {
      final disp = listing_fmt.formatEngineDisplacementForDisplay(
        l10n,
        listing.engineDisplacementLiters,
      );
      if (disp.isNotEmpty) parts.add(disp);
    }
    if (listing.enginePowerHp != null) {
      final power = listing_fmt.formatEnginePowerHpDisplay(
        l10n,
        listing.enginePowerHp,
      );
      if (power.isNotEmpty) parts.add(power);
    }
    if (parts.isEmpty) return missing;
    return parts.join(' · ');
  }

  String formatPower(Listing? listing) {
    if (listing?.enginePowerHp == null) return missing;
    return listing_fmt.formatEnginePowerHpDisplay(l10n, listing!.enginePowerHp);
  }

  String formatDrivetrain(Listing? listing) {
    if (listing?.drivetrain == null) return missing;
    return listing_fmt.formatListingDrivetrain(l10n, listing!.drivetrain!);
  }

  String formatDisplacement(Listing? listing) {
    if (listing?.engineDisplacementLiters == null) return missing;
    return listing_fmt.formatEngineDisplacementForDisplay(
      l10n,
      listing!.engineDisplacementLiters,
    );
  }

  String formatPhotos(int? photoCount) {
    if (photoCount == null || photoCount <= 0) return missing;
    return photoCount.toString();
  }

  String formatPublishedAt(Listing? listing) {
    if (listing == null) return missing;
    return listing_fmt.formatDate(listing.createdAt);
  }
}
