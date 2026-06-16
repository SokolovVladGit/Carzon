import '../../domain/entities/buyer_listing_model_data_source_result.dart';
import 'model_passport_formatters.dart';

/// Buyer-facing Model Passport section states on listing details.
enum ModelPassportUiState {
  hidden,
  loading,
  pendingOrNotReady,
  available,
  partial,
}

const String kModelPassportEpaSourceId = 'epa_fueleconomy';

bool _isPendingStatus(String? status) {
  final s = status?.trim().toLowerCase();
  return s == 'pending' || s == 'processing' || s == 'queued';
}

/// Selects an EPA row that signals async fetch is still in progress.
BuyerListingModelDataSourceResult? selectModelPassportPendingEpaRow(
  List<BuyerListingModelDataSourceResult> rows,
) {
  for (final row in rows) {
    if (row.sourceId != kModelPassportEpaSourceId) continue;
    if (_isPendingStatus(row.status)) return row;
  }
  return null;
}

/// Selects the first displayable EPA row for listing details.
BuyerListingModelDataSourceResult? selectModelPassportEpaRow(
  List<BuyerListingModelDataSourceResult> rows,
) {
  for (final row in rows) {
    if (row.sourceId != kModelPassportEpaSourceId) continue;
    final status = row.status?.trim().toLowerCase();
    if (status != 'succeeded' && status != 'partial') continue;
    if (!modelPassportSummaryHasDisplayableFields(row.normalizedSummary)) {
      continue;
    }
    return row;
  }
  return null;
}

ModelPassportUiState resolveModelPassportUiState({
  required bool loading,
  required bool fetchFailed,
  required List<BuyerListingModelDataSourceResult> rows,
}) {
  if (loading) return ModelPassportUiState.loading;
  if (fetchFailed) return ModelPassportUiState.hidden;

  if (selectModelPassportPendingEpaRow(rows) != null) {
    return ModelPassportUiState.pendingOrNotReady;
  }

  final row = selectModelPassportEpaRow(rows);
  if (row == null) return ModelPassportUiState.hidden;

  if (row.status?.trim().toLowerCase() == 'partial') {
    return ModelPassportUiState.partial;
  }
  return ModelPassportUiState.available;
}
