import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/recently_viewed/data/datasources/recently_viewed_local_datasource.dart';
import 'package:carzon/features/recently_viewed/data/repositories/recently_viewed_repository_impl.dart';
import 'package:carzon/features/recently_viewed/domain/entities/recently_viewed_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

RecentlyViewedEntry _entry(String id, {DateTime? viewedAt}) {
  return RecentlyViewedEntry(
    listingId: id,
    viewedAt: viewedAt ?? DateTime.utc(2026, 6, 1),
    title: 'Listing $id',
    make: 'VW',
    model: 'Golf',
    year: 2016,
    priceEur: 8900,
    priceCurrency: ListingCurrency.eur,
    city: 'Chișinău',
    marketRegion: MarketRegion.moldova,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecentlyViewedRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = RecentlyViewedRepositoryImpl(
      SharedPreferencesRecentlyViewedLocalDataSource(),
    );
  });

  test('record promotes duplicate to top and refreshes entry', () async {
    await repo.record(_entry('a', viewedAt: DateTime.utc(2026, 6, 1)));
    await repo.record(_entry('b', viewedAt: DateTime.utc(2026, 6, 2)));
    final updated = await repo.record(
      _entry('a', viewedAt: DateTime.utc(2026, 6, 3)),
    );

    expect(updated.map((e) => e.listingId), ['a', 'b']);
    expect(updated.first.viewedAt, DateTime.utc(2026, 6, 3));
  });

  test('record caps list at 30 entries', () async {
    for (var i = 0; i < 31; i++) {
      await repo.record(_entry('id-$i'));
    }
    final loaded = await repo.load();
    expect(loaded.length, 30);
    expect(loaded.first.listingId, 'id-30');
    expect(loaded.last.listingId, 'id-1');
  });

  test('clear removes all entries', () async {
    await repo.record(_entry('x'));
    await repo.clear();
    expect(await repo.load(), isEmpty);
  });
}
