import '../entities/recent_search_entry.dart';

abstract interface class RecentSearchesRepository {
  Future<List<RecentSearchEntry>> load();

  Future<List<RecentSearchEntry>> record(RecentSearchEntry entry);

  Future<List<RecentSearchEntry>> remove(RecentSearchEntry entry);

  Future<void> clear();
}
