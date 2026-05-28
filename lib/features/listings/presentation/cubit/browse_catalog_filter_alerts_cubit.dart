import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../filter_alerts/domain/entities/filter_alert_settings.dart';
import '../../../filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import '../../../filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import '../../../filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import '../../../filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
import '../../../notifications/domain/entities/notification_preferences.dart';
import '../../../notifications/domain/repositories/notifications_repository.dart';
import '../../domain/browse_state_for_alert_criteria.dart';
import '../../domain/entities/listing_discovery_criteria.dart';
import '../../domain/filter_alert_catalog_criteria_compare.dart';
import '../bloc/listings_state.dart';
import 'browse_catalog_filter_alerts_models.dart';

enum BrowseCatalogFilterAlertsLoadPhase { idle, loading, ready, failure }

class BrowseCatalogFilterAlertsState extends Equatable {
  const BrowseCatalogFilterAlertsState({
    this.phase = BrowseCatalogFilterAlertsLoadPhase.idle,
    this.settings,
    this.prefs,
    this.bellBusy = false,
  });

  final BrowseCatalogFilterAlertsLoadPhase phase;
  final FilterAlertSettings? settings;
  final NotificationPreferences? prefs;
  final bool bellBusy;

  bool get deliveryFullyEnabled {
    final s = settings;
    final p = prefs;
    if (s == null || s.criteria == null || !s.notificationsEnabled) {
      return false;
    }
    if (p == null || !p.globalEnabled || !p.filterAlertsEnabled) return false;
    return true;
  }

  BrowseCatalogFilterAlertsState copyWith({
    BrowseCatalogFilterAlertsLoadPhase? phase,
    FilterAlertSettings? settings,
    NotificationPreferences? prefs,
    bool? bellBusy,
    bool clearSettingsPrefs = false,
  }) {
    return BrowseCatalogFilterAlertsState(
      phase: phase ?? this.phase,
      settings: clearSettingsPrefs ? null : (settings ?? this.settings),
      prefs: clearSettingsPrefs ? null : (prefs ?? this.prefs),
      bellBusy: bellBusy ?? this.bellBusy,
    );
  }

  @override
  List<Object?> get props => [phase, settings, prefs, bellBusy];
}

BrowseCatalogBellOutcome _browseOutcomeFromEnableFailure(String message) {
  return switch (message) {
    'filter_alert_delivery_push_disabled' =>
      BrowseCatalogBellOutcome.pushBuildDisabled,
    'filter_alert_delivery_permission_denied' =>
      BrowseCatalogBellOutcome.osPermissionDenied,
    _ => BrowseCatalogBellOutcome.prefsOrRowFailed,
  };
}

