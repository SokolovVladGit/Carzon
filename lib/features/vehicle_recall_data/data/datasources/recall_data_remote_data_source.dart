import '../../domain/entities/buyer_listing_recall_source_result.dart';

abstract class RecallDataRemoteDataSource {
  Future<BuyerListingRecallSourceResult> fetchListingRecallsForBuyer(
    String listingId,
  );
}
