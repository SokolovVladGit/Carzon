import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';

/// Pure-Dart value object describing the fields an owner may edit on
/// an existing listing. No knowledge of Supabase or any data layer.
///
/// Fields intentionally excluded:
///   * `id` (passed separately as [listingId]), `sellerId`, `createdAt`,
///     `status`, `coverImageUrl` — these are not editable through the
///     MVP edit flow. Status is owned by `set_listing_status`; cover
///     replacement is a separate future feature.
class EditListingInput extends Equatable {
  const EditListingInput({
    required this.listingId,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.priceEur,
    required this.mileageKm,
    required this.type,
    required this.city,
    required this.marketRegion,
    this.bodyType,
    required this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled = false,
    this.priceCurrency = ListingCurrency.eur,
  });

  final String listingId;
  final String title;
  final String make;
  final String model;
  final int year;
  final num priceEur;

  /// Display/settlement currency for [priceEur] (`update_listing_details_v2`).
  final ListingCurrency priceCurrency;
  final int mileageKm;
  final ListingType type;
  final String city;
  final MarketRegion marketRegion;

  final ListingBodyType? bodyType;

  /// Required. Stored as a human-readable string; the data layer and
  /// the RPC both trim whitespace before writing.
  final String contactPhone;

  /// Optional. Stored without the leading `@`. Null or empty means
  /// "no Telegram".
  final String? telegramUsername;

  /// Seller opt-in to receive WhatsApp messages on [contactPhone].
  final bool whatsappEnabled;

  @override
  List<Object?> get props => [
    listingId,
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
    contactPhone,
    telegramUsername,
    whatsappEnabled,
  ];
}
