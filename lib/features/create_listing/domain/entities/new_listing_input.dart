import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

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
    required this.mileageKm,
    required this.type,
    required this.city,
    required this.marketRegion,
    required this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled = false,
    this.coverImageUrl,
  });

  final String sellerId;
  final String title;
  final String make;
  final String model;
  final int year;
  final num priceEur;
  final int mileageKm;
  final ListingType type;
  final String city;
  final MarketRegion marketRegion;

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

  NewListingInput copyWith({
    String? coverImageUrl,
    String? contactPhone,
    String? telegramUsername,
    bool? whatsappEnabled,
  }) =>
      NewListingInput(
        sellerId: sellerId,
        title: title,
        make: make,
        model: model,
        year: year,
        priceEur: priceEur,
        mileageKm: mileageKm,
        type: type,
        city: city,
        marketRegion: marketRegion,
        contactPhone: contactPhone ?? this.contactPhone,
        telegramUsername: telegramUsername ?? this.telegramUsername,
        whatsappEnabled: whatsappEnabled ?? this.whatsappEnabled,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      );

  @override
  List<Object?> get props => [
        sellerId,
        title,
        make,
        model,
        year,
        priceEur,
        mileageKm,
        type,
        city,
        marketRegion,
        contactPhone,
        telegramUsername,
        whatsappEnabled,
        coverImageUrl,
      ];
}
