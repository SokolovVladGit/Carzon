import 'package:equatable/equatable.dart';

import 'listing_currency.dart';

enum ListingType { sale, exchange, both }

enum ListingStatus { active, hidden, sold, archived }

/// First-class marketplace region dimension.
///
/// Carzon intentionally splits the market between Transnistria and Moldova
/// because buyer/seller behavior, plates, and logistics differ. Every
/// listing belongs to exactly one region.
enum MarketRegion { transnistria, moldova }

/// Vehicle body style (`listings.body_type`). Null in DB/UI means unspecified.
enum ListingBodyType {
  sedan,
  hatchback,
  wagon,
  suv,
  coupe,
  convertible,
  minivan,
  pickup,
  van,
  other,
}

/// Stored as `listings.fuel_type` (CHECK-constrained nullable text).
///
/// [plugInHybrid] persists as `plug_in_hybrid` (not Dart `.name`).
enum ListingFuelType {
  petrol,
  diesel,
  hybrid,
  plugInHybrid,
  electric,
  lpg,
  cng,
  other,
}

/// Stored as `listings.drivetrain`; `fourWheel` ↔ DB `four_wheel`.
enum ListingDrivetrain { fwd, rwd, awd, fourWheel }

/// Stored as `listings.transmission_type`; `dualClutch` ↔ DB `dual_clutch`.
enum ListingTransmissionType {
  manual,
  automatic,
  cvt,
  robotic,
  dualClutch,
  other,
}

/// Public-only VIN hint from `listings.vin_status` (Phase 1).
enum ListingVinStatus { notProvided, formatValid }

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.title,
    required this.make,
    required this.model,
    this.variant,
    required this.year,
    required this.priceEur,
    this.priceCurrency = ListingCurrency.eur,
    required this.mileageKm,
    required this.type,
    required this.city,
    required this.marketRegion,
    this.bodyType,
    this.fuelType,
    this.engineDisplacementLiters,
    this.enginePowerHp,
    this.drivetrain,
    this.transmissionType,
    this.registration,
    this.description,
    required this.createdAt,
    this.status = ListingStatus.active,
    this.coverImageUrl,
    this.sellerId,
    this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled = false,
    this.vinStatus = ListingVinStatus.notProvided,
    this.viewCount = 0,
  });

  final String id;
  final String title;
  final String make;
  final String model;

  /// Optional seller-authored derivative (`listings.variant`).
  final String? variant;

  final int year;
  final num priceEur;

  /// Stored amount; column name remains `price_eur` until a dedicated amount migration.
  final ListingCurrency priceCurrency;
  final int mileageKm;
  final ListingType type;
  final String city;
  final MarketRegion marketRegion;

  /// Optional body style; legacy listings may omit this field.
  final ListingBodyType? bodyType;

  final ListingFuelType? fuelType;

  /// Engine size in liters (mirrors `engine_displacement_liters`).
  final double? engineDisplacementLiters;

  /// Metric horsepower (`engine_power_hp` / л.с.).
  final int? enginePowerHp;

  final ListingDrivetrain? drivetrain;

  /// Seller-entered gearbox type (`transmission_type`). Distinct from drivetrain
  /// and VIN decode metadata.
  final ListingTransmissionType? transmissionType;

  /// Where the car is registered (distinct from marketplace [marketRegion]).
  final String? registration;

  /// Seller-authored description text.
  final String? description;

  final DateTime createdAt;
  final ListingStatus status;
  final String? coverImageUrl;
  final String? sellerId;

  /// Seller-provided phone, human-readable. May be null on legacy rows
  /// that predate the contact-fields migration.
  final String? contactPhone;

  /// Telegram username without the leading `@`. Null when not provided.
  final String? telegramUsername;

  /// Seller opt-in flag: if true, the `contact_phone` can be reached
  /// via WhatsApp. The UI derives the WhatsApp URL from the phone; no
  /// separate WhatsApp number is stored.
  final bool whatsappEnabled;

  /// Public column only — never contains full VIN text.
  final ListingVinStatus vinStatus;

  /// Public aggregate from `listings.view_count` (RPC-maintained).
  final int viewCount;

  /// Semantic alias until the backing column outgrows its historical name.
  num get priceAmount => priceEur;

  @override
  List<Object?> get props => [
    id,
    title,
    make,
    model,
    variant,
    year,
    priceEur,
    priceCurrency,
    mileageKm,
    type,
    city,
    marketRegion,
    bodyType,
    fuelType,
    engineDisplacementLiters,
    enginePowerHp,
    drivetrain,
    transmissionType,
    registration,
    description,
    createdAt,
    status,
    coverImageUrl,
    sellerId,
    contactPhone,
    telegramUsername,
    whatsappEnabled,
    vinStatus,
    viewCount,
  ];
}

