import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/recent_searches/data/datasources/recent_searches_local_datasource.dart';
import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('RecentSearchEntry JSON round trip via datasource', () async {
    SharedPreferences.setMockInitialValues({});
    final ds = SharedPreferencesRecentSearchesLocalDataSource();
    final criteria = ListingDiscoveryCriteria(
      search: 'golf',
      make: 'Volkswagen',
      model: 'Golf',
      sort: ListingSortOption.priceLowToHigh,
    );
    final entry = RecentSearchEntry(
      criteria: criteria,
      searchedAt: DateTime.utc(2026, 6, 21, 12, 30),
    );

    await ds.saveEntries([entry]);
    final loaded = await ds.loadEntries();

    expect(loaded.length, 1);
    expect(loaded.first.searchedAt, DateTime.utc(2026, 6, 21, 12, 30));
    expect(loaded.first.criteria.search, 'golf');
    expect(loaded.first.criteria.make, 'Volkswagen');
    expect(loaded.first.criteria.sort, ListingSortOption.priceLowToHigh);
  });
}
