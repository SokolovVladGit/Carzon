import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/vehicle_model_data/domain/entities/buyer_listing_model_data_source_result.dart';
import 'package:carzon/features/vehicle_model_data/domain/repositories/model_data_repository.dart';
import 'package:carzon/features/vehicle_model_data/domain/usecases/get_listing_model_data_for_buyer.dart';
import 'package:carzon/features/vehicle_recall_data/domain/entities/buyer_listing_recall_source_result.dart';
import 'package:carzon/features/vehicle_recall_data/domain/repositories/recall_data_repository.dart';
import 'package:carzon/features/vehicle_recall_data/domain/usecases/get_listing_recalls_for_buyer.dart';
import 'package:get_it/get_it.dart';

class _EmptyModelDataRepository implements ModelDataRepository {
  @override
  Future<Result<List<BuyerListingModelDataSourceResult>>>
  getListingModelDataForBuyer(String listingId) async => const Success([]);
}

class _EmptyRecallRepository implements RecallDataRepository {
  @override
  Future<Result<BuyerListingRecallSourceResult>> getListingRecallsForBuyer(
    String listingId,
  ) async =>
      const Success(BuyerListingRecallSourceResult.empty);
}

/// Stubs for listing-details sections that self-fetch via GetIt.
void registerListingDetailsSelfFetchStubs(GetIt getIt) {
  getIt.registerFactory<GetListingModelDataForBuyer>(
    () => GetListingModelDataForBuyer(_EmptyModelDataRepository()),
  );
  getIt.registerFactory<GetListingRecallsForBuyer>(
    () => GetListingRecallsForBuyer(_EmptyRecallRepository()),
  );
}
