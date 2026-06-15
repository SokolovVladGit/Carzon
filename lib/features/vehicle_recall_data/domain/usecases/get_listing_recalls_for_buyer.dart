import '../../../../core/utils/result.dart';
import '../entities/buyer_listing_recall_source_result.dart';
import '../repositories/recall_data_repository.dart';

class GetListingRecallsForBuyer {
  GetListingRecallsForBuyer(this._repository);

  final RecallDataRepository _repository;

  Future<Result<BuyerListingRecallSourceResult>> call(String listingId) =>
      _repository.getListingRecallsForBuyer(listingId);
}