/// DB value for [ListingDrivetrain.fourWheel] (`four_wheel`).
const String kListingFourWheelDbValue = 'four_wheel';

String listingDrivetrainToDbValue(ListingDrivetrain value) {
  if (value == ListingDrivetrain.fourWheel) return kListingFourWheelDbValue;
  return value.name;
}

ListingDrivetrain? listingDrivetrainFromDb(String? raw) {
  if (raw == null) return null;
  final v = raw.trim().toLowerCase();
  if (v.isEmpty) return null;
  if (v == kListingFourWheelDbValue) return ListingDrivetrain.fourWheel;
  for (final e in ListingDrivetrain.values) {
    if (e != ListingDrivetrain.fourWheel && e.name == v) return e;
  }
  return null;
}

/// DB value for [ListingTransmissionType.dualClutch] (`dual_clutch`).
const String kListingDualClutchDbValue = 'dual_clutch';

String listingTransmissionTypeToDbValue(ListingTransmissionType value) {
  return switch (value) {
    ListingTransmissionType.manual => 'manual',
    ListingTransmissionType.automatic => 'automatic',
    ListingTransmissionType.cvt => 'cvt',
    ListingTransmissionType.robotic => 'robotic',
    ListingTransmissionType.dualClutch => kListingDualClutchDbValue,
    ListingTransmissionType.other => 'other',
  };
}

ListingTransmissionType? listingTransmissionTypeFromDb(String? raw) {
  if (raw == null) return null;
  final v = raw.trim().toLowerCase();
  if (v.isEmpty) return null;
  if (v == kListingDualClutchDbValue) {
    return ListingTransmissionType.dualClutch;
  }
  for (final e in ListingTransmissionType.values) {
    if (e != ListingTransmissionType.dualClutch && e.name == v) return e;
  }
  return null;
}

/// DB / discovery-wire value for [ListingFuelType.plugInHybrid].
const String kListingPlugInHybridDbValue = 'plug_in_hybrid';

String listingFuelTypeToDbValue(ListingFuelType value) {
  return switch (value) {
    ListingFuelType.plugInHybrid => kListingPlugInHybridDbValue,
    _ => value.name,
  };
}

ListingFuelType? listingFuelTypeFromDb(String? raw) {
  if (raw == null) return null;
  final v = raw.trim().toLowerCase();
  if (v.isEmpty) return null;
  if (v == kListingPlugInHybridDbValue || v == 'pluginhybrid') {
    return ListingFuelType.plugInHybrid;
  }
  for (final e in ListingFuelType.values) {
    if (e != ListingFuelType.plugInHybrid && e.name == v) return e;
  }
  return null;
}

ListingVinStatus listingVinStatusFromDb(dynamic raw) {
  final key = raw?.toString().trim().toLowerCase();
  switch (key) {
    case 'format_valid':
      return ListingVinStatus.formatValid;
    case 'not_provided':
    case '':
    case null:
      return ListingVinStatus.notProvided;
    default:
      return ListingVinStatus.notProvided;
  }
}

String listingVinStatusToDb(ListingVinStatus status) => switch (status) {
  ListingVinStatus.notProvided => 'not_provided',
  ListingVinStatus.formatValid => 'format_valid',
};
