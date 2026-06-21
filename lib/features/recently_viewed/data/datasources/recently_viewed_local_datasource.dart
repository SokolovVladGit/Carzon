import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/listing_discovery_criteria_json.dart';
import '../../domain/entities/recently_viewed_entry.dart';

/// Reads/writes recently viewed listings in [SharedPreferences].
abstract interface class RecentlyViewedLocalDataSource {
  Future<List<RecentlyViewedEntry>> loadEntries();

  Future<void> saveEntries(List<RecentlyViewedEntry> entries);

  Future<void> clear();
}

final class SharedPreferencesRecentlyViewedLocalDataSource
    implements RecentlyViewedLocalDataSource {
  static const String storageKey = 'carzon.recently_viewed.v1';
  static const int maxEntries = 30;

  @override
  Future<List<RecentlyViewedEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <RecentlyViewedEntry>[];
      for (final entry in decoded) {
        final parsed = _parseEntry(entry);
        if (parsed != null) out.add(parsed);
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<void> saveEntries(List<RecentlyViewedEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final capped = entries.length > maxEntries
        ? entries.sublist(0, maxEntries)
        : entries;
    final encoded = jsonEncode(capped.map(_entryToJson).toList());
    await prefs.setString(storageKey, encoded);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  static Map<String, dynamic> _entryToJson(RecentlyViewedEntry entry) {
    return {
      'listing_id': entry.listingId,
      'viewed_at': entry.viewedAt.toUtc().toIso8601String(),
      'title': entry.title,
      'make': entry.make,
      'model': entry.model,
      'year': entry.year,
      'price_eur': entry.priceEur,
      'price_currency': listingCurrencyToDbString(entry.priceCurrency),
      'city': entry.city,
      'market_region': entry.marketRegion.name,
      if (entry.coverImageUrl != null) 'cover_image_url': entry.coverImageUrl,
    };
  }

  static RecentlyViewedEntry? _parseEntry(dynamic entry) {
    if (entry is! Map) return null;
    final map = entry is Map<String, dynamic>
        ? entry
        : Map<String, dynamic>.from(entry);

    final listingId = _trim(map['listing_id']);
    if (listingId == null) return null;

    final region = marketRegionFromWire(map['market_region']?.toString());
    if (region == null) return null;

    final viewedAt = _parseDate(map['viewed_at']) ?? DateTime.now().toUtc();
    final year = _parseInt(map['year']);
    if (year == null) return null;

    final priceEur = _parseNum(map['price_eur']);
    if (priceEur == null) return null;

    final make = _trim(map['make']) ?? '';
    final model = _trim(map['model']) ?? '';
    final city = _trim(map['city']) ?? '';
    final title = _trim(map['title']) ?? '';

    return RecentlyViewedEntry(
      listingId: listingId,
      viewedAt: viewedAt,
      title: title,
      make: make,
      model: model,
      year: year,
      priceEur: priceEur,
      priceCurrency: listingCurrencyFromDbString(_trim(map['price_currency'])),
      city: city,
      marketRegion: region,
      coverImageUrl: _trim(map['cover_image_url']),
    );
  }

  static String? _trim(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString().trim());
  }

  static num? _parseNum(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    return num.tryParse(value.toString().trim());
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
