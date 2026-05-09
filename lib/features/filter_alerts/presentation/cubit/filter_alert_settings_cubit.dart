import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../domain/entities/filter_alert_settings.dart';
import '../../domain/usecases/clear_filter_alert_criteria.dart';
import '../../domain/usecases/get_filter_alert_settings.dart';
import '../../domain/usecases/save_filter_alert_criteria.dart';

enum FilterAlertSettingsLoadStatus { initial, loading, loaded, failure }

class FilterAlertSettingsState extends Equatable {
  const FilterAlertSettingsState({
    this.status = FilterAlertSettingsLoadStatus.initial,
    this.settings,
    this.errorMessage,
    this.busySaving = false,
    this.busyClearing = false,
  });

  final FilterAlertSettingsLoadStatus status;
  final FilterAlertSettings? settings;
  final String? errorMessage;
  final bool busySaving;
  final bool busyClearing;

  bool get hasBackendRow =>
      settings != null && settings!.criteria != null;

  FilterAlertSettingsState copyWith({
    FilterAlertSettingsLoadStatus? status,
    FilterAlertSettings? settings,
    String? errorMessage,
    bool? busySaving,
    bool? busyClearing,
    bool clearError = false,
    bool clearSettings = false,
  }) {
    return FilterAlertSettingsState(
      status: status ?? this.status,
      settings: clearSettings ? null : (settings ?? this.settings),
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      busySaving: busySaving ?? this.busySaving,
      busyClearing: busyClearing ?? this.busyClearing,
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    errorMessage,
    busySaving,
    busyClearing,
  ];
}

class FilterAlertSettingsCubit extends Cubit<FilterAlertSettingsState> {
  FilterAlertSettingsCubit({
    required GetFilterAlertSettings getSettings,
    required SaveFilterAlertCriteria saveCriteria,
    required ClearFilterAlertCriteria clearCriteria,
  }) : _getSettings = getSettings,
       _saveCriteria = saveCriteria,
       _clearCriteria = clearCriteria,
       super(const FilterAlertSettingsState());

  final GetFilterAlertSettings _getSettings;
  final SaveFilterAlertCriteria _saveCriteria;
  final ClearFilterAlertCriteria _clearCriteria;

  Future<void> refresh() async {
    emit(
      state.copyWith(
        status: FilterAlertSettingsLoadStatus.loading,
        clearError: true,
      ),
    );
    final result = await _getSettings();
    switch (result) {
      case FailureResult():
        emit(
          const FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.failure,
          ),
        );
      case Success(:final value):
        emit(
          FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.loaded,
            settings: value,
          ),
        );
    }
  }

  Future<Result<FilterAlertSettings>> save(
    ListingDiscoveryCriteria criteria,
  ) async {
    emit(state.copyWith(busySaving: true, clearError: true));
    final result = await _saveCriteria(criteria);
    switch (result) {
      case FailureResult():
        emit(
          FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.loaded,
            settings: state.settings,
          ),
        );
      case Success(:final value):
        emit(
          FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.loaded,
            settings: value,
          ),
        );
    }
    emit(state.copyWith(busySaving: false));
    return result;
  }

  Future<Result<FilterAlertSettings>> clearPersistedCriteria() async {
    emit(state.copyWith(busyClearing: true, clearError: true));
    final result = await _clearCriteria();
    switch (result) {
      case FailureResult():
        emit(
          FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.loaded,
            settings: state.settings,
          ),
        );
      case Success(:final value):
        emit(
          FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.loaded,
            settings: value,
          ),
        );
    }
    emit(state.copyWith(busyClearing: false));
    return result;
  }
}
