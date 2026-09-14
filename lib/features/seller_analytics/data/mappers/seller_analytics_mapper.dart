import '../../../../core/errors/exceptions.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../sellers/domain/entities/seller_type.dart';
import '../../domain/entities/seller_analytics_daily_point.dart';
import '../../domain/entities/seller_analytics_summary.dart';
import '../../domain/entities/seller_engagement_summary.dart';
import '../../domain/entities/seller_inventory_demand.dart';
import '../../domain/entities/seller_listing_demand.dart';
import '../../domain/entities/seller_listing_engagement.dart';
import '../../domain/entities/seller_listing_performance.dart';

SellerAnalyticsSummary sellerAnalyticsSummaryFromRow(Map<String, dynamic> row) {
  return SellerAnalyticsSummary(
    sellerType: parseSellerAnalyticsSellerType(row['seller_type']),
    verifiedDealer: parseSellerAnalyticsBool(row['verified_dealer']),
    activeCount: parseSellerAnalyticsInt(row['active_count'], 'active_count'),
    soldCount: parseSellerAnalyticsInt(row['sold_count'], 'sold_count'),
    periodViews: parseSellerAnalyticsInt(row['period_views'], 'period_views'),
    currentFavorites: parseSellerAnalyticsInt(
      row['current_favorites'],
      'current_favorites',
    ),
    periodInquiries: parseSellerAnalyticsInt(
      row['period_inquiries'],
      'period_inquiries',
    ),
    conversionPercent: parseSellerAnalyticsNullablePercent(
      row['conversion_percent'],
    ),
  );
}

SellerAnalyticsDailyPoint sellerAnalyticsDailyPointFromRow(
  Map<String, dynamic> row,
) {
  return SellerAnalyticsDailyPoint(
    date: parseSellerAnalyticsDate(row['metric_date'], 'metric_date'),
    views: parseSellerAnalyticsInt(row['views'], 'views'),
  );
}

SellerEngagementSummary sellerEngagementSummaryFromRow(
  Map<String, dynamic> row,
) {
  return SellerEngagementSummary(
    periodImpressions: parseSellerAnalyticsInt(
      row['period_impressions'],
      'period_impressions',
    ),
    periodPhoneActions: parseSellerAnalyticsInt(
      row['period_phone_actions'],
      'period_phone_actions',
    ),
    periodWhatsappActions: parseSellerAnalyticsInt(
      row['period_whatsapp_actions'],
      'period_whatsapp_actions',
    ),
    periodTelegramActions: parseSellerAnalyticsInt(
      row['period_telegram_actions'],
      'period_telegram_actions',
    ),
    periodShares: parseSellerAnalyticsInt(
      row['period_shares'],
      'period_shares',
    ),
  );
}

SellerListingEngagement sellerListingEngagementFromRow(
  Map<String, dynamic> row,
) {
  return SellerListingEngagement(
    listingId: parseSellerAnalyticsRequiredText(
      row['listing_id'],
      'listing_id',
    ),
    periodImpressions: parseSellerAnalyticsInt(
      row['period_impressions'],
      'period_impressions',
    ),
    periodPhoneActions: parseSellerAnalyticsInt(
      row['period_phone_actions'],
      'period_phone_actions',
    ),
    periodWhatsappActions: parseSellerAnalyticsInt(
      row['period_whatsapp_actions'],
      'period_whatsapp_actions',
    ),
    periodTelegramActions: parseSellerAnalyticsInt(
      row['period_telegram_actions'],
      'period_telegram_actions',
    ),
    periodShares: parseSellerAnalyticsInt(
      row['period_shares'],
      'period_shares',
    ),
  );
}

SellerInventoryDemand sellerInventoryDemandFromRow(Map<String, dynamic> row) {
  final matchingUsers = parseSellerAnalyticsNullableInt(
    row['matching_users'],
    'matching_users',
  );
  final isSuppressed = parseSellerAnalyticsBool(row['is_suppressed']);
  assertSellerDemandInvariant(
    matchingUsers: matchingUsers,
    isSuppressed: isSuppressed,
    field: 'inventory demand',
  );
  return SellerInventoryDemand(
    matchingUsers: matchingUsers,
    isSuppressed: isSuppressed,
  );
}

SellerListingDemand sellerListingDemandFromRow(Map<String, dynamic> row) {
  final matchingUsers = parseSellerAnalyticsNullableInt(
    row['matching_users'],
    'matching_users',
  );
  final isSuppressed = parseSellerAnalyticsBool(row['is_suppressed']);
  assertSellerDemandInvariant(
    matchingUsers: matchingUsers,
    isSuppressed: isSuppressed,
    field: 'listing demand',
  );
  return SellerListingDemand(
    listingId: parseSellerAnalyticsRequiredText(
      row['listing_id'],
      'listing_id',
    ),
    matchingUsers: matchingUsers,
    isSuppressed: isSuppressed,
  );
}

