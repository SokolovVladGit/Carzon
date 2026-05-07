import '../../../../core/utils/result.dart';
import '../entities/my_seller_profile.dart';
import '../repositories/sellers_repository.dart';

class UpdateMySellerDisplayName {
  UpdateMySellerDisplayName(this._repository);

  final SellersRepository _repository;

  /// Pass `null` or rely on trimmed empty at call site to clear `display_name`.
  Future<Result<MySellerProfile>> call(String? displayName) =>
      _repository.updateMySellerDisplayName(displayName);
}
