import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import 'uploaded_listing_image.dart';

/// Pure-Dart value object describing the data required to create a new
/// listing. No knowledge of Supabase or any data layer.
class NewListingInput extends Equatable {
  const NewListingInput({
    required this.sellerId,
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
    required this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled = false,
    this.coverImageUrl,
    this.uploadedGallery,
    this.fuelType,
    this.engineDisplacementLiters,
    this.enginePowerHp,
    this.drivetrain,
    this.transmissionType,
    this.registration,
    this.description,
    this.vin,
  });

  final String sellerId;
  final String title;
  final String make;
  final String model;
  final int year;
  final num priceEur;
  final ListingCurrency priceCurrency;
  final int mileageKm;
  final ListingType type;
  final String city;
  final MarketRegion marketRegion;

  /// Optional (`listings.body_type` nullable until seller chooses).
  final ListingBodyType? bodyType;

  /// Required at the form level. Stored as a human-readable string;
  /// the data layer trims whitespace before inserting.
  final String contactPhone;

  /// Optional Telegram username. Stored without the leading `@`.
  final String? telegramUsername;

  /// Seller opt-in: allow buyers to reach the same phone on WhatsApp.
  final bool whatsappEnabled;

  /// Optional public URL of the listing's cover image. When non-null and
  /// non-empty the data layer will include it in the insert payload.
  final String? coverImageUrl;

  /// Ordered staging metadata for `create_listing_v2` (URLs + optional paths).
  final List<UploadedListingImage>? uploadedGallery;

  final ListingFuelType? fuelType;
  final double? engineDisplacementLiters;
  final int? enginePowerHp;
  final ListingDrivetrain? drivetrain;
  final ListingTransmissionType? transmissionType;
  final String? registration;
  final String? description;

  /// Normalized 17-char VIN when provided; null when omitted on create.
  final String? vin;

  NewListingInput copyWith({
    String? coverImageUrl,
    String? contactPhone,
    String? telegramUsername,
    bool? whatsappEnabled,
    ListingCurrency? priceCurrency,
    List<UploadedListingImage>? uploadedGallery,
    ListingBodyType? bodyType,
    ListingFuelType? fuelType,
    double? engineDisplacementLiters,
    int? enginePowerHp,
    ListingDrivetrain? drivetrain,
    ListingTransmissionType? transmissionType,
    String? registration,
    String? description,
    String? vin,
  }) => NewListingInput(
    sellerId: sellerId,
    title: title,
    make: make,
    model: model,
    year: year,
    priceEur: priceEur,
    priceCurrency: priceCurrency ?? this.priceCurrency,
    mileageKm: mileageKm,
    type: type,
    city: city,
    marketRegion: marketRegion,
    bodyType: bodyType ?? this.bodyType,
    contactPhone: contactPhone ?? this.contactPhone,
    telegramUsername: telegramUsername ?? this.telegramUsername,
    whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
    coverImageUrl: coverImageUrl ?? this.coverImageUrl,
    uploadedGallery: uploadedGallery ?? this.uploadedGallery,
    fuelType: fuelType ?? this.fuelType,
    engineDisplacementLiters:
        engineDisplacementLiters ?? this.engineDisplacementLiters,
    enginePowerHp: enginePowerHp ?? this.enginePowerHp,
    drivetrain: drivetrain ?? this.drivetrain,
    transmissionType: transmissionType ?? this.transmissionType,
    registration: registration ?? this.registration,
    description: description ?? this.description,
    vin: vin ?? this.vin,
  );

  @override
  List<Object?> get props => [
    sellerId,
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
    fuelType,
    engineDisplacementLiters,
    enginePowerHp,
    drivetrain,
    transmissionType,
    registration,
    description,
    vin,
    contactPhone,
    telegramUsername,
    whatsappEnabled,
    coverImageUrl,
    uploadedGallery,
  ];
}
