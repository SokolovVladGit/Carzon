import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/listing_discovery_criteria_json.dart';
import '../../domain/listing_discovery_state_sync.dart';

abstract interface class LastAppliedListingDiscoveryRepository {
  Future<ListingDiscoveryCriteria?> load();

  /// Saves [snapshot] locally, or removes storage when it matches catalog defaults.
  Future<void> persistIfNeeded(ListingDiscoveryCriteria snapshot);
}

final class SharedPreferencesLastAppliedListingDiscoveryRepository
    implements LastAppliedListingDiscoveryRepository {
  static const String _prefsKey =
      'carzon.listing_discovery_criteria.persisted_json.v1';

  @override
  Future<ListingDiscoveryCriteria?> load() async {
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

  @override
  Future<void> persistIfNeeded(ListingDiscoveryCriteria snapshot) async {
    final prefs = await SharedPreferences.getInstance();
    final shadow = listingsStateFromDiscoveryCriteria(snapshot);
    if (isDefaultListingsDiscoveryState(shadow)) {
      await prefs.remove(_prefsKey);
      return;
    }

    await prefs.setString(_prefsKey, jsonEncode(listingDiscoveryCriteriaToJson(snapshot)));
  }
}
