import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_currency.dart';

/// Display formatters shared by the listings tile and details page.
/// Kept feature-local — not promoted to core until a second feature
/// needs them. Enum-backed label helpers accept an [AppLocalizations]
/// so they can be called from any widget without reaching out to
/// `context` themselves.

String _corePriceAmount(num value) {
  if (value == value.truncate()) {
    return _thousands(value.toInt().toString());
  }
  return value.toStringAsFixed(2);
}

String formatListingPrice(num amount, ListingCurrency currency) {
  final core = _corePriceAmount(amount);
  switch (currency) {
    case ListingCurrency.eur:
      return '€$core';
    case ListingCurrency.usd:
      return '\$$core';
  }
}

String formatListingPriceFromListing(Listing listing) =>
    formatListingPrice(listing.priceEur, listing.priceCurrency);

String formatEur(num value) => formatListingPrice(value, ListingCurrency.eur);

String formatKm(AppLocalizations l10n, int km) =>
    '${_thousands(km.toString())} ${l10n.commonKilometersShort}';

String formatType(AppLocalizations l10n, ListingType type) {
  switch (type) {
    case ListingType.sale:
      return l10n.formatTypeSale;
    case ListingType.exchange:
      return l10n.formatTypeExchange;
    case ListingType.both:
      return l10n.formatTypeBoth;
  }
}

String formatMarketRegion(AppLocalizations l10n, MarketRegion region) {
  switch (region) {
    case MarketRegion.transnistria:
      return l10n.regionTransnistria;
    case MarketRegion.moldova:
      return l10n.regionMoldova;
  }
}

String formatListingFuelType(AppLocalizations l10n, ListingFuelType type) {
  switch (type) {
    case ListingFuelType.petrol:
      return l10n.listingFuelTypePetrol;
    case ListingFuelType.diesel:
      return l10n.listingFuelTypeDiesel;
    case ListingFuelType.hybrid:
      return l10n.listingFuelTypeHybrid;
    case ListingFuelType.electric:
      return l10n.listingFuelTypeElectric;
    case ListingFuelType.lpg:
      return l10n.listingFuelTypeLpg;
    case ListingFuelType.cng:
      return l10n.listingFuelTypeCng;
    case ListingFuelType.other:
      return l10n.listingFuelTypeOther;
  }
}

String formatListingDrivetrain(AppLocalizations l10n, ListingDrivetrain type) {
  switch (type) {
    case ListingDrivetrain.fwd:
      return l10n.listingDrivetrainFwd;
    case ListingDrivetrain.rwd:
      return l10n.listingDrivetrainRwd;
    case ListingDrivetrain.awd:
      return l10n.listingDrivetrainAwd;
    case ListingDrivetrain.fourWheel:
      return l10n.listingDrivetrainFourWheel;
  }
}

/// Formats liters for details (stored as liters in `engine_displacement_liters`).
///
/// Values >= [kCcDisplacementThreshold] are treated as cubic centimeters for
/// display (`N см³`).
const double kCcDisplacementThreshold = 80;

String formatEngineDisplacementForDisplay(
  AppLocalizations l10n,
  double? litersOrCc,
) {
  if (litersOrCc == null) return '';
  final v = litersOrCc;
  if (v >= kCcDisplacementThreshold && v.round() == v) {
    return '${v.toInt()} ${l10n.listingEngineDisplacementCcSuffix}';
  }
  final fixed = v.toStringAsFixed(3);
  final trimmed = fixed.replaceFirst(RegExp(r'\.?0+$'), '');
  return '$trimmed ${l10n.listingEngineDisplacementLitersSuffix}';
}

String formatEnginePowerHpDisplay(AppLocalizations l10n, int? hp) {
  if (hp == null) return '';
  return '$hp ${l10n.listingEnginePowerHpSuffix}';
}

String formatListingBodyType(AppLocalizations l10n, ListingBodyType type) {
  switch (type) {
    case ListingBodyType.sedan:
      return l10n.listingBodyTypeSedan;
    case ListingBodyType.hatchback:
      return l10n.listingBodyTypeHatchback;
    case ListingBodyType.wagon:
      return l10n.listingBodyTypeWagon;
    case ListingBodyType.suv:
      return l10n.listingBodyTypeSuv;
    case ListingBodyType.coupe:
      return l10n.listingBodyTypeCoupe;
    case ListingBodyType.convertible:
      return l10n.listingBodyTypeConvertible;
    case ListingBodyType.minivan:
      return l10n.listingBodyTypeMinivan;
    case ListingBodyType.pickup:
      return l10n.listingBodyTypePickup;
    case ListingBodyType.van:
      return l10n.listingBodyTypeVan;
    case ListingBodyType.other:
      return l10n.listingBodyTypeOther;
  }
}

String formatStatus(AppLocalizations l10n, ListingStatus status) {
  switch (status) {
    case ListingStatus.active:
      return l10n.statusActive;
    case ListingStatus.hidden:
      return l10n.statusHidden;
    case ListingStatus.sold:
      return l10n.statusSold;
    case ListingStatus.archived:
      return l10n.statusArchived;
  }
}

String formatDate(DateTime dt) {
  final local = dt.toLocal();
  final y = local.year.toString().padLeft(4, '0');
  final m = local.month.toString().padLeft(2, '0');
  final d = local.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

/// Locale-aware added-date for listing details header metadata (e.g. `14 янв. 2026`).
String formatListingAddedDate(AppLocalizations l10n, DateTime date) {
  return DateFormat('d MMM y', l10n.localeName).format(date.toLocal());
}

String _thousands(String digits) {
  final buf = StringBuffer();
  final n = digits.length;
  for (var i = 0; i < n; i++) {
    if (i > 0 && (n - i) % 3 == 0) buf.write(' ');
    buf.write(digits[i]);
  }
  return buf.toString();
}
