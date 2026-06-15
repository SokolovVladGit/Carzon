import '../../domain/entities/buyer_listing_model_data_source_result.dart';

abstract class ModelDataRemoteDataSource {
  Future<List<BuyerListingModelDataSourceResult>> fetchListingModelDataForBuyer(
    String listingId,
  );
}
