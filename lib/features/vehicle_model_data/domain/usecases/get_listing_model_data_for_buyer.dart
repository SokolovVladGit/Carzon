import '../../../../core/utils/result.dart';
import '../entities/buyer_listing_model_data_source_result.dart';
import '../repositories/model_data_repository.dart';

class GetListingModelDataForBuyer {
  GetListingModelDataForBuyer(this._repository);
  final ModelDataRepository _repository;

  Future<Result<List<BuyerListingModelDataSourceResult>>> call(
    String listingId,
  ) => _repository.getListingModelDataForBuyer(listingId);
}
