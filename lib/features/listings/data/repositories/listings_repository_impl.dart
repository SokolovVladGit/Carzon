import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/buyer_listing_vin_report_source_result.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_contact.dart';
import '../../domain/entities/listing_image.dart';
import '../../domain/entities/listing_report_reason.dart';
import '../../domain/entities/listing_view_stats.dart';
import '../../domain/repositories/listings_repository.dart';
import '../datasources/listings_remote_datasource.dart';

class ListingsRepositoryImpl implements ListingsRepository {
  ListingsRepositoryImpl(this._remote)
    : _logger = AppLogger('ListingsRepository');

  final ListingsRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<List<Listing>>> getListings(ListingsQuery query) async {
    try {
      final list = await _remote.fetch(query);
      return Success(list);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getListings unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load listings.'));
    }
  }

  @override
  Future<Result<Listing>> getById(String id) async {
    try {
      final item = await _remote.fetchById(id);
      return Success(item);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getById unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load listing.'));
    }
  }

  @override
  Future<Result<Listing>> updateStatus(String id, ListingStatus status) async {
    try {
      final item = await _remote.updateStatus(id, status.name);
      return Success(item);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('updateStatus unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to update listing status.'),
      );
    }
  }

  @override
  Future<Result<void>> deleteListing(String id) async {
    try {
      await _remote.deleteListing(id);
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('deleteListing unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to delete listing.'));
    }
  }

  @override
  Future<Result<void>> reportListing({
    required String listingId,
    required ListingReportReason reason,
    String? note,
  }) async {
    try {
      final normalizedNote = note?.trim();
      await _remote.reportListing(
        listingId: listingId,
        reason: reason.toDbValue(),
        note: normalizedNote == null || normalizedNote.isEmpty
            ? null
            : normalizedNote,
      );
      return const Success(null);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('reportListing unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to submit listing report.'),
      );
    }
  }

  @override
  Future<Result<List<ListingImage>>> getListingImages(String listingId) async {
    try {
      final images = await _remote.fetchListingImages(listingId);
      return Success(images);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getListingImages unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load listing images.'),
      );
    }
  }

  @override
  Future<Result<ListingContact>> getPublicContact(String listingId) async {
    try {
      final contact = await _remote.fetchPublicContact(listingId);
      return Success(contact);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getPublicContact unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load seller contact.'),
      );
    }
  }

  @override
  Future<Result<BuyerListingVinReportLookupResult>> fetchBuyerVinReportSources(
    String listingId,
  ) async {
    try {
      final r = await _remote.fetchBuyerListingVinReportSources(listingId);
      return Success(r);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('fetchBuyerVinReportSources unknown error', e, st);
      return const Success(
        BuyerListingVinReportLookupResult(fetchFailed: true),
      );
    }
  }

  @override
  Future<Result<ListingViewStats>> recordListingView(
    String listingId,
    String anonymousViewerId,
  ) async {
    try {
      final stats = await _remote.recordListingView(
        listingId,
        anonymousViewerId,
      );
      return Success(stats);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('recordListingView unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to record listing view.'),
      );
    }
  }
}
