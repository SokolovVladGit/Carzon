import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/recent_searches/data/datasources/recent_searches_local_datasource.dart';
import 'package:carzon/features/recent_searches/data/repositories/recent_searches_repository_impl.dart';
import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

RecentSearchEntry _entry(
  String token, {
  String? search,
  ListingSortOption sort = ListingSortOption.newestFirst,
  DateTime? searchedAt,
}) {
  return RecentSearchEntry(
    criteria: ListingDiscoveryCriteria(search: search ?? token, sort: sort),
    searchedAt: searchedAt ?? DateTime.utc(2026, 6, 1),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late RecentSearchesRepositoryImpl repo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = RecentSearchesRepositoryImpl(
      SharedPreferencesRecentSearchesLocalDataSource(),
    );
  });

  test('record dedupes ignoring sort and promotes to top', () async {
    await repo.record(_entry('a', sort: ListingSortOption.newestFirst));
    await repo.record(_entry('b'));
    final updated = await repo.record(
      _entry(
        'a',
        sort: ListingSortOption.priceLowToHigh,
        searchedAt: DateTime.utc(2026, 6, 3),
      ),
    );

    expect(updated.length, 2);
    expect(updated.first.criteria.search, 'a');
    expect(updated.first.criteria.sort, ListingSortOption.priceLowToHigh);
    expect(updated.first.searchedAt, DateTime.utc(2026, 6, 3));
    expect(updated.last.criteria.search, 'b');
  });

  test('record caps list at 8 entries', () async {
    for (var i = 0; i < 9; i++) {
      await repo.record(_entry('token-$i'));
    }
    final loaded = await repo.load();
    expect(loaded.length, RecentSearchesRepositoryImpl.maxEntries);
    expect(loaded.first.criteria.search, 'token-8');
    expect(loaded.last.criteria.search, 'token-1');
  });

  test('remove deletes matching criteria', () async {
    final a = _entry('alpha');
    final b = _entry('beta');
    await repo.record(a);
    await repo.record(b);
    final updated = await repo.remove(a);
    expect(updated.length, 1);
    expect(updated.single.criteria.search, 'beta');
  });

  test('clear removes all entries', () async {
    await repo.record(_entry('x'));
    await repo.clear();
    expect(await repo.load(), isEmpty);
  });
}
