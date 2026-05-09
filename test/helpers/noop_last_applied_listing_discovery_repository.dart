import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';

final class NoopLastAppliedListingDiscoveryRepository
    implements LastAppliedListingDiscoveryRepository {
  const NoopLastAppliedListingDiscoveryRepository();

  @override
  Future<ListingDiscoveryCriteria?> load() async => null;

  @override
  Future<void> persistIfNeeded(ListingDiscoveryCriteria snapshot) async {}
}
