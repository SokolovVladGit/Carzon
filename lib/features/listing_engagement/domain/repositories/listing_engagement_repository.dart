import '../../../../core/utils/result.dart';
import '../entities/listing_engagement_event_type.dart';
import '../entities/listing_engagement_record_result.dart';

abstract class ListingEngagementRepository {
  Future<Result<ListingEngagementRecordResult>> recordEvent({
    required String listingId,
    required ListingEngagementEventType eventType,
    required String anonymousViewerId,
  });
}
