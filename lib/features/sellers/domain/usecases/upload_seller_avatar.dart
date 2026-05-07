import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/my_seller_profile.dart';
import '../repositories/sellers_repository.dart';

class UploadSellerAvatar {
  UploadSellerAvatar(this._repository);
  final SellersRepository _repository;

  Future<Result<MySellerProfile>> call({
    required Uint8List bytes,
    required String contentType,
    String? previousAvatarStoragePath,
  }) => _repository.uploadSellerAvatar(
    bytes: bytes,
    contentType: contentType,
    previousAvatarStoragePath: previousAvatarStoragePath,
  );
}
