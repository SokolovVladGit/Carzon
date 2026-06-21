import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:carzon/features/recent_searches/domain/repositories/recent_searches_repository.dart';
import 'package:carzon/features/recent_searches/domain/usecases/record_recent_search.dart';
import 'package:carzon/features/recent_searches/presentation/cubit/recent_searches_cubit.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRecentSearchesRepository implements RecentSearchesRepository {
  List<RecentSearchEntry> stored = const [];

  @override
  Future<void> clear() async {
    stored = const [];
  }

  @override
  Future<List<RecentSearchEntry>> load() async =>
      List<RecentSearchEntry>.from(stored);

  @override
  Future<List<RecentSearchEntry>> record(RecentSearchEntry entry) async {
    stored = [entry, ...stored];
    return List<RecentSearchEntry>.from(stored);
  }

  @override
  Future<List<RecentSearchEntry>> remove(RecentSearchEntry entry) async {
    stored = stored
        .where((e) => e.criteria.search != entry.criteria.search)
        .toList(growable: false);
    return List<RecentSearchEntry>.from(stored);
  }
}

void main() {
  late _MemoryRecentSearchesRepository repository;
  late RecentSearchesCubit cubit;
  late RecordRecentSearch recordRecentSearch;

  setUp(() {
    repository = _MemoryRecentSearchesRepository();
    cubit = RecentSearchesCubit(repository: repository);
    recordRecentSearch = RecordRecentSearch(repository, cubit);
  });

  tearDown(() => cubit.close());

  test('ignores default feed criteria', () async {
    await recordRecentSearch(const ListingDiscoveryCriteria());
    expect(repository.stored, isEmpty);
    expect(cubit.state.entries, isEmpty);
  });

  test('ignores sort-only criteria', () async {
    await recordRecentSearch(
      const ListingDiscoveryCriteria(sort: ListingSortOption.priceLowToHigh),
    );
    expect(repository.stored, isEmpty);
  });

  test('records meaningful search criteria', () async {
    await recordRecentSearch(const ListingDiscoveryCriteria(search: 'octavia'));
    expect(repository.stored.length, 1);
    expect(cubit.state.entries.length, 1);
    expect(cubit.state.entries.first.criteria.search, 'octavia');
  });
}
