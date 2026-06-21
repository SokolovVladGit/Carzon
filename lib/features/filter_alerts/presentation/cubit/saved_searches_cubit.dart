import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/saved_search.dart';
import '../../domain/services/filter_alert_delivery_orchestrator.dart';
import '../../domain/usecases/delete_saved_search.dart';
import '../../domain/usecases/list_saved_searches.dart';
import '../../domain/usecases/set_saved_search_alerts_enabled.dart';

enum SavedSearchesLoadStatus { initial, loading, loaded, failure }

enum SavedSearchesUserNotice {
  none,
  osPermissionDenied,
  pushUnavailableInBuild,
  prefsUpdateFailed,
}

class SavedSearchesState extends Equatable {
  const SavedSearchesState({
    this.status = SavedSearchesLoadStatus.initial,
    this.savedSearches = const [],
    this.togglingIds = const {},
    this.deletingIds = const {},
    this.userNotice = SavedSearchesUserNotice.none,
  });

  final SavedSearchesLoadStatus status;
  final List<SavedSearch> savedSearches;
  final Set<String> togglingIds;
  final Set<String> deletingIds;
  final SavedSearchesUserNotice userNotice;

  bool isToggling(String id) => togglingIds.contains(id);
  bool isDeleting(String id) => deletingIds.contains(id);

  SavedSearchesState copyWith({
    SavedSearchesLoadStatus? status,
    List<SavedSearch>? savedSearches,
    Set<String>? togglingIds,
    Set<String>? deletingIds,
    SavedSearchesUserNotice? userNotice,
    bool clearNotice = false,
  }) {
    return SavedSearchesState(
      status: status ?? this.status,
      savedSearches: savedSearches ?? this.savedSearches,
      togglingIds: togglingIds ?? this.togglingIds,
      deletingIds: deletingIds ?? this.deletingIds,
      userNotice: clearNotice
          ? SavedSearchesUserNotice.none
          : (userNotice ?? this.userNotice),
    );
  }

  @override
  List<Object?> get props => [
    status,
    savedSearches,
    togglingIds,
    deletingIds,
    userNotice,
  ];
}

class SavedSearchesCubit extends Cubit<SavedSearchesState> {
  SavedSearchesCubit({
    required ListSavedSearches listSavedSearches,
    required DeleteSavedSearch deleteSavedSearch,
    required FilterAlertDeliveryOrchestrator deliveryOrchestrator,
  }) : _listSavedSearches = listSavedSearches,
       _deleteSavedSearch = deleteSavedSearch,
       _deliveryOrchestrator = deliveryOrchestrator,
       super(const SavedSearchesState());

  final ListSavedSearches _listSavedSearches;
  final DeleteSavedSearch _deleteSavedSearch;
  final FilterAlertDeliveryOrchestrator _deliveryOrchestrator;

  void clearUserNotice() {
    if (state.userNotice == SavedSearchesUserNotice.none) return;
    emit(state.copyWith(clearNotice: true));
  }

  Future<void> refresh() async {
    emit(
      state.copyWith(
        status: SavedSearchesLoadStatus.loading,
        clearNotice: true,
      ),
    );
    final result = await _listSavedSearches();
    switch (result) {
      case FailureResult():
        emit(const SavedSearchesState(status: SavedSearchesLoadStatus.failure));
      case Success(:final value):
        emit(
          SavedSearchesState(
            status: SavedSearchesLoadStatus.loaded,
            savedSearches: value,
          ),
        );
    }
  }

  Future<Result<void>> deleteSavedSearch(String id) async {
    emit(
      state.copyWith(
        deletingIds: {...state.deletingIds, id},
        clearNotice: true,
      ),
    );
    final result = await _deleteSavedSearch(id);
    switch (result) {
      case FailureResult():
        emit(state.copyWith(deletingIds: {...state.deletingIds}..remove(id)));
      case Success():
        final updated = state.savedSearches
            .where((s) => s.id != id)
            .toList(growable: false);
        emit(
          state.copyWith(
            savedSearches: updated,
            deletingIds: {...state.deletingIds}..remove(id),
          ),
        );
    }
    return result;
  }

  Future<Result<SavedSearch>> setAlertsEnabled(String id, bool enabled) async {
    emit(
      state.copyWith(
        togglingIds: {...state.togglingIds, id},
        clearNotice: true,
      ),
    );

    final row = state.savedSearches.where((s) => s.id == id).firstOrNull;
    if (row == null) {
      emit(state.copyWith(togglingIds: {...state.togglingIds}..remove(id)));
      return const FailureResult(UnknownFailure('saved_search_not_found'));
    }

    final Result<SavedSearch> result;
    if (enabled) {
      result = await _deliveryOrchestrator.enableDeliveries(row);
    } else {
      result = await _deliveryOrchestrator.disableDeliveries(row);
    }

    switch (result) {
      case FailureResult(:final failure):
        final notice = switch (failure.message) {
          'filter_alert_delivery_push_disabled' =>
            SavedSearchesUserNotice.pushUnavailableInBuild,
          'filter_alert_delivery_permission_denied' =>
            SavedSearchesUserNotice.osPermissionDenied,
          _ => SavedSearchesUserNotice.prefsUpdateFailed,
        };
        emit(
          state.copyWith(
            togglingIds: {...state.togglingIds}..remove(id),
            userNotice: notice,
          ),
        );
      case Success(:final value):
        final updated = state.savedSearches
            .map((s) => s.id == id ? value : s)
            .toList(growable: false);
        emit(
          state.copyWith(
            savedSearches: updated,
            togglingIds: {...state.togglingIds}..remove(id),
          ),
        );
    }
    return result;
  }
}
