import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_image.dart';
import '../../domain/entities/edit_listing_input.dart';
import '../../domain/entities/owner_listing_vin_lookup_result.dart';
import '../../domain/entities/owner_listing_vin_report_status.dart';
import '../../domain/entities/owner_listing_vin_source_result.dart';
import '../../domain/repositories/edit_listing_repository.dart';
import '../datasources/edit_listing_remote_datasource.dart';

class EditListingRepositoryImpl implements EditListingRepository {
  EditListingRepositoryImpl(this._remote)
    : _logger = AppLogger('EditListingRepository');

  final EditListingRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<Listing>> fetchOwnerListingForEdit(String listingId) async {
    try {
      final listing = await _remote.fetchOwnerListingForEdit(listingId);
      return Success(listing);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('fetchOwnerListingForEdit unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load listing.'));
    }
  }

  @override
  Future<Result<List<ListingImage>>> fetchOwnerListingImagesForEdit(
    String listingId,
  ) async {
    try {
      final images = await _remote.fetchOwnerListingImagesForEdit(listingId);
      return Success(images);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('fetchOwnerListingImagesForEdit unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load listing images.'),
      );
    }
  }

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
  Future<Result<OwnerListingVinLookupResult>> fetchOwnerVin(
    String listingId,
  ) async {
    try {
      final result = await _remote.fetchOwnerListingVin(listingId);
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('fetchOwnerVin unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load listing VIN.'));
    }
  }

  @override
  Future<Result<OwnerListingVinReportLookupResult>> fetchOwnerVinReportStatus(
    String listingId,
  ) async {
    try {
      final result = await _remote.fetchOwnerListingVinReportStatus(listingId);
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('fetchOwnerVinReportStatus unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load VIN report status.'),
      );
    }
  }

  @override
  Future<Result<OwnerListingVinSourceResultsLookupResult>>
  fetchOwnerVinSourceResults(String listingId) async {
    try {
      final result = await _remote.fetchOwnerListingVinSourceResults(listingId);
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('fetchOwnerVinSourceResults unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load VIN source results.'),
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
