import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/repositories/create_listing_repository.dart';
import '../datasources/create_listing_image_remote_datasource.dart';

class ListingImageRepositoryImpl implements ListingImageRepository {
  ListingImageRepositoryImpl(this._remote)
      : _logger = AppLogger('ListingImageRepository');

  final CreateListingImageRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<String>> uploadCover(CoverImageUpload upload) async {
    try {
      final url = await _remote.uploadCover(upload);
      return Success(url);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('uploadCover unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to upload cover image.'));
    }
  }

  @override
  Future<Result<void>> deleteByPublicUrl({
    required String publicUrl,
    required String sellerId,
  }) async {
    try {
      await _remote.deleteByPublicUrl(
        publicUrl: publicUrl,
        sellerId: sellerId,
      );
    } catch (e, st) {
      // Datasource is documented as non-throwing, but be defensive —
      // a best-effort cleanup must never flip a successful cover
      // update into a user-visible failure.
      _logger.error('deleteByPublicUrl best-effort cleanup failed', e, st);
    }
    return const Success(null);
  }
}
