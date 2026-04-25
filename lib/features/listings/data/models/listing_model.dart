import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/listing.dart';

class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.title,
    required super.make,
    required super.model,
    required super.year,
    required super.priceEur,
    required super.mileageKm,
    required super.type,
    required super.city,
    required super.marketRegion,
    required super.createdAt,
    super.status,
    super.coverImageUrl,
    super.sellerId,
    super.contactPhone,
    super.telegramUsername,
    super.whatsappEnabled,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: json['id'] as String,
      title: (json['title'] as String?) ?? '',
      make: (json['make'] as String?) ?? '',
      model: (json['model'] as String?) ?? '',
      year: (json['year'] as num?)?.toInt() ?? 0,
      priceEur: (json['price_eur'] as num?) ?? 0,
      mileageKm: (json['mileage_km'] as num?)?.toInt() ?? 0,
      type: _parseType(json['type'] as String?),
      city: (json['city'] as String?) ?? '',
      marketRegion: _parseMarketRegion(json['market_region'] as String?),
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status'] as String?),
      coverImageUrl: json['cover_image_url'] as String?,
      sellerId: json['seller_id'] as String?,
      contactPhone: json['contact_phone'] as String?,
      telegramUsername: json['telegram_username'] as String?,
      whatsappEnabled: (json['whatsapp_enabled'] as bool?) ?? false,
    );
  }

  static ListingType _parseType(String? raw) {
    switch (raw) {
      case 'sale':
        return ListingType.sale;
      case 'exchange':
        return ListingType.exchange;
      case 'both':
        return ListingType.both;
      default:
        return ListingType.sale;
    }
  }

  static ListingStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'active':
        return ListingStatus.active;
      case 'hidden':
        return ListingStatus.hidden;
      case 'sold':
        return ListingStatus.sold;
      case 'archived':
        return ListingStatus.archived;
      default:
        return ListingStatus.active;
    }
  }

  /// Strict parser: any unknown value surfaces as a [ServerException] instead
  /// of being silently mapped to the wrong region. `market_region` is a core
  /// product dimension — a bad value must not pass through.
  static MarketRegion _parseMarketRegion(String? raw) {
    switch (raw) {
      case 'transnistria':
        return MarketRegion.transnistria;
      case 'moldova':
        return MarketRegion.moldova;
      case null:
        throw ServerException('Listing row is missing market_region.');
      default:
        throw ServerException('Unknown market_region value: "$raw".');
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'make': make,
        'model': model,
        'year': year,
        'price_eur': priceEur,
        'mileage_km': mileageKm,
        'type': type.name,
        'city': city,
        'market_region': marketRegion.name,
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'cover_image_url': coverImageUrl,
        'seller_id': sellerId,
        'contact_phone': contactPhone,
        'telegram_username': telegramUsername,
        'whatsapp_enabled': whatsappEnabled,
      };
}
