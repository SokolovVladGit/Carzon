import '../../../../core/utils/result.dart';
import '../entities/buyer_listing_recall_source_result.dart';

abstract class RecallDataRepository {
  Future<Result<BuyerListingRecallSourceResult>> getListingRecallsForBuyer(
    String listingId,
  );
}
