import 'package:equatable/equatable.dart';

/// Buyer-safe row from `get_listing_model_data_for_buyer` (sanitized projection only).
class BuyerListingModelDataSourceResult extends Equatable {
  const BuyerListingModelDataSourceResult({
    required this.sourceId,
    this.status,
    this.confidence,
    this.normalizedSummary,
    this.limitationCodes = const [],
    this.matchQuality,
    this.sourceLabel,
    this.providerVersion,
    this.fetchedAt,
    this.ttlUntil,
    this.updatedAt,
  });

  final String sourceId;
  final String? status;
  final String? confidence;
  final Map<String, dynamic>? normalizedSummary;
  final List<String> limitationCodes;
  final String? matchQuality;
  final String? sourceLabel;
  final String? providerVersion;
  final DateTime? fetchedAt;
  final DateTime? ttlUntil;
  final DateTime? updatedAt;

  static String? _trim(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  static Map<String, dynamic>? _summary(dynamic v) {
    if (v == null) return null;
    if (v is Map<String, dynamic>) return v;
    if (v is Map) {
      return v.map((k, val) => MapEntry(k.toString(), val));
    }
    return null;
  }

  static List<String> _codes(dynamic v) {
    if (v == null) return const [];
    if (v is! List) return const [];
    final out = <String>[];
    for (final e in v) {
      final s = _trim(e);
      if (s != null) out.add(s);
    }
    return out;
  }

  static BuyerListingModelDataSourceResult? tryParse(Map<String, dynamic> row) {
    try {
      final sid = _trim(row['source_id']);
      if (sid == null) return null;
      return BuyerListingModelDataSourceResult(
        sourceId: sid,
        status: _trim(row['status']),
        confidence: _trim(row['confidence']),
        normalizedSummary: _summary(row['normalized_summary']),
        limitationCodes: _codes(row['limitation_codes']),
        matchQuality: _trim(row['match_quality']),
        sourceLabel: _trim(row['source_label']),
        providerVersion: _trim(row['provider_version']),
        fetchedAt: _ts(row['fetched_at']),
        ttlUntil: _ts(row['ttl_until']),
        updatedAt: _ts(row['updated_at']),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    sourceId,
    status,
    confidence,
    normalizedSummary,
    limitationCodes,
    matchQuality,
    sourceLabel,
    providerVersion,
    fetchedAt,
    ttlUntil,
    updatedAt,
  ];
}
