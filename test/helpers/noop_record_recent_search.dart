import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/recent_searches/domain/usecases/record_recent_search.dart';

/// Test/no-op [RecordRecentSearch] that never persists.
final class NoopRecordRecentSearch implements RecordRecentSearch {
  NoopRecordRecentSearch();

  ListingDiscoveryCriteria? lastRecorded;

  @override
  Future<void> call(
    ListingDiscoveryCriteria criteria, {
    DateTime? searchedAt,
  }) async {
    lastRecorded = criteria;
  }
}
