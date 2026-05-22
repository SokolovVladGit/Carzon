import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/compare_item.dart';
import '../../domain/entities/compare_listing_snapshot.dart';
import '../../domain/repositories/compare_repository.dart';
import 'compare_state.dart';

/// Global local compare set for the short-list vehicle decision tool.
///
/// Not tied to auth; persisted on device via [CompareRepository].
class CompareCubit extends Cubit<CompareState> {
  CompareCubit({required CompareRepository repository})
    : _repository = repository,
      super(const CompareState());

  final CompareRepository _repository;

  /// Restores the compare set from local storage (called at app bootstrap).
  Future<void> loadFromStorage() async {
    final items = await _repository.loadItems();
    final trimmed = items.length > CompareState.maxItems
        ? items.sublist(0, CompareState.maxItems)
        : items;
    emit(CompareState(items: trimmed));
    if (trimmed.length != items.length) {
      await _persist(trimmed);
    }
  }

  /// Adds [snapshot] when not duplicate and set is not full.
  Future<void> addSnapshot(CompareListingSnapshot snapshot) async {
    if (state.containsListing(snapshot.listingId)) return;
    if (state.isFull) return;
    final next = [
      ...state.items,
      CompareItem(snapshot: snapshot),
    ];
    await _persist(next);
  }

  Future<void> remove(String listingId) async {
    if (!state.containsListing(listingId)) return;
    final next = state.items
        .where((i) => i.listingId != listingId)
        .toList(growable: false);
    await _persist(next);
  }

  Future<void> clear() async {
    await _repository.clear();
    emit(const CompareState());
  }

  /// Adds when absent (if room); removes when already present.
  Future<void> toggleSnapshot(CompareListingSnapshot snapshot) async {
    if (state.containsListing(snapshot.listingId)) {
      await remove(snapshot.listingId);
      return;
    }
    await addSnapshot(snapshot);
  }

  Future<void> _persist(List<CompareItem> items) async {
    await _repository.saveItems(items);
    emit(CompareState(items: List<CompareItem>.unmodifiable(items)));
  }
}
