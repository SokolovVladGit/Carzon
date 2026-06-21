import '../entities/recently_viewed_entry.dart';
import '../repositories/recently_viewed_repository.dart';
import '../../presentation/cubit/recently_viewed_cubit.dart';

/// Persists a recently viewed listing and syncs the global cubit.
class RecordRecentlyViewed {
  RecordRecentlyViewed(this._repository, this._cubit);

  final RecentlyViewedRepository _repository;
  final RecentlyViewedCubit _cubit;

  Future<void> call(RecentlyViewedEntry entry) async {
    final updated = await _repository.record(entry);
    _cubit.syncEntries(updated);
  }
}
