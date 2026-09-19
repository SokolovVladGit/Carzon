import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/listing_discovery_criteria_json.dart';
import '../../domain/listing_discovery_state_sync.dart';

abstract interface class LastAppliedListingDiscoveryRepository {
  Future<ListingDiscoveryCriteria?> load();

  /// Saves [snapshot] locally, or removes storage when it matches catalog defaults.
  ///
  /// Represents the latest **applied** discovery criteria, not the last
  /// successful listings query.
  Future<void> persistIfNeeded(ListingDiscoveryCriteria snapshot);
}

final class SharedPreferencesLastAppliedListingDiscoveryRepository
    implements LastAppliedListingDiscoveryRepository {
  static const String _prefsKey =
      'carzon.listing_discovery_criteria.persisted_json.v1';

  ListingDiscoveryCriteria? _cached;
  bool _hasCache = false;
  int _persistGeneration = 0;
  Future<void> _persistTail = Future<void>.value();

  @override
  Future<ListingDiscoveryCriteria?> load() async {
    if (_hasCache) return _cached;
    return _loadFromDisk();
  }

  @override
  Future<void> persistIfNeeded(ListingDiscoveryCriteria snapshot) {
    final shadow = listingsStateFromDiscoveryCriteria(snapshot);
    final stored = isDefaultListingsDiscoveryState(shadow) ? null : snapshot;
    _cached = stored;
    _hasCache = true;
    final generation = ++_persistGeneration;
    _persistTail = _persistTail
        .catchError((_) {})
        .then((_) => _writeDiskIfCurrent(stored, generation));
    return _persistTail;
  }

  Future<ListingDiscoveryCriteria?> _loadFromDisk() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      Map<String, dynamic>? map;
      if (decoded is Map<String, dynamic>) {
        map = decoded;
      } else if (decoded is Map) {
        map = Map<String, dynamic>.from(decoded);
      }
      if (map == null) return null;
      return listingDiscoveryCriteriaFromJson(map);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeDiskIfCurrent(
    ListingDiscoveryCriteria? stored,
    int generation,
  ) async {
    if (generation != _persistGeneration) return;
    final prefs = await SharedPreferences.getInstance();
    if (generation != _persistGeneration) return;
    if (stored == null) {
      await prefs.remove(_prefsKey);
      return;
    }
    await prefs.setString(
      _prefsKey,
      jsonEncode(listingDiscoveryCriteriaToJson(stored)),
    );
  }
}
