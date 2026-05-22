import '../../domain/entities/buyer_listing_vin_report_source_result.dart';
import '../../domain/entities/listing.dart';
import 'nhtsa_vin_summary_display.dart';

/// Buyer-facing VIN report presentation state (frontend-only).
enum BuyerVinReportUiState {
  noVin,
  reportAvailable,
  loading,
  pendingOrNotReady,
  noPublicData,
  unavailableOrError,
}

/// Whether [summary] contains at least one buyer-displayable decoded field.
bool buyerVinReportHasDisplayableSummary(Map<String, dynamic>? summary) {
  if (summary == null || summary.isEmpty) return false;
  for (final entry in summary.entries) {
    final v = entry.value;
    if (v == null) continue;
    final s = v.toString().trim();
    if (s.isEmpty || s == kNhtsaWorkerNumericPlaceholder) continue;
    return true;
  }
  return false;
}

bool _resultsHaveDisplayableDecode(
  List<BuyerListingVinReportSourceResult> results,
) {
  for (final r in results) {
    if (buyerVinReportHasDisplayableSummary(r.normalizedSummary)) {
      return true;
    }
  }
  return false;
}

bool _resultsIndicatePendingProcessing(
  List<BuyerListingVinReportSourceResult> results,
) {
  for (final r in results) {
    final s = r.statusRaw?.trim().toLowerCase();
    if (s == 'pending' || s == 'processing') return true;
  }
  return false;
}

/// Resolves UI state from listing public VIN hint + buyer report lookup.
BuyerVinReportUiState resolveBuyerVinReportUiState({
  required ListingVinStatus listingVinStatus,
  BuyerListingVinReportLookupResult? lookup,
  bool loading = false,
  bool fetchFailed = false,
}) {
  if (listingVinStatus == ListingVinStatus.notProvided) {
    return BuyerVinReportUiState.noVin;
  }
  if (loading) return BuyerVinReportUiState.loading;

  if (fetchFailed) return BuyerVinReportUiState.unavailableOrError;

  final results = lookup?.results ?? const [];
  if (_resultsHaveDisplayableDecode(results)) {
    return BuyerVinReportUiState.reportAvailable;
  }
  if (_resultsIndicatePendingProcessing(results)) {
    return BuyerVinReportUiState.pendingOrNotReady;
  }
  return BuyerVinReportUiState.noPublicData;
}

/// Green Latin V/check badge only when public decode is available to show.
bool buyerVinReportShowsSuccessBadge(BuyerVinReportUiState state) =>
    state == BuyerVinReportUiState.reportAvailable;

/// Listing details CTA is tappable (opens sheet with explanation or report).
bool buyerVinReportCtaIsTappable(BuyerVinReportUiState state) =>
    state != BuyerVinReportUiState.noVin &&
    state != BuyerVinReportUiState.loading;
