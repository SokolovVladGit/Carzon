import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/recently_viewed_entry.dart';
import '../../domain/repositories/recently_viewed_repository.dart';
import 'recently_viewed_state.dart';

/// Device-local recently viewed listings (guest OK, not synced).
class RecentlyViewedCubit extends Cubit<RecentlyViewedState> {
  RecentlyViewedCubit({required RecentlyViewedRepository repository})
    : _repository = repository,
      super(const RecentlyViewedState());

  final RecentlyViewedRepository _repository;

  Future<void> loadFromStorage() async {
    emit(state.copyWith(status: RecentlyViewedStatus.loading));
    try {
      final entries = await _repository.load();
      emit(
        RecentlyViewedState(
          status: RecentlyViewedStatus.ready,
          entries: List<RecentlyViewedEntry>.unmodifiable(entries),
        ),
      );
    } catch (_) {
      emit(const RecentlyViewedState(status: RecentlyViewedStatus.failure));
    }
  }

  /// Updates in-memory state after persistence elsewhere (e.g. details load).
  void syncEntries(List<RecentlyViewedEntry> entries) {
    emit(
      RecentlyViewedState(
        status: RecentlyViewedStatus.ready,
        entries: List<RecentlyViewedEntry>.unmodifiable(entries),
      ),
    );
  }

  Future<bool> clear() async {
    try {
      await _repository.clear();
      emit(
        const RecentlyViewedState(
          status: RecentlyViewedStatus.ready,
          entries: [],
        ),
      );
      return true;
    } catch (_) {
      emit(state.copyWith(status: RecentlyViewedStatus.failure));
      return false;
    }
  }
}
