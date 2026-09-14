import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/listing_engagement_record_result.dart';

ListingEngagementRecordResult listingEngagementRecordResultFromRow(
  Map<String, dynamic> row,
) {
  return ListingEngagementRecordResult(
    recorded: _asBool(row['recorded'], 'recorded'),
    todayCount: _asInt(row['today_count'], 'today_count'),
  );
}

Map<String, dynamic> listingEngagementRpcRow(dynamic data) {
  if (data is Map<String, dynamic>) return data;
  if (data is Map) return Map<String, dynamic>.from(data);
  if (data is List && data.isNotEmpty && data.first is Map) {
    return Map<String, dynamic>.from(data.first as Map);
  }
  throw ServerException(
    'Unexpected response from record_listing_engagement_event RPC.',
  );
}

bool _asBool(dynamic raw, String field) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  if (raw is String) {
    final key = raw.trim().toLowerCase();
    if (key == 'true' || key == 't' || key == '1') return true;
    if (key == 'false' || key == 'f' || key == '0' || key.isEmpty) {
      return false;
    }
  }
  throw ServerException('Engagement $field has an invalid value.');
}

int _asInt(dynamic raw, String field) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) {
    final parsed = int.tryParse(raw.trim());
    if (parsed != null) return parsed;
  }
  throw ServerException('Engagement $field has an invalid value.');
}
