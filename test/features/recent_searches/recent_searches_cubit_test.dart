import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/recent_searches/domain/entities/recent_search_entry.dart';
import 'package:carzon/features/recent_searches/domain/repositories/recent_searches_repository.dart';
import 'package:carzon/features/recent_searches/presentation/cubit/recent_searches_cubit.dart';
import 'package:carzon/features/recent_searches/presentation/cubit/recent_searches_state.dart';
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

  setUp(() {
    repository = _MemoryRecentSearchesRepository();
    cubit = RecentSearchesCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('remove updates entries after persistence', () async {
    final entry = RecentSearchEntry(
      criteria: const ListingDiscoveryCriteria(search: 'bmw'),
      searchedAt: DateTime.utc(2026, 6, 1),
    );
    cubit.syncEntries([entry]);
    final ok = await cubit.remove(entry);
    expect(ok, isTrue);
    expect(cubit.state.entries, isEmpty);
  });

  test('clear empties entries', () async {
    cubit.syncEntries([
      RecentSearchEntry(
        criteria: const ListingDiscoveryCriteria(search: 'x'),
        searchedAt: DateTime.utc(2026, 6, 1),
      ),
    ]);
    final ok = await cubit.clear();
    expect(ok, isTrue);
    expect(cubit.state.status, RecentSearchesStatus.ready);
    expect(cubit.state.entries, isEmpty);
  });
}
