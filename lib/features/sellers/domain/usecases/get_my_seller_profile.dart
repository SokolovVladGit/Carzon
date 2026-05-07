import '../../../../core/utils/result.dart';
import '../entities/my_seller_profile.dart';
import '../repositories/sellers_repository.dart';

class GetMySellerProfile {
  GetMySellerProfile(this._repository);

  final SellersRepository _repository;

  Future<Result<MySellerProfile>> call() => _repository.getMySellerProfile();
}
