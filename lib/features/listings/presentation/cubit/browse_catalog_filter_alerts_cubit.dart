import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../filter_alerts/domain/entities/saved_search.dart';
import '../../../filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import '../../../filter_alerts/domain/usecases/create_saved_search.dart';
import '../../../filter_alerts/domain/usecases/delete_saved_search.dart';
import '../../../filter_alerts/domain/usecases/list_saved_searches.dart';
import '../../../filter_alerts/domain/utils/saved_search_match.dart';
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
    this.savedSearches = const [],
    this.prefs,
    this.bellBusy = false,
  });

  final BrowseCatalogFilterAlertsLoadPhase phase;
  final List<SavedSearch> savedSearches;
  final NotificationPreferences? prefs;
  final bool bellBusy;

  SavedSearch? matchedSavedSearch(ListingDiscoveryCriteria criteria) {
    return findSavedSearchMatchingCriteria(savedSearches, criteria);
  }

  bool deliveryFullyEnabledForCriteria(ListingDiscoveryCriteria criteria) {
    final match = matchedSavedSearch(criteria);
    final p = prefs;
    if (match == null || !match.alertsEnabled) return false;
    if (p == null || !p.globalEnabled || !p.filterAlertsEnabled) return false;
    return true;
  }

  bool get atSavedSearchCap =>
      savedSearches.length >= SavedSearchesLimits.maxPerUser;

  BrowseCatalogFilterAlertsState copyWith({
    BrowseCatalogFilterAlertsLoadPhase? phase,
    List<SavedSearch>? savedSearches,
    NotificationPreferences? prefs,
    bool? bellBusy,
    bool clearData = false,
  }) {
    return BrowseCatalogFilterAlertsState(
      phase: phase ?? this.phase,
      savedSearches: clearData
          ? const []
          : (savedSearches ?? this.savedSearches),
      prefs: clearData ? null : (prefs ?? this.prefs),
      bellBusy: bellBusy ?? this.bellBusy,
    );
  }

  @override
  List<Object?> get props => [phase, savedSearches, prefs, bellBusy];
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
    required ListSavedSearches listSavedSearches,
    required CreateSavedSearch createSavedSearch,
    required DeleteSavedSearch deleteSavedSearch,
    required NotificationsRepository notificationsRepository,
    required FilterAlertDeliveryOrchestrator deliveryOrchestrator,
  }) : _listSavedSearches = listSavedSearches,
       _createSavedSearch = createSavedSearch,
       _deleteSavedSearch = deleteSavedSearch,
       _notificationsRepository = notificationsRepository,
       _deliveryOrchestrator = deliveryOrchestrator,
       super(const BrowseCatalogFilterAlertsState());

  final ListSavedSearches _listSavedSearches;
  final CreateSavedSearch _createSavedSearch;
  final DeleteSavedSearch _deleteSavedSearch;
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

    final listRes = await _listSavedSearches();
    switch (listRes) {
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
            savedSearches: value,
            prefs: p,
          ),
        );
    }
  }

  bool catalogBellBadgeVisibleForApplied(ListingsState applied) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    final merged = listingDiscoveryCriteriaFromBrowseStateForAlert(applied);
    return state.deliveryFullyEnabledForCriteria(merged);
  }

  bool catalogBellSavedWithoutDeliveryVisibleForApplied(ListingsState applied) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    final merged = listingDiscoveryCriteriaFromBrowseStateForAlert(applied);
    final match = state.matchedSavedSearch(merged);
    if (match == null) return false;
    if (state.deliveryFullyEnabledForCriteria(merged)) return false;
    return true;
  }

  bool browseBellShowsActiveDraft(ListingDiscoveryCriteria draft) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    return state.deliveryFullyEnabledForCriteria(draft);
  }

  bool browseBellShowsSavedDraftWithoutDelivery(
    ListingDiscoveryCriteria draft,
  ) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    final match = state.matchedSavedSearch(draft);
    if (match == null) return false;
    if (state.deliveryFullyEnabledForCriteria(draft)) return false;
    return true;
  }

  Future<BrowseCatalogBellOutcome> handleCatalogFilterBell({
    required ListingDiscoveryCriteria draftCriteria,
    required bool authenticated,
    required String autoName,
  }) async {
    if (!authenticated) {
      return BrowseCatalogBellOutcome.signedOut;
    }
    if (!discoveryCriteriaEligibleForFilterAlertPersist(draftCriteria)) {
      return BrowseCatalogBellOutcome.criteriaTooBroad;
    }

    final matched = state.matchedSavedSearch(draftCriteria);
    final deliveryOn = state.deliveryFullyEnabledForCriteria(draftCriteria);

    emit(state.copyWith(bellBusy: true));
    try {
      if (matched != null) {
        final deleteResult = await _deleteSavedSearch(matched.id);
        switch (deleteResult) {
          case FailureResult():
            emit(state.copyWith(bellBusy: false));
            await refresh();
            if (kDebugMode) {
              debugPrint(
                '[catalogBell] outcome=savedAlertClearFailed '
                'deliveryWasOn=$deliveryOn',
              );
            }
            return BrowseCatalogBellOutcome.savedAlertClearFailed;
          case Success():
            emit(state.copyWith(bellBusy: false));
            await refresh();
            if (kDebugMode) {
              debugPrint('[catalogBell] outcome=savedAlertCleared');
            }
            return BrowseCatalogBellOutcome.savedAlertCleared;
        }
      }

      if (state.atSavedSearchCap) {
        emit(state.copyWith(bellBusy: false));
        return BrowseCatalogBellOutcome.maxSavedSearchesReached;
      }

      if (savedSearchesContainMatchingCriteria(
        state.savedSearches,
        draftCriteria,
      )) {
        emit(state.copyWith(bellBusy: false));
        return BrowseCatalogBellOutcome.noop;
      }

      if (!Env.pushNotificationsEnabled) {
        final save = await _createSavedSearch(
          name: autoName,
          criteria: draftCriteria,
          alertsEnabled: false,
        );
        switch (save) {
          case FailureResult(:final failure):
            emit(state.copyWith(bellBusy: false));
            if (failure.message == 'max_saved_searches_reached') {
              return BrowseCatalogBellOutcome.maxSavedSearchesReached;
            }
            if (failure.message == 'duplicate_saved_search') {
              await refresh();
              return BrowseCatalogBellOutcome.noop;
            }
            return BrowseCatalogBellOutcome.criteriaSaveFailed;
          case Success():
            break;
        }
        emit(state.copyWith(bellBusy: false));
        await refresh();
        return BrowseCatalogBellOutcome.criteriaSavedDeliveryUnavailable;
      }

      final save = await _createSavedSearch(
        name: autoName,
        criteria: draftCriteria,
        alertsEnabled: false,
      );
      late SavedSearch created;
      switch (save) {
        case FailureResult(:final failure):
          emit(state.copyWith(bellBusy: false));
          if (failure.message == 'max_saved_searches_reached') {
            return BrowseCatalogBellOutcome.maxSavedSearchesReached;
          }
          if (failure.message == 'duplicate_saved_search') {
            await refresh();
            return BrowseCatalogBellOutcome.noop;
          }
          return BrowseCatalogBellOutcome.criteriaSaveFailed;
        case Success(:final value):
          created = value;
          emit(state.copyWith(savedSearches: [...state.savedSearches, value]));
      }

      switch (await _deliveryOrchestrator.enableDeliveries(created)) {
        case FailureResult(:final failure):
          emit(state.copyWith(bellBusy: false));
          await refresh();
          if (failure.message == 'filter_alert_delivery_prefs_save_failed' ||
              failure.message == 'filter_alert_delivery_prefs_load_failed') {
            return BrowseCatalogBellOutcome.prefsOrRowFailed;
          }
          return _browseOutcomeFromEnableFailure(failure.message);
        case Success(:final value):
          final updated = state.savedSearches
              .map((s) => s.id == value.id ? value : s)
              .toList(growable: false);
          emit(state.copyWith(bellBusy: false, savedSearches: updated));
          await refresh();
          return BrowseCatalogBellOutcome.deliveriesEnabled;
      }
    } catch (_) {
      emit(state.copyWith(bellBusy: false));
      await refresh();
      return BrowseCatalogBellOutcome.prefsOrRowFailed;
    }
  }
}
