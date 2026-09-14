import '../../../../core/utils/result.dart';
import '../entities/my_seller_context.dart';
import '../entities/seller_type.dart';
import '../repositories/sellers_repository.dart';

class SetMySellerType {
  SetMySellerType(this._repository);

  final SellersRepository _repository;

  Future<Result<MySellerContext>> call(SellerType sellerType) =>
      _repository.setMySellerType(sellerType);
}
