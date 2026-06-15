import '../../../../core/utils/result.dart';
import '../entities/buyer_listing_model_data_source_result.dart';

abstract class ModelDataRepository {
  Future<Result<List<BuyerListingModelDataSourceResult>>>
  getListingModelDataForBuyer(String listingId);
}
