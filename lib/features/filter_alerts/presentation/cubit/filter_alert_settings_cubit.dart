import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../domain/entities/filter_alert_settings.dart';
import '../../domain/services/filter_alert_delivery_orchestrator.dart';
import '../../domain/usecases/clear_filter_alert_criteria.dart';
import '../../domain/usecases/get_filter_alert_settings.dart';
import '../../domain/usecases/save_filter_alert_criteria.dart';

enum FilterAlertSettingsLoadStatus { initial, loading, loaded, failure }

enum FilterAlertSettingsUserNotice {
  none,
  osPermissionDenied,
  pushUnavailableInBuild,
  saveFilterBeforeNotifications,
  prefsUpdateFailed,
}

class FilterAlertSettingsState extends Equatable {
  const FilterAlertSettingsState({
    this.status = FilterAlertSettingsLoadStatus.initial,
    this.settings,
    this.errorMessage,
    this.busySaving = false,
    this.busyClearing = false,
    this.busyNotificationToggle = false,
    this.userNotice = FilterAlertSettingsUserNotice.none,
  });

  final FilterAlertSettingsLoadStatus status;
  final FilterAlertSettings? settings;
  final String? errorMessage;
  final bool busySaving;
  final bool busyClearing;
  final bool busyNotificationToggle;
  final FilterAlertSettingsUserNotice userNotice;

  bool get hasBackendRow => settings != null && settings!.criteria != null;

  FilterAlertSettingsState copyWith({
    FilterAlertSettingsLoadStatus? status,
    FilterAlertSettings? settings,
    String? errorMessage,
    bool? busySaving,
    bool? busyClearing,
    bool? busyNotificationToggle,
    FilterAlertSettingsUserNotice? userNotice,
    bool clearError = false,
    bool clearSettings = false,
    bool clearNotice = false,
  }) {
    return FilterAlertSettingsState(
      status: status ?? this.status,
      settings: clearSettings ? null : (settings ?? this.settings),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      busySaving: busySaving ?? this.busySaving,
      busyClearing: busyClearing ?? this.busyClearing,
      busyNotificationToggle:
          busyNotificationToggle ?? this.busyNotificationToggle,
      userNotice: clearNotice
          ? FilterAlertSettingsUserNotice.none
          : (userNotice ?? this.userNotice),
    );
  }

  @override
  List<Object?> get props => [
    status,
    settings,
    errorMessage,
    busySaving,
    busyClearing,
    busyNotificationToggle,
    userNotice,
  ];
}

class FilterAlertSettingsCubit extends Cubit<FilterAlertSettingsState> {
  FilterAlertSettingsCubit({
    required GetFilterAlertSettings getSettings,
    required SaveFilterAlertCriteria saveCriteria,
    required ClearFilterAlertCriteria clearCriteria,
    required FilterAlertDeliveryOrchestrator deliveryOrchestrator,
  }) : _getSettings = getSettings,
       _saveCriteria = saveCriteria,
       _clearCriteria = clearCriteria,
       _deliveryOrchestrator = deliveryOrchestrator,
       super(const FilterAlertSettingsState());

  final GetFilterAlertSettings _getSettings;
  final SaveFilterAlertCriteria _saveCriteria;
  final ClearFilterAlertCriteria _clearCriteria;
  final FilterAlertDeliveryOrchestrator _deliveryOrchestrator;

  void clearUserNotice() {
    if (state.userNotice == FilterAlertSettingsUserNotice.none) return;
    emit(state.copyWith(clearNotice: true));
  }

  Future<void> refresh() async {
    emit(
      state.copyWith(
        status: FilterAlertSettingsLoadStatus.loading,
        clearError: true,
        clearNotice: true,
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
    emit(state.copyWith(busySaving: true, clearError: true, clearNotice: true));
    final notif = state.settings?.notificationsEnabled ?? false;
    final result = await _saveCriteria(criteria, notificationsEnabled: notif);
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
    emit(
      state.copyWith(busyClearing: true, clearError: true, clearNotice: true),
    );
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

  /// Enables filter-alert push path: OS permission (explicit), prefs, server flag, token sync.
  Future<Result<FilterAlertSettings>> enableFilterAlertNotifications() async {
    if (state.settings?.criteria == null) {
      emit(
        state.copyWith(
          userNotice:
              FilterAlertSettingsUserNotice.saveFilterBeforeNotifications,
        ),
      );
      return const FailureResult(UnknownFailure('no_criteria'));
    }

    emit(state.copyWith(busyNotificationToggle: true, clearNotice: true));

    final deliver = await _deliveryOrchestrator.enableDeliveries(
      state.settings!,
    );

    switch (deliver) {
      case FailureResult(:final failure):
        final FilterAlertSettingsUserNotice notice =
            failure.message == 'filter_alert_delivery_push_disabled'
            ? FilterAlertSettingsUserNotice.pushUnavailableInBuild
            : failure.message == 'filter_alert_delivery_permission_denied'
            ? FilterAlertSettingsUserNotice.osPermissionDenied
            : FilterAlertSettingsUserNotice.prefsUpdateFailed;
        emit(state.copyWith(busyNotificationToggle: false, userNotice: notice));
        return deliver;
      case Success(:final value):
        emit(
          FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.loaded,
            settings: value,
            busyNotificationToggle: false,
          ),
        );
        return deliver;
    }
  }

  /// Disables filter-alert delivery flag only (criteria and global/message prefs unchanged).
  Future<Result<FilterAlertSettings>> disableFilterAlertNotifications() async {
    emit(state.copyWith(busyNotificationToggle: true, clearNotice: true));
    final result = await _deliveryOrchestrator.disableDeliveriesFlagOnly();
    switch (result) {
      case FailureResult():
        emit(state.copyWith(busyNotificationToggle: false));
      case Success(:final value):
        emit(
          FilterAlertSettingsState(
            status: FilterAlertSettingsLoadStatus.loaded,
            settings: value,
            busyNotificationToggle: false,
          ),
        );
    }
    return result;
  }
}
