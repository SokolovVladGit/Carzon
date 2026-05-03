import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/log_redaction.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/constants/listing_gallery_limits.dart';
import '../../domain/entities/cover_image_upload.dart';
import '../../domain/entities/uploaded_listing_image.dart';
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
      _logger.debug(
        'upload_cover server error '
        'code=${e.postgrestCode ?? '-'} '
        'details=${redactLikelyDigitsInLogs(e.diagnosticsDetails ?? '-')} '
        'message=${redactLikelyDigitsInLogs(e.message)}',
      );
      return FailureResult(
        ServerFailure(e.message, diagnosticsDetails: e.diagnosticsDetails),
      );
    } catch (e, st) {
      _logger.error('uploadCover unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to upload cover image.'),
      );
    }
  }

  @override
  Future<Result<List<UploadedListingImage>>> uploadSequential(
    List<CoverImageUpload> uploads,
  ) async {
    if (uploads.isEmpty) {
      return const Success(<UploadedListingImage>[]);
    }
    if (uploads.length > kMaxListingPhotos) {
      _logger.debug('uploadSequential rejected: too many uploads');
      return const FailureResult(UnknownFailure('Too many images.'));
    }
    final out = <UploadedListingImage>[];
    for (final upload in uploads) {
      final step = await uploadCover(upload);
      switch (step) {
        case FailureResult(:final failure):
          return FailureResult(failure);
        case Success(:final value):
          final storagePath =
              SupabaseCreateListingImageRemoteDataSource.extractStoragePathFromPublicUrl(
                value,
              );
          out.add(
            UploadedListingImage(publicUrl: value, storagePath: storagePath),
          );
      }
    }
    return Success(out);
  }

  @override
  Future<Result<void>> deleteByPublicUrl({
    required String publicUrl,
    required String sellerId,
  }) async {
    try {
      await _remote.deleteByPublicUrl(publicUrl: publicUrl, sellerId: sellerId);
    } catch (e, st) {
      // Datasource is documented as non-throwing, but be defensive —
      // a best-effort cleanup must never flip a successful cover
      // update into a user-visible failure.
      _logger.error('deleteByPublicUrl best-effort cleanup failed', e, st);
    }
    return const Success(null);
  }

  @override
  Future<Result<void>> deleteUploadedBatchBestEffort({
    required List<UploadedListingImage> images,
    required String sellerId,
  }) async {
    for (final img in images) {
      await deleteByPublicUrl(publicUrl: img.publicUrl, sellerId: sellerId);
    }
    return const Success(null);
  }
}
