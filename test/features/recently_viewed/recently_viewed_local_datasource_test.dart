import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/recently_viewed/data/datasources/recently_viewed_local_datasource.dart';
import 'package:carzon/features/recently_viewed/domain/entities/recently_viewed_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

RecentlyViewedEntry _entry(
  String id, {
  DateTime? viewedAt,
  String title = 'Skoda Octavia',
}) {
  return RecentlyViewedEntry(
    listingId: id,
    viewedAt: viewedAt ?? DateTime.utc(2026, 6, 1, 12),
    title: title,
    make: 'Skoda',
    model: 'Octavia',
    year: 2017,
    priceEur: 10800,
    priceCurrency: ListingCurrency.eur,
    city: 'Tiraspol',
    marketRegion: MarketRegion.transnistria,
    coverImageUrl: 'https://cdn.example/cover.jpg',
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesRecentlyViewedLocalDataSource datasource;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    datasource = SharedPreferencesRecentlyViewedLocalDataSource();
  });

  test('missing key returns empty list', () async {
    expect(await datasource.loadEntries(), isEmpty);
  });

  test('save and load round trip preserves order and fields', () async {
    final entries = [
      _entry('a', viewedAt: DateTime.utc(2026, 6, 3)),
      _entry('b', viewedAt: DateTime.utc(2026, 6, 2)),
    ];
    await datasource.saveEntries(entries);
    final loaded = await datasource.loadEntries();
    expect(loaded.map((e) => e.listingId), ['a', 'b']);
    expect(loaded.first.title, 'Skoda Octavia');
    expect(loaded.first.priceCurrency, ListingCurrency.eur);
  });

  test('malformed JSON returns empty list safely', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesRecentlyViewedLocalDataSource.storageKey: '{bad-json',
    });
    datasource = SharedPreferencesRecentlyViewedLocalDataSource();
    expect(await datasource.loadEntries(), isEmpty);
  });

  test('clear removes persisted data', () async {
    await datasource.saveEntries([_entry('x')]);
    await datasource.clear();
    expect(await datasource.loadEntries(), isEmpty);
  });

  test('serialized JSON excludes seller contact and VIN fields', () async {
    await datasource.saveEntries([
      _entry('listing-1', title: 'Public title only'),
    ]);
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(
      SharedPreferencesRecentlyViewedLocalDataSource.storageKey,
    );
    expect(raw, isNotNull);
    expect(raw!, isNot(contains('seller')));
    expect(raw, isNot(contains('telegram')));
    expect(raw, isNot(contains('phone')));
    expect(raw, isNot(contains('vin')));
    expect(raw, contains('Public title only'));
  });
}
