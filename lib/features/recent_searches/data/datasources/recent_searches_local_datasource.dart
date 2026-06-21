import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../listings/domain/listing_discovery_criteria_json.dart';
import '../../domain/entities/recent_search_entry.dart';

/// Reads/writes recent discovery searches in [SharedPreferences].
abstract interface class RecentSearchesLocalDataSource {
  Future<List<RecentSearchEntry>> loadEntries();

  Future<void> saveEntries(List<RecentSearchEntry> entries);

  Future<void> clear();
}

final class SharedPreferencesRecentSearchesLocalDataSource
    implements RecentSearchesLocalDataSource {
  static const String storageKey = 'carzon.recent_searches.v1';

  @override
  Future<List<RecentSearchEntry>> loadEntries() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return const [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return const [];
      final out = <RecentSearchEntry>[];
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
  Future<void> saveEntries(List<RecentSearchEntry> entries) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded = jsonEncode(entries.map(_entryToJson).toList());
    await prefs.setString(storageKey, encoded);
  }

  @override
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(storageKey);
  }

  static Map<String, dynamic> _entryToJson(RecentSearchEntry entry) {
    return {
      'criteria': listingDiscoveryCriteriaToJson(entry.criteria),
      'searched_at': entry.searchedAt.toUtc().toIso8601String(),
    };
  }

  static RecentSearchEntry? _parseEntry(dynamic entry) {
    if (entry is! Map) return null;
    final map = entry is Map<String, dynamic>
        ? entry
        : Map<String, dynamic>.from(entry);

    final criteriaRaw = map['criteria'];
    if (criteriaRaw == null) return null;
    final criteria = listingDiscoveryCriteriaFromJson(criteriaRaw);
    if (criteria == null) return null;

    final searchedAt = _parseDate(map['searched_at']) ?? DateTime.now().toUtc();
    return RecentSearchEntry(criteria: criteria, searchedAt: searchedAt);
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value.toUtc();
    return DateTime.tryParse(value.toString())?.toUtc();
  }
}
