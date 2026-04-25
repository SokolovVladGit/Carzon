import 'package:equatable/equatable.dart';

enum ListingType { sale, exchange, both }

enum ListingStatus { active, hidden, sold, archived }

/// First-class marketplace region dimension.
///
/// Carzon intentionally splits the market between Transnistria and Moldova
/// because buyer/seller behavior, plates, and logistics differ. Every
/// listing belongs to exactly one region.
enum MarketRegion { transnistria, moldova }

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.priceEur,
    required this.mileageKm,
    required this.type,
    required this.city,
    required this.marketRegion,
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
  final int mileageKm;
  final ListingType type;
  final String city;
  final MarketRegion marketRegion;
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

  @override
  List<Object?> get props => [
        id,
        title,
        make,
        model,
        year,
        priceEur,
        mileageKm,
        type,
        city,
        marketRegion,
        createdAt,
        status,
        coverImageUrl,
        sellerId,
        contactPhone,
        telegramUsername,
        whatsappEnabled,
      ];
}
