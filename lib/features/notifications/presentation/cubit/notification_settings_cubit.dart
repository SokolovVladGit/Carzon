import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/notification_preferences.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../services/push_messaging_permission_status.dart';
import '../../services/push_notification_registration_service.dart';

enum NotificationSettingsLoadPhase { initial, loading, ready, failure }

enum NotificationUserNotice {
  none,
  osPermissionDenied,
  loadFailed,
  saveFailed,
  pushUnavailableInBuild,
}

class NotificationSettingsState extends Equatable {
  const NotificationSettingsState({
    this.phase = NotificationSettingsLoadPhase.initial,
    this.preferences,
    this.osPermission,
    this.notice = NotificationUserNotice.none,
    this.busy = false,
  });

  final NotificationSettingsLoadPhase phase;
  final NotificationPreferences? preferences;
  final PushMessagingPermissionStatus? osPermission;
  final NotificationUserNotice notice;
  final bool busy;

  bool get pushAvailableInBuild => Env.pushNotificationsEnabled;

  NotificationSettingsState copyWith({
    NotificationSettingsLoadPhase? phase,
    NotificationPreferences? preferences,
    PushMessagingPermissionStatus? osPermission,
    NotificationUserNotice? notice,
    bool? busy,
    bool clearPreferences = false,
  }) {
    return NotificationSettingsState(
      phase: phase ?? this.phase,
      preferences: clearPreferences ? null : (preferences ?? this.preferences),
      osPermission: osPermission ?? this.osPermission,
      notice: notice ?? this.notice,
      busy: busy ?? this.busy,
    );
  }

  @override
  List<Object?> get props => [phase, preferences, osPermission, notice, busy];
}

class NotificationSettingsCubit extends Cubit<NotificationSettingsState> {
  NotificationSettingsCubit({
    required NotificationsRepository notificationsRepository,
    required PushNotificationRegistrationService pushRegistration,
  }) : _repository = notificationsRepository,
       _pushRegistration = pushRegistration,
       super(const NotificationSettingsState());

  final NotificationsRepository _repository;
  final PushNotificationRegistrationService _pushRegistration;

  void clearNotice() {
    if (state.notice == NotificationUserNotice.none) return;
    emit(state.copyWith(notice: NotificationUserNotice.none));
  }

  Future<void> load() async {
    emit(
      state.copyWith(
        phase: NotificationSettingsLoadPhase.loading,
        notice: NotificationUserNotice.none,
      ),
    );

    final prefsResult = await _repository.getMyPreferences();
    switch (prefsResult) {
      case FailureResult():
        emit(
          const NotificationSettingsState(
            phase: NotificationSettingsLoadPhase.failure,
            notice: NotificationUserNotice.loadFailed,
          ),
        );
        return;
      case Success(:final value):
        PushMessagingPermissionStatus? perm;
        if (Env.pushNotificationsEnabled) {
          perm = await _pushRegistration.readOsNotificationPermissionStatus();
        }
        emit(
          NotificationSettingsState(
            phase: NotificationSettingsLoadPhase.ready,
            preferences: value,
            osPermission: perm,
            notice: NotificationUserNotice.none,
          ),
        );
    }
  }

