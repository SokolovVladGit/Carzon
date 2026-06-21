import '../../domain/entities/recently_viewed_entry.dart';
import '../../domain/repositories/recently_viewed_repository.dart';
import '../datasources/recently_viewed_local_datasource.dart';

final class RecentlyViewedRepositoryImpl implements RecentlyViewedRepository {
  RecentlyViewedRepositoryImpl(this._local);

  final RecentlyViewedLocalDataSource _local;

  @override
  Future<List<RecentlyViewedEntry>> load() => _local.loadEntries();

  @override
  Future<List<RecentlyViewedEntry>> record(RecentlyViewedEntry entry) async {
    final existing = await _local.loadEntries();
    final withoutDuplicate = existing
        .where((e) => e.listingId != entry.listingId)
        .toList(growable: false);
    final next = [entry, ...withoutDuplicate];
    final capped =
        next.length > SharedPreferencesRecentlyViewedLocalDataSource.maxEntries
        ? next.sublist(
            0,
            SharedPreferencesRecentlyViewedLocalDataSource.maxEntries,
          )
        : next;
    await _local.saveEntries(capped);
    return capped;
  }

  @override
  Future<void> clear() => _local.clear();
}
