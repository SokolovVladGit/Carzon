import '../../../listings/domain/filter_alert_catalog_criteria_compare.dart';
import '../../domain/entities/recent_search_entry.dart';
import '../../domain/repositories/recent_searches_repository.dart';
import '../datasources/recent_searches_local_datasource.dart';

final class RecentSearchesRepositoryImpl implements RecentSearchesRepository {
  RecentSearchesRepositoryImpl(this._local);

  static const int maxEntries = 8;

  final RecentSearchesLocalDataSource _local;

  @override
  Future<List<RecentSearchEntry>> load() => _local.loadEntries();

  @override
  Future<List<RecentSearchEntry>> record(RecentSearchEntry entry) async {
    final existing = await _local.loadEntries();
    final withoutDuplicate = existing
        .where(
          (e) => !listingDiscoveryCriteriaEqualIgnoringSort(
            e.criteria,
            entry.criteria,
          ),
        )
        .toList(growable: false);
    final next = [entry, ...withoutDuplicate];
    final capped = next.length > maxEntries
        ? next.sublist(0, maxEntries)
        : next;
    await _local.saveEntries(capped);
    return capped;
  }

  @override
  Future<List<RecentSearchEntry>> remove(RecentSearchEntry entry) async {
    final existing = await _local.loadEntries();
    final next = existing
        .where(
          (e) => !listingDiscoveryCriteriaEqualIgnoringSort(
            e.criteria,
            entry.criteria,
          ),
        )
        .toList(growable: false);
    await _local.saveEntries(next);
    return next;
  }

  @override
  Future<void> clear() => _local.clear();
}
