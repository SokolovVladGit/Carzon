import '../../../../core/utils/result.dart';
import '../entities/seller_listing_defaults.dart';

abstract interface class SellerListingDefaultsRepository {
  Future<Result<SellerListingDefaults>> getMyListingDefaults();

  Future<Result<SellerListingDefaults>> saveMyListingDefaults(
    SellerListingDefaults defaults,
  );
}
