import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_currency.dart';

// --- Wire-type coercion (Supabase / PostgREST JSON may vary by driver or view) ---

String? _stringFromDynamic(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

String _requiredNonEmptyId(dynamic value) {
  final s = _stringFromDynamic(value)?.trim();
  if (s == null || s.isEmpty) {
    throw ServerException('Listing row is missing or empty id.');
  }
  return s;
}

String _optionalTextWithFallback(dynamic value, String fallback) {
  final s = _stringFromDynamic(value)?.trim();
  if (s == null || s.isEmpty) return fallback;
  return s;
}

String? _nonEmptyTrimmedOptional(dynamic value) {
  final s = _stringFromDynamic(value);
  if (s == null) return null;
  final t = s.trim();
  return t.isEmpty ? null : t;
}

String? _normalizedEnumKey(dynamic value) {
  final s = _stringFromDynamic(value)?.trim().toLowerCase();
  if (s == null || s.isEmpty) return null;
  return s;
}

int _intFromDynamic(dynamic value, {int fallback = 0}) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return fallback;
    final asInt = int.tryParse(t);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(t);
    if (asDouble != null) return asDouble.toInt();
  }
  return fallback;
}

num _numFromDynamic(dynamic value, {num fallback = 0}) {
  if (value == null) return fallback;
  if (value is num) return value;
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return fallback;
    return num.tryParse(t) ?? double.tryParse(t) ?? fallback;
  }
  return fallback;
}

double? _doubleFromDynamicNullable(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return null;
    return double.tryParse(t);
  }
  return null;
}

int? _intFromDynamicNullable(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) {
    final t = value.trim();
    if (t.isEmpty) return null;
    final asInt = int.tryParse(t);
    if (asInt != null) return asInt;
    return double.tryParse(t)?.toInt();
  }
  return null;
}

bool _boolFromDynamic(dynamic value, {bool fallback = false}) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) {
    if (value == 0) return false;
    if (value == 1) return true;
  }
  if (value is String) {
    switch (value.trim().toLowerCase()) {
      case 'true':
      case 't':
      case '1':
      case 'yes':
        return true;
      case 'false':
      case 'f':
      case '0':
      case 'no':
        return false;
      default:
        return fallback;
    }
  }
  return fallback;
}

DateTime _dateTimeFromDynamic(dynamic value) {
  if (value == null) return DateTime.now();
  if (value is String) {
    final parsed = DateTime.tryParse(value.trim());
    return parsed ?? DateTime.now();
  }
  final asString = _stringFromDynamic(value);
  if (asString != null) {
    final parsed = DateTime.tryParse(asString.trim());
    if (parsed != null) return parsed;
  }
  return DateTime.now();
}

class ListingModel extends Listing {
  const ListingModel({
    required super.id,
    required super.title,
    required super.make,
    required super.model,
    required super.year,
    required super.priceEur,
    super.priceCurrency,
    required super.mileageKm,
    required super.type,
    required super.city,
    required super.marketRegion,
    super.bodyType,
    super.fuelType,
    super.engineDisplacementLiters,
    super.enginePowerHp,
    super.drivetrain,
    super.registration,
    super.description,
    required super.createdAt,
    super.status,
    super.coverImageUrl,
    super.sellerId,
    super.contactPhone,
    super.telegramUsername,
    super.whatsappEnabled,
    super.vinStatus,
  });

