import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/listing_engagement_event_type.dart';
import '../../domain/entities/listing_engagement_record_result.dart';
import '../../domain/repositories/listing_engagement_repository.dart';
import '../datasources/listing_engagement_remote_datasource.dart';

class ListingEngagementRepositoryImpl implements ListingEngagementRepository {
  ListingEngagementRepositoryImpl(this._remote)
    : _logger = AppLogger('ListingEngagementRepository');

  final ListingEngagementRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<ListingEngagementRecordResult>> recordEvent({
    required String listingId,
    required ListingEngagementEventType eventType,
    required String anonymousViewerId,
  }) async {
    try {
      final result = await _remote.recordEvent(
        listingId: listingId,
        eventType: eventType,
        anonymousViewerId: anonymousViewerId,
      );
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('recordEvent unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to record listing engagement.'),
      );
    }
  }
}
