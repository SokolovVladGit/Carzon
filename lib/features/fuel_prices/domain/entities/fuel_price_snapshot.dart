import 'package:equatable/equatable.dart';

/// Public territory snapshot from `get_fuel_prices_for_app`.
class FuelPriceSnapshot extends Equatable {
  const FuelPriceSnapshot({
    required this.territory,
    required this.status,
    required this.isStale,
    required this.sourceLabel,
    required this.currency,
    required this.unit,
    required this.items,
    required this.limitationCodes,
    this.effectiveDate,
    this.fetchedAt,
  });

  final String territory;
  final String status;
  final bool isStale;
  final String sourceLabel;
  final String? effectiveDate;
  final DateTime? fetchedAt;
  final String currency;
  final String unit;
  final List<FuelPriceItem> items;
  final List<String> limitationCodes;

  bool get isAvailable =>
      status != 'unavailable' && items.isNotEmpty;

  static FuelPriceSnapshot? tryParse(Map<String, dynamic> row) {
    try {
      final snapshotRaw = row['snapshot'];
      if (snapshotRaw is! Map) return null;
      final map = Map<String, dynamic>.from(snapshotRaw);

      final territory = _trim(map['territory']);
      if (territory == null) return null;

      return FuelPriceSnapshot(
        territory: territory,
        status: _trim(map['status']) ?? 'unavailable',
        isStale: map['is_stale'] == true,
        sourceLabel: _trim(map['source_label']) ?? '',
        effectiveDate: _trim(map['effective_date']),
        fetchedAt: _ts(map['fetched_at']),
        currency: _trim(map['currency']) ?? '',
        unit: _trim(map['unit']) ?? 'liter',
        items: _items(map['items']),
        limitationCodes: _codes(map['limitation_codes']),
      );
    } catch (_) {
      return null;
    }
  }

  static String? _trim(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _ts(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static List<String> _codes(dynamic value) {
    if (value is! List) return const [];
    final out = <String>[];
    for (final entry in value) {
      final text = _trim(entry);
      if (text != null) out.add(text);
    }
    return out;
  }

  static List<FuelPriceItem> _items(dynamic value) {
    if (value is! List) return const [];
    final out = <FuelPriceItem>[];
    for (final entry in value) {
      if (entry is! Map) continue;
      final map = Map<String, dynamic>.from(entry);
      final fuelCode = _trim(map['fuel_code']);
      final priceRaw = map['price'];
      final price = priceRaw is num
          ? priceRaw.toDouble()
          : double.tryParse(priceRaw?.toString() ?? '');
      if (fuelCode == null || price == null) continue;
      out.add(FuelPriceItem(fuelCode: fuelCode, price: price));
    }
    return out;
  }

  @override
  List<Object?> get props => [
    territory,
    status,
    isStale,
    sourceLabel,
    effectiveDate,
    fetchedAt,
    currency,
    unit,
    items,
    limitationCodes,
  ];
}

class FuelPriceItem extends Equatable {
  const FuelPriceItem({required this.fuelCode, required this.price});

  final String fuelCode;
  final double price;

  @override
  List<Object?> get props => [fuelCode, price];
}
