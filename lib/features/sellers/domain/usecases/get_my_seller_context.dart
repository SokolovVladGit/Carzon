import '../../../../core/utils/result.dart';
import '../entities/my_seller_context.dart';
import '../repositories/sellers_repository.dart';

class GetMySellerContext {
  GetMySellerContext(this._repository);

  final SellersRepository _repository;

  Future<Result<MySellerContext>> call() => _repository.getMySellerContext();
}
