import '../../../../core/utils/result.dart';
import '../entities/seller_public_profile.dart';
import '../repositories/sellers_repository.dart';

class GetSellerPublicProfile {
  GetSellerPublicProfile(this._repository);

  final SellersRepository _repository;

  Future<Result<SellerPublicProfile?>> call(String sellerId) =>
      _repository.getSellerPublicProfile(sellerId);
}
