import '../../../../core/errors/exceptions.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/domain/listing_discovery_criteria_json.dart';
import '../../domain/entities/filter_alert_settings.dart';

class FilterAlertSettingsModel extends FilterAlertSettings {
  const FilterAlertSettingsModel({
    required super.userId,
    required super.criteria,
    required super.notificationsEnabled,
    required super.createdAt,
    required super.updatedAt,
  });

  factory FilterAlertSettingsModel.fromSupabase(Map<String, dynamic> row) {
    final userIdRaw = row['user_id']?.toString().trim() ?? '';
    if (userIdRaw.isEmpty) {
      throw ServerException('filter_alert_settings.user_id invalid');
    }

    final criteriaRaw = row['criteria'];
    ListingDiscoveryCriteria? criteria;
    if (criteriaRaw == null) {
      criteria = null;
    } else if (criteriaRaw is Map) {
      final m =
          criteriaRaw is Map<String, dynamic>
              ? criteriaRaw
              : Map<String, dynamic>.from(criteriaRaw);
      criteria = listingDiscoveryCriteriaFromJson(m);
    } else {
      throw ServerException(
        'filter_alert_settings.criteria is not an object (${criteriaRaw.runtimeType}).',
      );
    }

    final notifRaw = row['notifications_enabled'];
    if (notifRaw is! bool) {
      throw ServerException(
        'filter_alert_settings.notifications_enabled invalid',
      );
    }

    DateTime parseTs(dynamic v, String label) {
      if (v is String) return DateTime.parse(v.trim());
      throw ServerException('filter_alert_settings missing $label');
    }

    return FilterAlertSettingsModel(
      userId: userIdRaw,
      criteria: criteria,
      notificationsEnabled: notifRaw,
      createdAt: parseTs(row['created_at'], 'created_at'),
      updatedAt: parseTs(row['updated_at'], 'updated_at'),
    );
  }
}