  factory ListingModel.fromJson(Map<String, dynamic> json) {
    return ListingModel(
      id: _requiredNonEmptyId(json['id']),
      title: _optionalTextWithFallback(json['title'], ''),
      make: _optionalTextWithFallback(json['make'], ''),
      model: _optionalTextWithFallback(json['model'], ''),
      year: _intFromDynamic(json['year']),
      priceEur: _numFromDynamic(json['price_eur']),
      priceCurrency: listingCurrencyFromDbString(
        _stringFromDynamic(json['price_currency']),
      ),
      mileageKm: _intFromDynamic(json['mileage_km']),
      type: _parseType(json['type']),
      city: _optionalTextWithFallback(json['city'], ''),
      marketRegion: _parseMarketRegion(json['market_region']),
      bodyType: _parseBodyType(json['body_type']),
      fuelType: listingFuelTypeFromDb(
        _stringFromDynamic(json['fuel_type'])?.trim(),
      ),
      engineDisplacementLiters: _doubleFromDynamicNullable(
        json['engine_displacement_liters'],
      ),
      enginePowerHp: _intFromDynamicNullable(json['engine_power_hp']),
      drivetrain: listingDrivetrainFromDb(
        _stringFromDynamic(json['drivetrain'])?.trim(),
      ),
      registration: _nonEmptyTrimmedOptional(json['registration']),
      description: _nonEmptyTrimmedOptional(json['description']),
      createdAt: _dateTimeFromDynamic(json['created_at']),
      status: _parseStatus(json['status']),
      coverImageUrl: _nonEmptyTrimmedOptional(json['cover_image_url']),
      sellerId: _nonEmptyTrimmedOptional(json['seller_id']),
      contactPhone: _nonEmptyTrimmedOptional(json['contact_phone']),
      telegramUsername: _nonEmptyTrimmedOptional(json['telegram_username']),
      whatsappEnabled: _boolFromDynamic(json['whatsapp_enabled']),
      vinStatus: listingVinStatusFromDb(json['vin_status']),
    );
  }

  static ListingType _parseType(dynamic raw) {
    final key = _normalizedEnumKey(raw);
    switch (key) {
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

  /// Unknown non-null [ListingBodyType] values are dropped so the public feed
  /// keeps working when the database contains legacy or mistyped labels.
  static ListingBodyType? _parseBodyType(dynamic raw) {
    final key = _normalizedEnumKey(raw);
    if (key == null) return null;
    switch (key) {
      case 'sedan':
        return ListingBodyType.sedan;
      case 'hatchback':
        return ListingBodyType.hatchback;
      case 'wagon':
        return ListingBodyType.wagon;
      case 'suv':
        return ListingBodyType.suv;
      case 'coupe':
        return ListingBodyType.coupe;
      case 'convertible':
        return ListingBodyType.convertible;
      case 'minivan':
        return ListingBodyType.minivan;
      case 'pickup':
        return ListingBodyType.pickup;
      case 'van':
        return ListingBodyType.van;
      case 'other':
        return ListingBodyType.other;
      default:
        return null;
    }
  }

  /// Core product dimension — invalid values must not pass silently.
  static MarketRegion _parseMarketRegion(dynamic raw) {
    final key = _normalizedEnumKey(raw);
    switch (key) {
      case 'transnistria':
        return MarketRegion.transnistria;
      case 'moldova':
        return MarketRegion.moldova;
      case null:
        throw ServerException('Listing row is missing or empty market_region.');
      default:
        final display = _stringFromDynamic(raw)?.trim() ?? '$raw';
        throw ServerException('Unknown market_region value: "$display".');
    }
  }

  static ListingStatus _parseStatus(dynamic raw) {
    final key = _normalizedEnumKey(raw);
    switch (key) {
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
    'price_currency': listingCurrencyToDbString(priceCurrency),
    'mileage_km': mileageKm,
    'type': type.name,
    'city': city,
    'market_region': marketRegion.name,
    'body_type': bodyType?.name,
    'fuel_type': fuelType?.name,
    'engine_displacement_liters': engineDisplacementLiters,
    'engine_power_hp': enginePowerHp,
    'drivetrain': drivetrain == null
        ? null
        : listingDrivetrainToDbValue(drivetrain!),
    'registration': registration,
    'description': description,
    'created_at': createdAt.toIso8601String(),
    'status': status.name,
    'cover_image_url': coverImageUrl,
    'seller_id': sellerId,
    'contact_phone': contactPhone,
    'telegram_username': telegramUsername,
    'whatsapp_enabled': whatsappEnabled,
    'vin_status': listingVinStatusToDb(vinStatus),
  };
}
