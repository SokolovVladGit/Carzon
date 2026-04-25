import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

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
    required this.contactPhone,
    this.telegramUsername,
    this.whatsappEnabled = false,
  });

  final String listingId;
  final String title;
  final String make;
  final String model;
  final int year;
  final num priceEur;
  final int mileageKm;
  final ListingType type;
  final String city;
  final MarketRegion marketRegion;

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
        mileageKm,
        type,
        city,
        marketRegion,
        contactPhone,
        telegramUsername,
        whatsappEnabled,
      ];
}
