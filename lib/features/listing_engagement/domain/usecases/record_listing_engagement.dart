import 'dart:async';

import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/repositories/anonymous_viewer_id_repository.dart';
import '../entities/listing_engagement_event_type.dart';
import '../entities/listing_engagement_record_result.dart';
import '../repositories/listing_engagement_repository.dart';

/// Records one engagement event. Product actions must not await this.
class RecordListingEngagement {
  RecordListingEngagement(this._repository, this._anonymousViewerIds)
    : _logger = AppLogger('RecordListingEngagement');

  final ListingEngagementRepository _repository;
  final AnonymousViewerIdRepository _anonymousViewerIds;
  final AppLogger _logger;

  Future<Result<ListingEngagementRecordResult>> call({
    required String listingId,
    required ListingEngagementEventType eventType,
  }) async {
    var anonymousViewerId = '';
    try {
      anonymousViewerId = await _anonymousViewerIds.getOrCreate();
    } catch (e, st) {
      _logger.error('anonymous viewer id failed', e, st);
    }
    return _repository.recordEvent(
      listingId: listingId,
      eventType: eventType,
      anonymousViewerId: anonymousViewerId,
    );
  }

  /// Best-effort: never throws to the caller, never retries.
  void recordFireAndForget({
    required String listingId,
    required ListingEngagementEventType eventType,
  }) {
    unawaited(_recordSafely(listingId: listingId, eventType: eventType));
  }

  Future<void> _recordSafely({
    required String listingId,
    required ListingEngagementEventType eventType,
  }) async {
    try {
      final result = await call(listingId: listingId, eventType: eventType);
      if (result is FailureResult<ListingEngagementRecordResult>) {
        _logger.warn(
          'engagement ${eventType.wireValue} failed for $listingId: '
          '${result.failure.message}',
        );
      }
    } catch (e, st) {
      _logger.error(
        'engagement ${eventType.wireValue} threw for $listingId',
        e,
        st,
      );
    }
  }
}