void assertSellerDemandInvariant({
  required int? matchingUsers,
  required bool isSuppressed,
  required String field,
}) {
  if (isSuppressed) {
    if (matchingUsers != null) {
      throw ServerException(
        'Seller analytics $field suppressed matching_users must be null.',
      );
    }
    return;
  }
  if (matchingUsers == null) {
    throw ServerException('Seller analytics $field matching_users is missing.');
  }
  if (matchingUsers < 0) {
    throw ServerException(
      'Seller analytics $field matching_users is negative.',
    );
  }
  if (matchingUsers > 0 && matchingUsers < 5) {
    throw ServerException(
      'Seller analytics $field leaked a suppressed matching_users count.',
    );
  }
}

SellerListingPerformance sellerListingPerformanceFromRow(
  Map<String, dynamic> row,
) {
  return SellerListingPerformance(
    listingId: parseSellerAnalyticsRequiredText(
      row['listing_id'],
      'listing_id',
    ),
    title: parseSellerAnalyticsText(row['title']),
    status: parseSellerAnalyticsListingStatus(row['status']),
    createdAt: parseSellerAnalyticsDateTime(row['created_at'], 'created_at'),
    soldAt: parseSellerAnalyticsNullableDateTime(row['sold_at'], 'sold_at'),
    make: parseSellerAnalyticsText(row['make']),
    model: parseSellerAnalyticsText(row['model']),
    year: parseSellerAnalyticsInt(row['year'], 'year'),
    periodViews: parseSellerAnalyticsInt(row['period_views'], 'period_views'),
    currentFavorites: parseSellerAnalyticsInt(
      row['current_favorites'],
      'current_favorites',
    ),
    periodInquiries: parseSellerAnalyticsInt(
      row['period_inquiries'],
      'period_inquiries',
    ),
  );
}

SellerType parseSellerAnalyticsSellerType(dynamic raw) {
  return SellerType.fromWire(raw);
}

ListingStatus parseSellerAnalyticsListingStatus(dynamic raw) {
  final key = _normalizedKey(raw);
  switch (key) {
    case 'hidden':
      return ListingStatus.hidden;
    case 'sold':
      return ListingStatus.sold;
    case 'archived':
      return ListingStatus.archived;
    default:
      return ListingStatus.active;
  }
}

int? parseSellerAnalyticsNullableInt(dynamic raw, String field) {
  if (raw == null) return null;
  return parseSellerAnalyticsInt(raw, field);
}

int parseSellerAnalyticsInt(dynamic raw, String field) {
  if (raw is int) return raw;
  if (raw is num) return raw.toInt();
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ServerException('Seller analytics $field is empty.');
    }
    final asInt = int.tryParse(trimmed);
    if (asInt != null) return asInt;
    final asDouble = double.tryParse(trimmed);
    if (asDouble != null && asDouble.isFinite) return asDouble.toInt();
  }
  throw ServerException('Seller analytics $field has an invalid value.');
}

double? parseSellerAnalyticsNullablePercent(dynamic raw) {
  if (raw == null) return null;
  if (raw is num) {
    return raw.isFinite ? raw.toDouble() : null;
  }
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;
    final parsed = double.tryParse(trimmed);
    if (parsed == null) {
      throw ServerException(
        'Seller analytics conversion_percent has an invalid value.',
      );
    }
    return parsed.isFinite ? parsed : null;
  }
  throw ServerException(
    'Seller analytics conversion_percent has an unexpected type.',
  );
}

bool parseSellerAnalyticsBool(dynamic raw) {
  if (raw is bool) return raw;
  if (raw is num) return raw != 0;
  final key = _normalizedKey(raw);
  return key == 'true' || key == 't' || key == '1';
}

String parseSellerAnalyticsRequiredText(dynamic raw, String field) {
  final text = parseSellerAnalyticsText(raw);
  if (text.isEmpty) {
    throw ServerException('Seller analytics $field is missing.');
  }
  return text;
}

String parseSellerAnalyticsText(dynamic raw) {
  if (raw == null) return '';
  if (raw is String) return raw.trim();
  return raw.toString().trim();
}

DateTime parseSellerAnalyticsDate(dynamic raw, String field) {
  final dt = parseSellerAnalyticsDateTime(raw, field);
  return DateTime(dt.year, dt.month, dt.day);
}

DateTime parseSellerAnalyticsDateTime(dynamic raw, String field) {
  if (raw is DateTime) return raw.toLocal();
  if (raw is String) {
    final trimmed = raw.trim();
    if (trimmed.isEmpty) {
      throw ServerException('Seller analytics $field is empty.');
    }
    final parsed = DateTime.tryParse(trimmed);
    if (parsed != null) return parsed.toLocal();
  }
  throw ServerException('Seller analytics $field has an invalid value.');
}

DateTime? parseSellerAnalyticsNullableDateTime(dynamic raw, String field) {
  if (raw == null) return null;
  if (raw is String && raw.trim().isEmpty) return null;
  return parseSellerAnalyticsDateTime(raw, field);
}

String? _normalizedKey(dynamic raw) {
  if (raw == null) return null;
  final text = raw is String ? raw : raw.toString();
  final trimmed = text.trim().toLowerCase();
  return trimmed.isEmpty ? null : trimmed;
}
