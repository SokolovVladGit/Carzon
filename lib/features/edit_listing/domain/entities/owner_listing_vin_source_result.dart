import 'package:equatable/equatable.dart';

/// Owner-safe row from `get_my_listing_vin_source_results` (sanitized projection only).
class OwnerListingVinSourceResult extends Equatable {
  const OwnerListingVinSourceResult({
    required this.sourceId,
    this.regionRaw,
    this.accessModeRaw,
    this.statusRaw,
    this.visibilityRaw,
    this.confidenceRaw,
    this.normalizedSummary,
    this.limitationCodes = const [],
    this.requiresUserConsent = false,
    this.consentRequiredReason,
    this.sourceLabel,
    this.providerVersion,
    this.fetchedAt,
    this.ttlUntil,
    this.updatedAt,
  });

  final String sourceId;
  final String? regionRaw;
  final String? accessModeRaw;
  final String? statusRaw;
  final String? visibilityRaw;
  final String? confidenceRaw;
  final Map<String, dynamic>? normalizedSummary;
  final List<String> limitationCodes;
  final bool requiresUserConsent;
  final String? consentRequiredReason;
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

  /// NHTSA basic-decode row eligible to drive owner "Базовая информация" UI.
  bool get isNhtsaBasicDecodeEligible {
    if (sourceId != 'nhtsa_vpic') return false;
    final s = statusRaw?.trim().toLowerCase();
    if (s != 'succeeded' && s != 'partial') return false;
    return hasBasicSummaryKeys;
  }

  bool get hasBasicSummaryKeys {
    final m = normalizedSummary;
    if (m == null || m.isEmpty) return false;
    bool nonEmpty(String k) {
      final v = m[k];
      if (v == null) return false;
      if (v is num) return true;
      final t = v.toString().trim();
      return t.isNotEmpty;
    }

    return nonEmpty('make') ||
        nonEmpty('model') ||
        nonEmpty('year') ||
        nonEmpty('body_type') ||
        nonEmpty('fuel_type') ||
        nonEmpty('engine') ||
        nonEmpty('transmission');
  }

  static OwnerListingVinSourceResult? tryParse(Map<String, dynamic> row) {
    try {
      final sid = _trim(row['source_id']);
      if (sid == null) return null;
      return OwnerListingVinSourceResult(
        sourceId: sid,
        regionRaw: _trim(row['region']),
        accessModeRaw: _trim(row['access_mode']),
        statusRaw: _trim(row['status']),
        visibilityRaw: _trim(row['visibility']),
        confidenceRaw: _trim(row['confidence']),
        normalizedSummary: _summary(row['normalized_summary']),
        limitationCodes: _codes(row['limitation_codes']),
        requiresUserConsent: row['requires_user_consent'] == true,
        consentRequiredReason: _trim(row['consent_required_reason']),
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
    regionRaw,
    accessModeRaw,
    statusRaw,
    visibilityRaw,
    confidenceRaw,
    normalizedSummary,
    limitationCodes,
    requiresUserConsent,
    consentRequiredReason,
    sourceLabel,
    providerVersion,
    fetchedAt,
    ttlUntil,
    updatedAt,
  ];
}

/// Outcome of `get_my_listing_vin_source_results` (owner-only).
class OwnerListingVinSourceResultsLookupResult extends Equatable {
  const OwnerListingVinSourceResultsLookupResult({
    this.results = const [],
    this.fetchFailed = false,
  });

  final List<OwnerListingVinSourceResult> results;

  /// RPC/network/parse failure — non-fatal for editing.
  final bool fetchFailed;

  @override
  List<Object?> get props => [results, fetchFailed];
}
