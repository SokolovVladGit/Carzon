import '../../domain/entities/buyer_listing_recall_source_result.dart';
import 'recall_formatters.dart';

/// Buyer-facing Recall section states on listing details.
enum RecallUiState { hidden, loading, pendingOrNotReady, visible, partial }

bool _recallResultIndicatesPending(BuyerListingRecallSourceResult? result) {
  if (result == null) return false;
  final status = result.status?.trim().toLowerCase();
  if (status != 'pending' && status != 'processing' && status != 'queued') {
    return false;
  }
  return !recallResultHasDisplayableCampaigns(result);
}

RecallUiState resolveRecallUiState({
  required bool loading,
  required bool fetchFailed,
  required BuyerListingRecallSourceResult? result,
}) {
  if (loading) return RecallUiState.loading;
  if (fetchFailed) return RecallUiState.hidden;
  if (_recallResultIndicatesPending(result)) {
    return RecallUiState.pendingOrNotReady;
  }
  if (result == null || !recallResultHasDisplayableCampaigns(result)) {
    return RecallUiState.hidden;
  }
  if (result.status?.trim().toLowerCase() == 'partial') {
    return RecallUiState.partial;
  }
  return RecallUiState.visible;
}
