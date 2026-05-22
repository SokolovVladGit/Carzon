import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../listings/domain/entities/listing_currency.dart';
import '../../domain/entities/compare_item.dart';
import '../../domain/entities/compare_listing_snapshot.dart';

/// Reads/writes the ordered compare set in [SharedPreferences].
abstract interface class CompareLocalDataSource {
  Future<List<CompareItem>> loadItems();

  Future<void> saveItems(List<CompareItem> items);

  Future<void> clear();
}

final class SharedPreferencesCompareLocalDataSource
    implements CompareLocalDataSource {
  static const String storageKey = 'carzon.compare_set.v1';

  @override
  Future<List<CompareItem>> loadItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <CompareItem>[];
      for (final entry in decoded) {
        final item = _parseItem(entry);
        if (item != null) out.add(item);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveItems(List<CompareItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(items.map(_itemToJson).toList());
    await prefs.setString(storageKey, encoded);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  static Map<String, dynamic> _itemToJson(CompareItem item) {
    final s = item.snapshot;
    return {
      'listing_id': s.listingId,
      'added_at': s.addedAt.toUtc().toIso8601String(),
      if (s.coverImageUrl != null) 'cover_image_url': s.coverImageUrl,
      if (s.make != null) 'make': s.make,
      if (s.model != null) 'model': s.model,
      if (s.year != null) 'year': s.year,
      if (s.priceEur != null) 'price_eur': s.priceEur,
      'price_currency': listingCurrencyToDbString(s.priceCurrency),
      if (s.city != null) 'city': s.city,
      if (s.marketRegionRaw != null) 'market_region': s.marketRegionRaw,
    };
  }

  static CompareItem? _parseItem(dynamic entry) {
    if (entry is! Map) return null;
    final map = entry is Map<String, dynamic>
        ? entry
        : Map<String, dynamic>.from(entry);
    final id = _trim(map['listing_id']);
    if (id == null) return null;
    final addedAt = _parseDate(map['added_at']) ?? DateTime.now().toUtc();
    return CompareItem(
      snapshot: CompareListingSnapshot(
        listingId: id,
        addedAt: addedAt,
        coverImageUrl: _trim(map['cover_image_url']),
        make: _trim(map['make']),
        model: _trim(map['model']),
        year: _parseInt(map['year']),
        priceEur: _parseNum(map['price_eur']),
        priceCurrency: listingCurrencyFromDbString(
          _trim(map['price_currency']),
        ),
        city: _trim(map['city']),
        marketRegionRaw: _trim(map['market_region']),
      ),
    );
  }

  static String? _trim(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  static num? _parseNum(dynamic v) {
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString().trim());
  }

  static DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v.toUtc();
    return DateTime.tryParse(v.toString())?.toUtc();
  }
}
