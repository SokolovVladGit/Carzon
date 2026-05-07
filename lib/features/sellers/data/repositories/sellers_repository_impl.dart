import 'dart:typed_data';

import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/my_seller_profile.dart';
import '../../domain/entities/seller_public_profile.dart';
import '../../domain/repositories/sellers_repository.dart';
import '../datasources/seller_avatar_remote_datasource.dart';
import '../datasources/sellers_remote_datasource.dart';

class SellersRepositoryImpl implements SellersRepository {
  SellersRepositoryImpl(this._remote, this._avatarStorage)
    : _logger = AppLogger('SellersRepository');

  final SellersRemoteDataSource _remote;
  final SellerAvatarRemoteDataSource _avatarStorage;
  final AppLogger _logger;

  static const _unsupportedMarker = 'seller_avatar_unsupported_format';

  @override
  Future<Result<SellerPublicProfile?>> getSellerPublicProfile(
    String sellerId,
  ) async {
    try {
      final profile = await _remote.fetchPublicProfile(sellerId);
      return Success(profile);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getSellerPublicProfile unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load seller profile.'),
      );
    }
  }

  @override
  Future<Result<MySellerProfile>> getMySellerProfile() async {
    try {
      final row = await _remote.fetchMySellerProfile();
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getMySellerProfile unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load seller profile settings.'),
      );
    }
  }

  @override
  Future<Result<MySellerProfile>> updateMySellerDisplayName(
    String? displayName,
  ) async {
    try {
      final row = await _remote.updateMySellerDisplayName(displayName);
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('updateMySellerDisplayName unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to update public seller name.'),
      );
    }
  }

  @override
  Future<Result<MySellerProfile>> uploadSellerAvatar({
    required Uint8List bytes,
    required String contentType,
    String? previousAvatarStoragePath,
  }) async {
    SellerAvatarUploadPayload? staged;
    try {
      staged = await _avatarStorage.uploadAvatar(
        bytes: bytes,
        contentType: contentType,
      );
    } on ServerException catch (e) {
      if (e.message == _unsupportedMarker) {
        return const FailureResult(SellerAvatarUnsupportedFormat());
      }
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('uploadSellerAvatar staging error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to upload public seller photo.'),
      );
    }

    try {
      final row = await _remote.updateMySellerAvatar(
        avatarPath: staged.storagePath,
        avatarUrl: staged.publicUrl,
      );
      await _avatarStorage.deleteByStoragePathBestEffort(
        previousAvatarStoragePath,
      );
      return Success(row);
    } on ServerException catch (e) {
      await _avatarStorage.deleteByStoragePathBestEffort(staged.storagePath);
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('uploadSellerAvatar RPC error', e, st);
      await _avatarStorage.deleteByStoragePathBestEffort(staged.storagePath);
      return const FailureResult(
        UnknownFailure('Failed to save public seller photo.'),
      );
    }
  }

  @override
  Future<Result<MySellerProfile>> clearSellerAvatar({
    String? previousAvatarStoragePath,
  }) async {
    try {
      final row = await _remote.clearMySellerAvatar();
      await _avatarStorage.deleteByStoragePathBestEffort(
        previousAvatarStoragePath,
      );
      return Success(row);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('clearSellerAvatar unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to remove public seller photo.'),
      );
    }
  }
}
