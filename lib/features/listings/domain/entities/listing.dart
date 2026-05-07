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

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.priceEur,
    this.priceCurrency = ListingCurrency.eur,
    required this.mileageKm,
    required this.type,
    required this.city,
    required this.marketRegion,
    this.bodyType,
    required this.createdAt,
    this.status = ListingStatus.active,
    this.coverImageUrl,
    this.sellerId,
    this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled = false,
  });

  final String id;
  final String title;
  final String make;
  final String model;
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

  /// Semantic alias until the backing column outgrows its historical name.
  num get priceAmount => priceEur;

  @override
  List<Object?> get props => [
    id,
    title,
    make,
    model,
    year,
    priceEur,
    priceCurrency,
    mileageKm,
    type,
    city,
    marketRegion,
    bodyType,
    createdAt,
    status,
    coverImageUrl,
    sellerId,
    contactPhone,
    telegramUsername,
    whatsappEnabled,
  ];
}
