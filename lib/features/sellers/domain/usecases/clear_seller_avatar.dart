import '../../../../core/utils/result.dart';
import '../entities/my_seller_profile.dart';
import '../repositories/sellers_repository.dart';

class ClearSellerAvatar {
  ClearSellerAvatar(this._repository);
  final SellersRepository _repository;

  Future<Result<MySellerProfile>> call({String? previousAvatarStoragePath}) =>
      _repository.clearSellerAvatar(
        previousAvatarStoragePath: previousAvatarStoragePath,
      );
}