class BrowseCatalogFilterAlertsCubit
    extends Cubit<BrowseCatalogFilterAlertsState> {
  BrowseCatalogFilterAlertsCubit({
    required GetFilterAlertSettings getSettings,
    required SaveFilterAlertCriteria saveCriteria,
    required ClearFilterAlertCriteria clearCriteria,
    required NotificationsRepository notificationsRepository,
    required FilterAlertDeliveryOrchestrator deliveryOrchestrator,
  }) : _getSettings = getSettings,
       _saveCriteria = saveCriteria,
       _clearCriteria = clearCriteria,
       _notificationsRepository = notificationsRepository,
       _deliveryOrchestrator = deliveryOrchestrator,
       super(const BrowseCatalogFilterAlertsState());

  final GetFilterAlertSettings _getSettings;
  final SaveFilterAlertCriteria _saveCriteria;
  final ClearFilterAlertCriteria _clearCriteria;
  final NotificationsRepository _notificationsRepository;
  final FilterAlertDeliveryOrchestrator _deliveryOrchestrator;

  void onAuthChanged(AuthState auth) {
    switch (auth.status) {
      case AuthStatus.authenticated:
        refresh();
      default:
        emit(
          const BrowseCatalogFilterAlertsState(
            phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          ),
        );
    }
  }

  Future<void> refresh() async {
    emit(
      state.copyWith(
        phase: BrowseCatalogFilterAlertsLoadPhase.loading,
        bellBusy: false,
      ),
    );
    final prefsRes = await _notificationsRepository.getMyPreferences();
    NotificationPreferences? p;
    switch (prefsRes) {
      case FailureResult():
        p = null;
      case Success(:final value):
        p = value;
    }

    final settingsRes = await _getSettings();
    switch (settingsRes) {
      case FailureResult():
        emit(
          BrowseCatalogFilterAlertsState(
            phase: BrowseCatalogFilterAlertsLoadPhase.failure,
            prefs: p,
          ),
        );
        return;
      case Success(:final value):
        emit(
          BrowseCatalogFilterAlertsState(
            phase: BrowseCatalogFilterAlertsLoadPhase.ready,
            settings: value,
            prefs: p,
          ),
        );
    }
  }

  bool catalogBellBadgeVisibleForApplied(ListingsState applied) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    final s = state.settings;
    if (s == null || s.criteria == null) return false;
    if (!state.deliveryFullyEnabled) return false;
    final merged = listingDiscoveryCriteriaFromBrowseStateForAlert(applied);
    return listingDiscoveryCriteriaEqualIgnoringSort(merged, s.criteria!);
  }

  /// Whether the main catalog filter FAB should render the distinct
  /// "saved alert, delivery unavailable" ornament for the currently
  /// applied [applied] feed: saved criteria exists and matches the feed,
  /// but `deliveryFullyEnabled` is false (push-disabled build, prefs
  /// global/filter-alerts off, or `notifications_enabled=false` on the
  /// row).
  ///
  /// Mutually exclusive with [catalogBellBadgeVisibleForApplied]; the
  /// FAB UI must prefer the active-delivery ornament when both helpers
  /// somehow returned true (delivery wins). They cannot actually both
  /// return true: `deliveryFullyEnabled` is the discriminator.
  bool catalogBellSavedWithoutDeliveryVisibleForApplied(ListingsState applied) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    final s = state.settings;
    if (s == null || s.criteria == null) return false;
    if (state.deliveryFullyEnabled) return false;
    final merged = listingDiscoveryCriteriaFromBrowseStateForAlert(applied);
    return listingDiscoveryCriteriaEqualIgnoringSort(merged, s.criteria!);
  }

  bool browseBellShowsActiveDraft(ListingDiscoveryCriteria draft) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    final s = state.settings;
    if (s == null || s.criteria == null) return false;
    if (!state.deliveryFullyEnabled) return false;
    return listingDiscoveryCriteriaEqualIgnoringSort(draft, s.criteria!);
  }

  /// Whether the in-sheet bell should render the "saved, delivery
  /// unavailable" affordance for [draft]: the user has previously saved
  /// matching criteria but delivery is not fully enabled (typically a
  /// push-disabled build, or prefs/`filter_alerts_enabled` not yet on).
  ///
  /// Distinct from [browseBellShowsActiveDraft], which only flips true
  /// once delivery is fully on. Catalog FAB ornament intentionally does
  /// **not** use this state — strong amber on the feed remains reserved
  /// for active delivery (`catalogBellBadgeVisibleForApplied`).
  bool browseBellShowsSavedDraftWithoutDelivery(
    ListingDiscoveryCriteria draft,
  ) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    final s = state.settings;
    if (s == null || s.criteria == null) return false;
    if (state.deliveryFullyEnabled) return false;
    return listingDiscoveryCriteriaEqualIgnoringSort(draft, s.criteria!);
  }

  Future<BrowseCatalogBellOutcome> handleCatalogFilterBell({
    required ListingDiscoveryCriteria draftCriteria,
    required bool authenticated,
  }) async {
    if (!authenticated) {
      return BrowseCatalogBellOutcome.signedOut;
    }
    if (!discoveryCriteriaEligibleForFilterAlertPersist(draftCriteria)) {
      return BrowseCatalogBellOutcome.criteriaTooBroad;
    }

    final matched =
        state.settings?.criteria != null &&
        listingDiscoveryCriteriaEqualIgnoringSort(
          draftCriteria,
          state.settings!.criteria!,
        );
    final deliveryOn = state.deliveryFullyEnabled;

    emit(state.copyWith(bellBusy: true));
    try {
      // Tap-to-toggle semantics: if the current draft already matches
      // the saved alert criteria, the bell acts as an OFF switch and
      // clears the row regardless of whether delivery was fully on.
      //
      // `upsertClearsCriteria` (the backend behind
      // [ClearFilterAlertCriteria]) sets `criteria = null` AND flips
      // `notifications_enabled = false` in one round-trip, so this
      // path subsumes the previous `disableDeliveriesFlagOnly` branch
      // — the row is cleanly returned to a "no saved alert" baseline
      // and the catalog FAB ornaments / sheet bell / inline banner all
      // become inactive on the subsequent `refresh()`.
      //
      // Notification preferences (`global_enabled`,
      // `filter_alerts_enabled`) are intentionally untouched: they are
      // cross-feature settings owned by the notification settings
      // surface, not by this filter alert row.
      if (matched) {
        final clearResult = await _clearCriteria();
        switch (clearResult) {
          case FailureResult():
            emit(state.copyWith(bellBusy: false));
            await refresh();
            if (kDebugMode) {
              debugPrint(
                '[catalogBell] outcome=savedAlertClearFailed '
                'deliveryWasOn=$deliveryOn '
                'pushNotificationsEnabled=${Env.pushNotificationsEnabled}',
              );
            }
            return BrowseCatalogBellOutcome.savedAlertClearFailed;
          case Success(:final value):
            emit(state.copyWith(bellBusy: false, settings: value));
            await refresh();
            if (kDebugMode) {
              debugPrint(
                '[catalogBell] outcome=savedAlertCleared '
                'deliveryWasOn=$deliveryOn '
                'pushNotificationsEnabled=${Env.pushNotificationsEnabled}',
              );
            }
            return BrowseCatalogBellOutcome.savedAlertCleared;
        }
      }

      // Push-disabled build: persist criteria so the saved alert exists
      // for `/filter-alert` management + future enable, but never call
      // the delivery orchestrator (no permission prompt, no prefs upsert,
      // no FCM token sync). Surfaces as a success-shaped UX rather than
      // a "push unavailable" failure.
      if (!Env.pushNotificationsEnabled) {
        if (!matched) {
          final prevFlag = state.settings?.notificationsEnabled ?? false;
          final save = await _saveCriteria(
            draftCriteria,
            notificationsEnabled: prevFlag,
          );
          switch (save) {
            case FailureResult():
              emit(state.copyWith(bellBusy: false));
              return BrowseCatalogBellOutcome.criteriaSaveFailed;
            case Success():
              break;
          }
        }
        emit(state.copyWith(bellBusy: false));
        await refresh();
        if (kDebugMode) {
          debugPrint(
            '[catalogBell] outcome=criteriaSavedDeliveryUnavailable '
            'matched=$matched '
            'deliveryFullyEnabled=${state.deliveryFullyEnabled} '
            'pushNotificationsEnabled=${Env.pushNotificationsEnabled}',
          );
        }
        return BrowseCatalogBellOutcome.criteriaSavedDeliveryUnavailable;
      }

      if (!matched) {
        final prevFlag = state.settings?.notificationsEnabled ?? false;
        final save = await _saveCriteria(
          draftCriteria,
          notificationsEnabled: prevFlag,
        );
        switch (save) {
          case FailureResult():
            emit(state.copyWith(bellBusy: false));
            return BrowseCatalogBellOutcome.criteriaSaveFailed;
          case Success(:final value):
            emit(state.copyWith(settings: value));
        }
      }

      final rowAfter = await _freshSettingsSnapshot();
      if (rowAfter?.criteria == null) {
        emit(state.copyWith(bellBusy: false));
        return BrowseCatalogBellOutcome.criteriaSaveFailed;
      }

      switch (await _deliveryOrchestrator.enableDeliveries(rowAfter!)) {
        case FailureResult(:final failure):
          emit(state.copyWith(bellBusy: false));
          await refresh();
          if (failure.message == 'filter_alert_delivery_prefs_save_failed' ||
              failure.message == 'filter_alert_delivery_prefs_load_failed') {
            return BrowseCatalogBellOutcome.prefsOrRowFailed;
          }
          return _browseOutcomeFromEnableFailure(failure.message);
        case Success(:final value):
          emit(state.copyWith(bellBusy: false, settings: value));
          await refresh();
          return BrowseCatalogBellOutcome.deliveriesEnabled;
      }
    } catch (_) {
      emit(state.copyWith(bellBusy: false));
      await refresh();
      return BrowseCatalogBellOutcome.prefsOrRowFailed;
    }
  }

  Future<FilterAlertSettings?> _freshSettingsSnapshot() async {
    final r = await _getSettings();
    switch (r) {
      case FailureResult():
        return null;
      case Success(:final value):
        return value;
    }
  }
}
