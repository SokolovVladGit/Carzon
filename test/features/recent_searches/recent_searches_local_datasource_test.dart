import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/recent_searches/data/datasources/recent_searches_local_datasource.dart';
import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferencesRecentSearchesLocalDataSource ds;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesRecentSearchesLocalDataSource.storageKey: '{not json',
    });
    ds = SharedPreferencesRecentSearchesLocalDataSource();
  });

  test('malformed JSON returns empty list', () async {
    expect(await ds.loadEntries(), isEmpty);
  });

  test('missing key returns empty list', () async {
    SharedPreferences.setMockInitialValues({});
    expect(await ds.loadEntries(), isEmpty);
  });

  test('clear removes storage key', () async {
    SharedPreferences.setMockInitialValues({});
    await ds.saveEntries(const []);
    await ds.clear();
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.containsKey(
        SharedPreferencesRecentSearchesLocalDataSource.storageKey,
      ),
      isFalse,
    );
  });

  test('round-trips drivetrain in stored criteria JSON', () async {
    SharedPreferences.setMockInitialValues({});
    const criteria = ListingDiscoveryCriteria(
      drivetrain: ListingDrivetrain.fourWheel,
      make: 'Subaru',
    );
    final entry = RecentSearchEntry(
      criteria: criteria,
      searchedAt: DateTime.utc(2026, 3, 1),
    );
    await ds.saveEntries([entry]);
    final loaded = await ds.loadEntries();
    expect(loaded, hasLength(1));
    expect(loaded.single.criteria.drivetrain, ListingDrivetrain.fourWheel);
    expect(loaded.single.criteria.make, 'Subaru');
    final raw = await SharedPreferences.getInstance();
    final stored = raw.getString(
      SharedPreferencesRecentSearchesLocalDataSource.storageKey,
    );
    expect(stored, contains('"drivetrain":"four_wheel"'));
  });
}
