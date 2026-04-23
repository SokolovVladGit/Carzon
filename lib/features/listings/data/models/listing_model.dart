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
    required super.createdAt,
    super.status,
    super.coverImageUrl,
    super.sellerId,
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
      createdAt:
          DateTime.tryParse((json['created_at'] as String?) ?? '') ?? DateTime.now(),
      status: _parseStatus(json['status'] as String?),
      coverImageUrl: json['cover_image_url'] as String?,
      sellerId: json['seller_id'] as String?,
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
        'created_at': createdAt.toIso8601String(),
        'status': status.name,
        'cover_image_url': coverImageUrl,
        'seller_id': sellerId,
      };
}
