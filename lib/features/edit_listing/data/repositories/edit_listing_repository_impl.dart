import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../../domain/repositories/edit_listing_repository.dart';
import '../datasources/edit_listing_remote_datasource.dart';

class EditListingRepositoryImpl implements EditListingRepository {
  EditListingRepositoryImpl(this._remote)
    : _logger = AppLogger('EditListingRepository');

  final EditListingRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<Listing>> updateDetails(EditListingInput input) async {
    try {
      final listing = await _remote.updateDetails(input);
      return Success(listing);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('updateDetails unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to update listing.'));
    }
  }

  @override
  Future<Result<Listing>> updateDetailsV2(EditListingInput input) async {
    try {
      final listing = await _remote.updateDetailsV2(input);
      return Success(listing);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('updateDetailsV2 unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to update listing.'));
    }
  }

  @override
  Future<Result<Listing>> replaceListingImages({
    required String listingId,
    required List<String> imagePublicUrls,
    List<String?>? storagePaths,
  }) async {
    try {
      final listing = await _remote.replaceListingImages(
        listingId: listingId,
        imagePublicUrls: imagePublicUrls,
        storagePaths: storagePaths,
      );
      return Success(listing);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('replaceListingImages unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to replace listing images.'),
      );
    }
  }

  @override
  Future<Result<Listing>> updateCoverImage({
    required String listingId,
    required String? coverImageUrl,
  }) async {
    try {
      final listing = await _remote.updateCoverImage(
        listingId: listingId,
        coverImageUrl: coverImageUrl,
      );
      return Success(listing);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('updateCoverImage unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to update cover image.'),
      );
    }
  }
}
