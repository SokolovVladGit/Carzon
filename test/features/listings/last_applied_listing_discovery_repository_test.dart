import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesLastAppliedListingDiscoveryRepository repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = SharedPreferencesLastAppliedListingDiscoveryRepository();
  });

  test('persist + load restores criteria snapshot', () async {
    const criteria = ListingDiscoveryCriteria(
      make: 'Audi',
      marketRegion: MarketRegion.moldova,
    );
    await repo.persistIfNeeded(criteria);

    expect(await repo.load(), criteria);
  });

  test('cleared-feed snapshot removes stored prefs', () async {
    await repo.persistIfNeeded(
      const ListingDiscoveryCriteria(marketRegion: MarketRegion.moldova),
    );
    await repo.persistIfNeeded(
      const ListingDiscoveryCriteria(marketRegion: MarketRegion.transnistria),
    );

    expect(await repo.load(), isNull);
  });
}
