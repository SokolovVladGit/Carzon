import 'package:equatable/equatable.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/owner_listing_vin_report_status.dart';
import '../../domain/entities/owner_listing_vin_source_result.dart';

/// User-facing VIN report status bucket for edit page (seller-only).
enum EditListingOwnerVinReportUiKind {
  noVinListed,
  unavailable,
  inProgress,
  basicInfoProcessed,
  basicInfoFailed,
}

/// Maps owner RPC status + listing VIN hint into conservative UI buckets.
EditListingOwnerVinReportUiKind resolveEditListingOwnerVinReportUiKind({
  required ListingVinStatus listingPublicVinStatus,
  required bool reportFetchFailed,
  required OwnerListingVinReportStatus? report,
}) {
  if (listingPublicVinStatus != ListingVinStatus.formatValid) {
    return EditListingOwnerVinReportUiKind.noVinListed;
  }
  if (reportFetchFailed) {
    return EditListingOwnerVinReportUiKind.unavailable;
  }
  if (report == null) {
    return EditListingOwnerVinReportUiKind.unavailable;
  }

  final p = report.processingStatusRaw?.trim().toLowerCase();
  final d = report.decodeStatusRaw?.trim().toLowerCase();

  if (p == null && d == null) {
    return EditListingOwnerVinReportUiKind.unavailable;
  }

  const terminalDecodeFailures = <String>{
    'failed',
    'provider_unavailable',
    'rate_limited',
    'quota_exceeded',
  };

  final processingFailed = p == 'failed' || p == 'cancelled';
  final decodeFailed = d != null && terminalDecodeFailures.contains(d);

  if (processingFailed || decodeFailed) {
    return EditListingOwnerVinReportUiKind.basicInfoFailed;
  }

  final basicDone = p == 'succeeded' && d == 'decoded';
  if (basicDone) {
    return EditListingOwnerVinReportUiKind.basicInfoProcessed;
  }

  const inFlightProcessing = {'pending', 'processing', 'stale'};
  if (p != null && inFlightProcessing.contains(p)) {
    return EditListingOwnerVinReportUiKind.inProgress;
  }

  const queuedDecode = {'pending', 'not_requested', 'stale'};
  if (d != null && queuedDecode.contains(d)) {
    return EditListingOwnerVinReportUiKind.inProgress;
  }

  if (p == 'succeeded' && d != null && d != 'decoded') {
    return EditListingOwnerVinReportUiKind.inProgress;
  }

  return EditListingOwnerVinReportUiKind.unavailable;
}

/// Owner-only decoded summary: succeeded + decoded + at least one field.
bool editListingOwnerVinReportShowDecodedSummary(
  OwnerListingVinReportStatus? r,
) {
  if (r == null) return false;
  final dec = r.decodeStatusRaw?.trim().toLowerCase();
  final proc = r.processingStatusRaw?.trim().toLowerCase();
  if (dec != 'decoded' || proc != 'succeeded') return false;
  return r.hasDecodedSummaryFields;
}

/// Normalized basic-decode fields for owner "Базовая информация" (never a full VIN).
class OwnerVinBasicDecodeFields extends Equatable {
  const OwnerVinBasicDecodeFields({
    this.make,
    this.model,
    this.year,
    this.bodyType,
    this.fuelType,
    this.engine,
    this.transmission,
    this.trim,
    this.driveType,
    this.manufacturer,
  });

  final String? make;
  final String? model;
  final int? year;
  final String? bodyType;
  final String? fuelType;
  final String? engine;
  final String? transmission;
  final String? trim;
  final String? driveType;
  final String? manufacturer;

  bool get hasAny =>
      (make != null && make!.trim().isNotEmpty) ||
      (model != null && model!.trim().isNotEmpty) ||
      year != null ||
      (bodyType != null && bodyType!.trim().isNotEmpty) ||
      (fuelType != null && fuelType!.trim().isNotEmpty) ||
      (engine != null && engine!.trim().isNotEmpty) ||
      (transmission != null && transmission!.trim().isNotEmpty) ||
      (trim != null && trim!.trim().isNotEmpty) ||
      (driveType != null && driveType!.trim().isNotEmpty) ||
      (manufacturer != null && manufacturer!.trim().isNotEmpty);

  @override
  List<Object?> get props => [
    make,
    model,
    year,
    bodyType,
    fuelType,
    engine,
    transmission,
    trim,
    driveType,
    manufacturer,
  ];
}

String? _summaryString(dynamic v) {
  if (v == null) return null;
  final s = v.toString().trim();
  return s.isEmpty ? null : s;
}

int? _summaryYear(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString().trim());
}

/// Prefers `nhtsa_vpic` [OwnerListingVinSourceResult.normalizedSummary], else legacy snapshot fields.
OwnerVinBasicDecodeFields? resolveOwnerVinBasicDecodeFields({
  required OwnerListingVinReportStatus? report,
  required List<OwnerListingVinSourceResult> sourceResults,
  required bool sourceResultsLookupFailed,
}) {
  if (!sourceResultsLookupFailed) {
    for (final r in sourceResults) {
      if (!r.isNhtsaBasicDecodeEligible) continue;
      final m = r.normalizedSummary;
      if (m == null) continue;
      final fields = OwnerVinBasicDecodeFields(
        make: _summaryString(m['make']),
        model: _summaryString(m['model']),
        year: _summaryYear(m['year']),
        bodyType: _summaryString(m['body_type']),
        fuelType: _summaryString(m['fuel_type']),
        engine: _summaryString(m['engine']),
        transmission: _summaryString(m['transmission']),
        trim: _summaryString(m['trim']),
        driveType: _summaryString(m['drive_type']),
        manufacturer: _summaryString(m['manufacturer']),
      );
      if (fields.hasAny) return fields;
    }
  }

  if (report == null || !editListingOwnerVinReportShowDecodedSummary(report)) {
    return null;
  }
  return OwnerVinBasicDecodeFields(
    make: _summaryString(report.decodedMake),
    model: _summaryString(report.decodedModel),
    year: report.decodedYear,
    bodyType: _summaryString(report.decodedBodyType),
    fuelType: _summaryString(report.decodedFuelType),
  );
}

/// Whether to show the owner basic info block (Phase 2H: source results or legacy snapshot).
bool editListingOwnerVinReportShowDecodedSummaryForOwner({
  required OwnerListingVinReportStatus? report,
  required List<OwnerListingVinSourceResult> sourceResults,
  required bool sourceResultsLookupFailed,
}) {
  final f = resolveOwnerVinBasicDecodeFields(
    report: report,
    sourceResults: sourceResults,
    sourceResultsLookupFailed: sourceResultsLookupFailed,
  );
  return f != null && f.hasAny;
}

/// Localized primary line for the owner-only VIN status block on edit listing.
String editListingOwnerVinReportPrimaryLine(
  AppLocalizations l10n,
  EditListingOwnerVinReportUiKind kind,
) {
  return switch (kind) {
    EditListingOwnerVinReportUiKind.noVinListed =>
      l10n.editListingVinReportNoVinBody,
    EditListingOwnerVinReportUiKind.unavailable =>
      l10n.editListingVinReportUnavailableBody,
    EditListingOwnerVinReportUiKind.inProgress =>
      l10n.editListingVinReportPendingBody,
    EditListingOwnerVinReportUiKind.basicInfoProcessed =>
      l10n.editListingVinReportDecodedBody,
    EditListingOwnerVinReportUiKind.basicInfoFailed =>
      l10n.editListingVinReportFailedBody,
  };
}
