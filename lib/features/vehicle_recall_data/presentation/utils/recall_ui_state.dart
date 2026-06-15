import '../../domain/entities/buyer_listing_recall_source_result.dart';
import 'recall_formatters.dart';

/// Buyer-facing Recall section states on listing details.
enum RecallUiState { hidden, loading, visible, partial }

RecallUiState resolveRecallUiState({
  required bool loading,
  required bool fetchFailed,
  required BuyerListingRecallSourceResult? result,
}) {
  if (loading) return RecallUiState.loading;
  if (fetchFailed) return RecallUiState.hidden;
  if (result == null || !recallResultHasDisplayableCampaigns(result)) {
    return RecallUiState.hidden;
  }
  if (result.status?.trim().toLowerCase() == 'partial') {
    return RecallUiState.partial;
  }
  return RecallUiState.visible;
}
