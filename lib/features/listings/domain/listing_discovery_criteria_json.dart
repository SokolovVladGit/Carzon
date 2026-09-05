import 'entities/listing.dart';
import 'entities/listing_currency.dart';
import 'entities/listing_discovery_criteria.dart';
import 'entities/listing_sort_option.dart';

/// Canonical JSON serialization for [ListingDiscoveryCriteria].
///
/// - [schemaVersion] must be `1` for decoding.
/// - Enum values use stable lowercase snake/snake_wire strings (not localized UI copy).
abstract final class ListingDiscoveryCriteriaJsonSchema {
  static const schemaVersionKey = 'schemaVersion';
  static const currentVersion = 1;
}

ListingSortOption listingSortOptionFromWire(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'price_low_to_high':
      return ListingSortOption.priceLowToHigh;
    case 'price_high_to_low':
      return ListingSortOption.priceHighToLow;
    case 'newest_year_first':
      return ListingSortOption.newestYearFirst;
    case 'lowest_mileage_first':
      return ListingSortOption.lowestMileageFirst;
    case 'newest_first':
    case '':
    case null:
    default:
      return ListingSortOption.newestFirst;
  }
}

String listingSortOptionToWire(ListingSortOption o) {
  switch (o) {
    case ListingSortOption.newestFirst:
      return 'newest_first';
    case ListingSortOption.priceLowToHigh:
      return 'price_low_to_high';
    case ListingSortOption.priceHighToLow:
      return 'price_high_to_low';
    case ListingSortOption.newestYearFirst:
      return 'newest_year_first';
    case ListingSortOption.lowestMileageFirst:
      return 'lowest_mileage_first';
  }
}

ListingPriceCurrencyFilter listingPriceCurrencyFilterFromWire(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'usd':
      return ListingPriceCurrencyFilter.usd;
    case 'eur':
      return ListingPriceCurrencyFilter.eur;
    case 'any':
    case '':
    case null:
    default:
      return ListingPriceCurrencyFilter.any;
  }
}

String listingPriceCurrencyFilterToWire(ListingPriceCurrencyFilter f) {
  switch (f) {
    case ListingPriceCurrencyFilter.any:
      return 'any';
    case ListingPriceCurrencyFilter.usd:
      return 'usd';
    case ListingPriceCurrencyFilter.eur:
      return 'eur';
  }
}

MarketRegion? marketRegionFromWire(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'transnistria':
      return MarketRegion.transnistria;
    case 'moldova':
      return MarketRegion.moldova;
    case 'both':
    case '':
    case null:
    default:
      return null;
  }
}

String marketRegionToWireNullable(MarketRegion? region) {
  if (region == null) return 'both';
  switch (region) {
    case MarketRegion.transnistria:
      return 'transnistria';
    case MarketRegion.moldova:
      return 'moldova';
  }
}

