import 'dart:typed_data';

import '../../../../core/utils/result.dart';
import '../entities/my_seller_profile.dart';
import '../entities/seller_public_profile.dart';

abstract interface class SellersRepository {
  /// [Success] with `null` when the seller has no public-visible profile row.
  Future<Result<SellerPublicProfile?>> getSellerPublicProfile(String sellerId);

  /// Authenticated: load own editable seller row for account UI.
  Future<Result<MySellerProfile>> getMySellerProfile();

  /// Authenticated: persist trimmed display name; `null` clears to backend null.
  Future<Result<MySellerProfile>> updateMySellerDisplayName(
    String? displayName,
  );

  /// Upload new avatar to Storage, persist RPC row; optional cleanup of prior path.
  Future<Result<MySellerProfile>> uploadSellerAvatar({
    required Uint8List bytes,
    required String contentType,
    String? previousAvatarStoragePath,
  });

  /// Clear avatar in DB; optional best-effort Storage delete for [previousAvatarStoragePath].
  Future<Result<MySellerProfile>> clearSellerAvatar({
    String? previousAvatarStoragePath,
  });
}
