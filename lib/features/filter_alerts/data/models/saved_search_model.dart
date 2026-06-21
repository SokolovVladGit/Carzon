import '../../../../core/errors/exceptions.dart';
import '../../../listings/domain/listing_discovery_criteria_json.dart';
import '../../domain/entities/saved_search.dart';

class SavedSearchModel extends SavedSearch {
  const SavedSearchModel({
    required super.id,
    required super.name,
    required super.criteria,
    required super.alertsEnabled,
    required super.createdAt,
    required super.updatedAt,
    super.lastNotifiedAt,
  });

  factory SavedSearchModel.fromRpcRow(Map<String, dynamic> row) {
    final idRaw = row['id']?.toString().trim() ?? '';
    if (idRaw.isEmpty) {
      throw ServerException('saved_searches.id invalid');
    }

    final nameRaw = row['name']?.toString().trim() ?? '';
    if (nameRaw.isEmpty) {
      throw ServerException('saved_searches.name invalid');
    }

    final criteriaRaw = row['criteria'];
    if (criteriaRaw is! Map) {
      throw ServerException('saved_searches.criteria is not an object');
    }
    final criteriaMap = criteriaRaw is Map<String, dynamic>
        ? criteriaRaw
        : Map<String, dynamic>.from(criteriaRaw);
    final criteria = listingDiscoveryCriteriaFromJson(criteriaMap);
    if (criteria == null) {
      throw ServerException('saved_searches.criteria invalid');
    }

    final alertsRaw = row['alerts_enabled'];
    if (alertsRaw is! bool) {
      throw ServerException('saved_searches.alerts_enabled invalid');
    }

    DateTime parseTs(dynamic v, String label) {
      if (v is String) return DateTime.parse(v.trim());
      throw ServerException('saved_searches missing $label');
    }

    DateTime? parseOptionalTs(dynamic v) {
      if (v == null) return null;
      if (v is String && v.trim().isEmpty) return null;
      if (v is String) return DateTime.parse(v.trim());
      return null;
    }

    return SavedSearchModel(
      id: idRaw,
      name: nameRaw,
      criteria: criteria,
      alertsEnabled: alertsRaw,
      createdAt: parseTs(row['created_at'], 'created_at'),
      updatedAt: parseTs(row['updated_at'], 'updated_at'),
      lastNotifiedAt: parseOptionalTs(row['last_notified_at']),
    );
  }
}
