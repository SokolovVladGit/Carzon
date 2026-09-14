import '../../domain/entities/listing_engagement_event_type.dart';
import '../../domain/entities/listing_engagement_record_result.dart';

abstract class ListingEngagementRemoteDataSource {
  Future<ListingEngagementRecordResult> recordEvent({
    required String listingId,
    required ListingEngagementEventType eventType,
    required String anonymousViewerId,
  });
}
