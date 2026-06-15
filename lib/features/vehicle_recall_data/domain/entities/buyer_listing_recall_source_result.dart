import 'package:equatable/equatable.dart';

import 'buyer_listing_recall_campaign.dart';

/// Buyer-safe row from `get_listing_recalls_for_buyer` (sanitized projection only).
class BuyerListingRecallSourceResult extends Equatable {
  const BuyerListingRecallSourceResult({
    this.sourceId,
    this.status,
    this.campaigns = const [],
    this.campaignCount = 0,
    this.sourceLabel,
    this.sourceUpdatedAt,
    this.fetchedAt,
    this.ttlUntil,
    this.updatedAt,
    this.limitationCodes = const [],
    this.matchQuality,
    this.market,
  });

  final String? sourceId;
  final String? status;
  final List<BuyerListingRecallCampaign> campaigns;
  final int campaignCount;
  final String? sourceLabel;
  final DateTime? sourceUpdatedAt;
  final DateTime? fetchedAt;
  final DateTime? ttlUntil;
  final DateTime? updatedAt;
  final List<String> limitationCodes;
  final String? matchQuality;
  final String? market;

  static const BuyerListingRecallSourceResult empty =
      BuyerListingRecallSourceResult();

  static const Set<String> _forbiddenTopLevelKeys = {
    'source_metadata',
    'cache_key',
    'job_id',
    'error_code',
    'error_message',
    'vin_hash',
    'vin_normalized',
    'listing_id',
    'raw_provider',
    'provider_response',
  };

  static String? _trim(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  static DateTime? _timestamp(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;
    return DateTime.tryParse(value.toString());
  }

  static int? _count(dynamic value) {
    if (value == null) return null;
    if (value is int) return value >= 0 ? value : null;
    if (value is num) {
      final n = value.toInt();
      return n >= 0 ? n : null;
    }
    return int.tryParse(value.toString().trim());
  }

  static Map<String, dynamic>? _summaryMap(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return value;
    if (value is Map) {
      return value.map((key, val) => MapEntry(key.toString(), val));
    }
    return null;
  }

  static List<String> _codes(dynamic value) {
    if (value == null) return const [];
    if (value is! List) return const [];
    final out = <String>[];
    for (final entry in value) {
      final code = _trim(entry);
      if (code != null) out.add(code);
    }
    return out;
  }

  static List<BuyerListingRecallCampaign> _campaignsFromSummary(
    Map<String, dynamic>? summary,
  ) {
    if (summary == null) return const [];
    final raw = summary['campaigns'];
    if (raw is! List) return const [];

    final out = <BuyerListingRecallCampaign>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final parsed = BuyerListingRecallCampaign.tryParse(
        Map<String, dynamic>.from(item),
      );
      if (parsed != null) out.add(parsed);
    }
    return out;
  }

  /// Parses one RPC row from `get_listing_recalls_for_buyer`.
  static BuyerListingRecallSourceResult? tryParseRow(
    Map<String, dynamic> row,
  ) {
    try {
      for (final key in row.keys) {
        if (_forbiddenTopLevelKeys.contains(key.trim().toLowerCase())) {
          return null;
        }
      }

      final summary = _summaryMap(row['normalized_summary']);
      final campaigns = _campaignsFromSummary(summary);
      final summaryCount = summary == null ? null : _count(summary['campaign_count']);
      final campaignCount = summaryCount ?? campaigns.length;

      return BuyerListingRecallSourceResult(
        sourceId: _trim(row['source_id']),
        status: _trim(row['status']),
        campaigns: campaigns,
        campaignCount: campaignCount,
        sourceLabel: _trim(row['source_label']),
        sourceUpdatedAt: _timestamp(row['source_updated_at']),
        fetchedAt: _timestamp(row['fetched_at']),
        ttlUntil: _timestamp(row['ttl_until']),
        updatedAt: _timestamp(row['updated_at']),
        limitationCodes: _codes(row['limitation_codes']),
        matchQuality: _trim(row['match_quality']) ??
            (summary == null ? null : _trim(summary['match_quality'])),
        market: summary == null ? null : _trim(summary['market']),
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses RPC payload list/object into a single buyer-safe result.
  static BuyerListingRecallSourceResult fromRpcData(dynamic data) {
    if (data == null) return empty;

    if (data is Map) {
      final parsed = tryParseRow(Map<String, dynamic>.from(data));
      return parsed ?? empty;
    }

    if (data is List) {
      for (final item in data) {
        if (item is! Map) continue;
        final parsed = tryParseRow(Map<String, dynamic>.from(item));
        if (parsed != null) return parsed;
      }
      return empty;
    }

    return empty;
  }

  bool get hasCampaigns => campaigns.isNotEmpty;

  @override
  List<Object?> get props => [
    sourceId,
    status,
    campaigns,
    campaignCount,
    sourceLabel,
    sourceUpdatedAt,
    fetchedAt,
    ttlUntil,
    updatedAt,
    limitationCodes,
    matchQuality,
    market,
  ];
}