ListingBodyType? listingBodyTypeFromWire(String? raw) {
  switch (raw?.trim().toLowerCase()) {
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

String? listingBodyTypeToWire(ListingBodyType? t) => t?.name;

ListingFuelType? listingFuelTypeFromWire(String? raw) {
  return listingFuelTypeFromDb(raw);
}

String? listingFuelTypeToWire(ListingFuelType? t) {
  if (t == null) return null;
  return listingFuelTypeToDbValue(t);
}

ListingTransmissionType? listingTransmissionTypeFromWire(String? raw) {
  if (raw == null) return null;
  return listingTransmissionTypeFromDb(raw.trim());
}

String? listingTransmissionTypeToWire(ListingTransmissionType? t) {
  if (t == null) return null;
  return listingTransmissionTypeToDbValue(t);
}

String? listingDrivetrainToWire(ListingDrivetrain? d) {
  if (d == null) return null;
  return listingDrivetrainToDbValue(d);
}

ListingDrivetrain? listingDrivetrainFromWire(String? raw) {
  return listingDrivetrainFromDb(raw);
}

ListingType? listingTypeFromWire(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'sale':
      return ListingType.sale;
    case 'exchange':
      return ListingType.exchange;
    case 'both':
      return ListingType.both;
    default:
      return null;
  }
}

String listingTypeToWire(ListingType t) => t.name;

/// Encodes criteria for persistence (local + Supabase `criteria` JSONB).
///
/// Insertion order is stable for fingerprinting / duplicate checks.
Map<String, dynamic> listingDiscoveryCriteriaToJson(
  ListingDiscoveryCriteria c,
) {
  final typeStrings = <String>[];
  final types = <ListingType>[...(c.typeIn ?? const <ListingType>[])];
  types.sort((a, b) => listingTypeToWire(a).compareTo(listingTypeToWire(b)));
  for (final t in types) {
    typeStrings.add(listingTypeToWire(t));
  }

  return <String, dynamic>{
    ListingDiscoveryCriteriaJsonSchema.schemaVersionKey:
        ListingDiscoveryCriteriaJsonSchema.currentVersion,
    'search': c.search,
    'make': c.make,
    'model': c.model,
    'minYear': c.minYear,
    'maxYear': c.maxYear,
    'minPrice': c.minPrice,
    'maxPrice': c.maxPrice,
    'maxMileage': c.maxMileage,
    'city': c.city,
    'marketRegion': marketRegionToWireNullable(c.marketRegion),
    'bodyType': c.bodyType == null ? null : listingBodyTypeToWire(c.bodyType!),
    'fuelType': c.fuelType == null ? null : listingFuelTypeToWire(c.fuelType!),
    'transmissionType': c.transmissionType == null
        ? null
        : listingTransmissionTypeToWire(c.transmissionType!),
    'drivetrain': c.drivetrain == null
        ? null
        : listingDrivetrainToWire(c.drivetrain!),
    'typeIn': typeStrings.isEmpty ? <String>[] : typeStrings,
    'priceCurrencyFilter': listingPriceCurrencyFilterToWire(
      c.priceCurrencyFilter,
    ),
    'sort': listingSortOptionToWire(c.sort),
  };
}

/// Decodes persisted JSON safely. Unknown enum tokens are ignored or folded to neutral defaults.
ListingDiscoveryCriteria? listingDiscoveryCriteriaFromJson(dynamic raw) {
  if (raw == null) return null;

  late final Map<String, dynamic> map;
  if (raw is Map<String, dynamic>) {
    map = raw;
  } else if (raw is Map) {
    map = Map<String, dynamic>.from(raw);
  } else {
    return null;
  }

  final v = map[ListingDiscoveryCriteriaJsonSchema.schemaVersionKey];
  if (v != ListingDiscoveryCriteriaJsonSchema.currentVersion) {
    return null;
  }

  final typeInWire = map['typeIn'];
  List<ListingType>? typeInDecoded;
  if (typeInWire is List && typeInWire.isNotEmpty) {
    final resolved = <ListingType>{};
    for (final rawItem in typeInWire) {
      if (rawItem is! String) continue;
      final parsed = listingTypeFromWire(rawItem);
      if (parsed != null) resolved.add(parsed);
    }
    if (resolved.isNotEmpty) {
      final typed = resolved.toList()..sort((a, b) => a.name.compareTo(b.name));
      typeInDecoded = typed;
    }
  }

  return ListingDiscoveryCriteria(
    search: map['search']?.toString(),
    make: map['make']?.toString(),
    model: map['model']?.toString(),
    minYear: _intOrNull(map['minYear']),
    maxYear: _intOrNull(map['maxYear']),
    minPrice: _numOrNull(map['minPrice']),
    maxPrice: _numOrNull(map['maxPrice']),
    maxMileage: _intOrNull(map['maxMileage']),
    city: map['city']?.toString(),
    marketRegion: marketRegionFromWire(map['marketRegion']?.toString()),
    bodyType: listingBodyTypeFromWire(map['bodyType']?.toString()),
    fuelType: listingFuelTypeFromWire(map['fuelType']?.toString()),
    transmissionType: listingTransmissionTypeFromWire(
      map['transmissionType']?.toString(),
    ),
    drivetrain: listingDrivetrainFromWire(map['drivetrain']?.toString()),
    typeIn: typeInDecoded,
    priceCurrencyFilter: listingPriceCurrencyFilterFromWire(
      map['priceCurrencyFilter']?.toString(),
    ),
    sort: listingSortOptionFromWire(map['sort']?.toString()),
  );
}

int? _intOrNull(dynamic raw) {
  if (raw == null) return null;
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) return int.tryParse(raw.trim());
  return null;
}

num? _numOrNull(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) return raw;
  if (raw is String) return num.tryParse(raw.trim());
  return null;
}
