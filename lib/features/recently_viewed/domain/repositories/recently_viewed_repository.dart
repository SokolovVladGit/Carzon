import '../entities/recently_viewed_entry.dart';

/// Local recently-viewed history (device-only, Phase 1).
abstract interface class RecentlyViewedRepository {
  Future<List<RecentlyViewedEntry>> load();

  Future<List<RecentlyViewedEntry>> record(RecentlyViewedEntry entry);

  Future<void> clear();
}
