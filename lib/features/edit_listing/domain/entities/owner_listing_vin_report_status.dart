import 'package:equatable/equatable.dart';

/// Owner-safe row from `get_my_listing_vin_report_status` (no full VIN / no vin_hash).
class OwnerListingVinReportStatus extends Equatable {
  const OwnerListingVinReportStatus({
    required this.listingId,
    this.publicVinStatusRaw,
    this.processingStatusRaw,
    this.decodeStatusRaw,
    this.verificationStatusRaw,
    this.mismatchStatusRaw,
    this.decodedMake,
    this.decodedModel,
    this.decodedYear,
    this.decodedBodyType,
    this.decodedFuelType,
    this.reportUpdatedAt,
  });

  final String listingId;

  /// `listings.vin_status` (`not_provided` / `format_valid`).
  final String? publicVinStatusRaw;

  final String? processingStatusRaw;
  final String? decodeStatusRaw;
  final String? verificationStatusRaw;
  final String? mismatchStatusRaw;

  /// Sanitized snapshot fields; never a full VIN.
  final String? decodedMake;
  final String? decodedModel;
  final int? decodedYear;
  final String? decodedBodyType;
  final String? decodedFuelType;

  /// Snapshot `updated_at`; optional for future UI.
  final DateTime? reportUpdatedAt;

  static String? _trimmed(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _year(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    final n = int.tryParse(v.toString().trim());
    return n;
  }

  static DateTime? _ts(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;
    return DateTime.tryParse(v.toString());
  }

  /// At least one non-empty decoded text/year for owner summary UI.
  bool get hasDecodedSummaryFields =>
      (decodedMake != null && decodedMake!.trim().isNotEmpty) ||
      (decodedModel != null && decodedModel!.trim().isNotEmpty) ||
      decodedYear != null ||
      (decodedBodyType != null && decodedBodyType!.trim().isNotEmpty) ||
      (decodedFuelType != null && decodedFuelType!.trim().isNotEmpty);

  /// Best-effort parse; returns null when the row is unusable.
  static OwnerListingVinReportStatus? tryParse(Map<String, dynamic> row) {
    try {
      final rawId = row['listing_id'];
      if (rawId == null) return null;
      final listingId = rawId is String ? rawId : rawId.toString();

      return OwnerListingVinReportStatus(
        listingId: listingId,
        publicVinStatusRaw: _trimmed(row['vin_status']),
        processingStatusRaw: _trimmed(row['processing_status']),
        decodeStatusRaw: _trimmed(row['decode_status']),
        verificationStatusRaw: _trimmed(row['verification_status']),
        mismatchStatusRaw: _trimmed(row['mismatch_status']),
        decodedMake: _trimmed(row['decoded_make']),
        decodedModel: _trimmed(row['decoded_model']),
        decodedYear: _year(row['decoded_year']),
        decodedBodyType: _trimmed(row['decoded_body_type']),
        decodedFuelType: _trimmed(row['decoded_fuel_type']),
        reportUpdatedAt: _ts(row['report_updated_at']),
      );
    } catch (_) {
      return null;
    }
  }

  @override
  List<Object?> get props => [
    listingId,
    publicVinStatusRaw,
    processingStatusRaw,
    decodeStatusRaw,
    verificationStatusRaw,
    mismatchStatusRaw,
    decodedMake,
    decodedModel,
    decodedYear,
    decodedBodyType,
    decodedFuelType,
    reportUpdatedAt,
  ];
}

/// Outcome of `get_my_listing_vin_report_status` for the edit flow (never public).
class OwnerListingVinReportLookupResult extends Equatable {
  const OwnerListingVinReportLookupResult({
    this.status,
    this.fetchFailed = false,
  });

  final OwnerListingVinReportStatus? status;

  /// RPC/network/parse failure — non-fatal for editing.
  final bool fetchFailed;

  @override
  List<Object?> get props => [status, fetchFailed];
}
