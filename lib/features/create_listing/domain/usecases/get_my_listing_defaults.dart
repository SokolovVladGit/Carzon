import '../../../../core/utils/result.dart';
import '../entities/seller_listing_defaults.dart';
import '../repositories/seller_listing_defaults_repository.dart';

class GetMyListingDefaults {
  GetMyListingDefaults(this._repository);

  final SellerListingDefaultsRepository _repository;

  Future<Result<SellerListingDefaults>> call() =>
      _repository.getMyListingDefaults();
}
