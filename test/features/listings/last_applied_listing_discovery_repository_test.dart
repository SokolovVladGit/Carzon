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
    await repo.persistIfNeeded(const ListingDiscoveryCriteria());

    expect(await repo.load(), isNull);
  });

  test('load returns applied snapshot before disk write completes', () async {
    const next = ListingDiscoveryCriteria(make: 'Toyota');
    final pending = repo.persistIfNeeded(next);

    expect(await repo.load(), next);
    await pending;
    expect(await repo.load(), next);
  });

  test('rapid persist A then B leaves load and disk as B', () async {
    const a = ListingDiscoveryCriteria(make: 'Audi');
    const b = ListingDiscoveryCriteria(make: 'Toyota');
    final first = repo.persistIfNeeded(a);
    final second = repo.persistIfNeeded(b);

    expect(await repo.load(), b);
    await first;
    await second;
    expect(await repo.load(), b);

    final cold = SharedPreferencesLastAppliedListingDiscoveryRepository();
    expect(await cold.load(), b);
  });
}