  Future<void> setGlobalEnabled(bool enabled) async {
    final prefs = state.preferences;
    if (prefs == null || state.phase != NotificationSettingsLoadPhase.ready) {
      return;
    }

    if (!Env.pushNotificationsEnabled) {
      emit(
        state.copyWith(notice: NotificationUserNotice.pushUnavailableInBuild),
      );
      return;
    }

    emit(state.copyWith(busy: true, notice: NotificationUserNotice.none));

    try {
      if (enabled) {
        final requested = await _pushRegistration
            .requestOsNotificationPermission();
        if (!requested.allowsTokenRegistration) {
          emit(
            state.copyWith(
              busy: false,
              notice: NotificationUserNotice.osPermissionDenied,
            ),
          );
          return;
        }

        final update = await _repository.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: prefs.messagesEnabled,
          filterAlertsEnabled: prefs.filterAlertsEnabled,
        );
        switch (update) {
          case FailureResult():
            emit(
              state.copyWith(
                busy: false,
                notice: NotificationUserNotice.saveFailed,
              ),
            );
            return;
          case Success(:final value):
            final perm = await _pushRegistration
                .readOsNotificationPermissionStatus();
            await _pushRegistration.syncTokenWithBackendIfEligible();
            emit(
              state.copyWith(
                busy: false,
                preferences: value,
                osPermission: perm,
              ),
            );
        }
      } else {
        final update = await _repository.updateMyPreferences(
          globalEnabled: false,
          messagesEnabled: false,
          filterAlertsEnabled: false,
        );
        switch (update) {
          case FailureResult():
            emit(
              state.copyWith(
                busy: false,
                notice: NotificationUserNotice.saveFailed,
              ),
            );
            return;
          case Success(:final value):
            await _pushRegistration.revokeDevicePushRegistration();
            final perm = await _pushRegistration
                .readOsNotificationPermissionStatus();
            emit(
              state.copyWith(
                busy: false,
                preferences: value,
                osPermission: perm,
              ),
            );
        }
      }
    } catch (_) {
      emit(
        state.copyWith(busy: false, notice: NotificationUserNotice.saveFailed),
      );
    }
  }

  Future<void> setMessagesEnabled(bool enabled) async {
    final prefs = state.preferences;
    if (prefs == null || state.phase != NotificationSettingsLoadPhase.ready) {
      return;
    }

    if (!prefs.globalEnabled) {
      return;
    }

    if (!Env.pushNotificationsEnabled) {
      emit(
        state.copyWith(notice: NotificationUserNotice.pushUnavailableInBuild),
      );
      return;
    }

    emit(state.copyWith(busy: true, notice: NotificationUserNotice.none));

    try {
      if (enabled) {
        var perm = await _pushRegistration.readOsNotificationPermissionStatus();
        if (!perm.allowsTokenRegistration) {
          perm = await _pushRegistration.requestOsNotificationPermission();
        }
        if (!perm.allowsTokenRegistration) {
          emit(
            state.copyWith(
              busy: false,
              notice: NotificationUserNotice.osPermissionDenied,
            ),
          );
          return;
        }

        final update = await _repository.updateMyPreferences(
          globalEnabled: true,
          messagesEnabled: true,
          filterAlertsEnabled: prefs.filterAlertsEnabled,
        );
        switch (update) {
          case FailureResult():
            emit(
              state.copyWith(
                busy: false,
                notice: NotificationUserNotice.saveFailed,
              ),
            );
            return;
          case Success(:final value):
            final p = await _pushRegistration
                .readOsNotificationPermissionStatus();
            await _pushRegistration.syncTokenWithBackendIfEligible();
            emit(
              state.copyWith(busy: false, preferences: value, osPermission: p),
            );
        }
      } else {
        final update = await _repository.updateMyPreferences(
          globalEnabled: prefs.globalEnabled,
          messagesEnabled: false,
          filterAlertsEnabled: prefs.filterAlertsEnabled,
        );
        switch (update) {
          case FailureResult():
            emit(
              state.copyWith(
                busy: false,
                notice: NotificationUserNotice.saveFailed,
              ),
            );
            return;
          case Success(:final value):
            final p = await _pushRegistration
                .readOsNotificationPermissionStatus();
            emit(
              state.copyWith(busy: false, preferences: value, osPermission: p),
            );
        }
      }
    } catch (_) {
      emit(
        state.copyWith(busy: false, notice: NotificationUserNotice.saveFailed),
      );
    }
  }

  Future<void> setFilterAlertsEnabled(bool enabled) async {
    final prefs = state.preferences;
    if (prefs == null || state.phase != NotificationSettingsLoadPhase.ready) {
      return;
    }

    if (!prefs.globalEnabled) {
      return;
    }

    if (!Env.pushNotificationsEnabled) {
      emit(
        state.copyWith(notice: NotificationUserNotice.pushUnavailableInBuild),
      );
      return;
    }

    emit(state.copyWith(busy: true, notice: NotificationUserNotice.none));

    try {
      if (enabled) {
        var perm = await _pushRegistration.readOsNotificationPermissionStatus();
        if (!perm.allowsTokenRegistration) {
          perm = await _pushRegistration.requestOsNotificationPermission();
        }
        if (!perm.allowsTokenRegistration) {
          emit(
            state.copyWith(
              busy: false,
              notice: NotificationUserNotice.osPermissionDenied,
            ),
          );
          return;
        }

        final update = await _repository.updateMyPreferences(
          globalEnabled: prefs.globalEnabled,
          messagesEnabled: prefs.messagesEnabled,
          filterAlertsEnabled: true,
        );
        switch (update) {
          case FailureResult():
            emit(
              state.copyWith(
                busy: false,
                notice: NotificationUserNotice.saveFailed,
              ),
            );
            return;
          case Success(:final value):
            final p = await _pushRegistration
                .readOsNotificationPermissionStatus();
            await _pushRegistration.syncTokenWithBackendIfEligible();
            emit(
              state.copyWith(busy: false, preferences: value, osPermission: p),
            );
        }
      } else {
        final update = await _repository.updateMyPreferences(
          globalEnabled: prefs.globalEnabled,
          messagesEnabled: prefs.messagesEnabled,
          filterAlertsEnabled: false,
        );
        switch (update) {
          case FailureResult():
            emit(
              state.copyWith(
                busy: false,
                notice: NotificationUserNotice.saveFailed,
              ),
            );
            return;
          case Success(:final value):
            final p = await _pushRegistration
                .readOsNotificationPermissionStatus();
            emit(
              state.copyWith(busy: false, preferences: value, osPermission: p),
            );
        }
      }
    } catch (_) {
      emit(
        state.copyWith(busy: false, notice: NotificationUserNotice.saveFailed),
      );
    }
  }
}
