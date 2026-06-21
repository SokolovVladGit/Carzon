import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/recent_search_entry.dart';
import '../../domain/repositories/recent_searches_repository.dart';
import 'recent_searches_state.dart';

/// Device-local recent discovery searches (guest OK, not synced).
class RecentSearchesCubit extends Cubit<RecentSearchesState> {
  RecentSearchesCubit({required RecentSearchesRepository repository})
    : _repository = repository,
      super(const RecentSearchesState());

  final RecentSearchesRepository _repository;

  Future<void> loadFromStorage() async {
    emit(state.copyWith(status: RecentSearchesStatus.loading));
    try {
      final entries = await _repository.load();
      emit(
        RecentSearchesState(
          status: RecentSearchesStatus.ready,
          entries: List<RecentSearchEntry>.unmodifiable(entries),
        ),
      );
    } catch (_) {
      emit(const RecentSearchesState(status: RecentSearchesStatus.failure));
    }
  }

  /// Updates in-memory state after persistence elsewhere (e.g. feed load).
  void syncEntries(List<RecentSearchEntry> entries) {
    emit(
      RecentSearchesState(
        status: RecentSearchesStatus.ready,
        entries: List<RecentSearchEntry>.unmodifiable(entries),
      ),
    );
  }

  Future<bool> remove(RecentSearchEntry entry) async {
    try {
      final updated = await _repository.remove(entry);
      emit(
        RecentSearchesState(
          status: RecentSearchesStatus.ready,
          entries: List<RecentSearchEntry>.unmodifiable(updated),
        ),
      );
      return true;
    } catch (_) {
      emit(state.copyWith(status: RecentSearchesStatus.failure));
      return false;
    }
  }

  Future<bool> clear() async {
    try {
      await _repository.clear();
      emit(
        const RecentSearchesState(
          status: RecentSearchesStatus.ready,
          entries: [],
        ),
      );
      return true;
    } catch (_) {
      emit(state.copyWith(status: RecentSearchesStatus.failure));
      return false;
    }
  }
}
