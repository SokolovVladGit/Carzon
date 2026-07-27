import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/env.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../filter_alerts/domain/entities/saved_search.dart';
import '../../../filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import '../../../filter_alerts/domain/usecases/create_saved_search.dart';
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
    if (!Env.pushNotificationsEnabled) return false;
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
    filterAlertDeliverySessionStale => BrowseCatalogBellOutcome.noop,
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
    required NotificationsRepository notificationsRepository,
    required FilterAlertDeliveryOrchestrator deliveryOrchestrator,
  }) : _listSavedSearches = listSavedSearches,
       _createSavedSearch = createSavedSearch,
       _notificationsRepository = notificationsRepository,
       _deliveryOrchestrator = deliveryOrchestrator,
       super(const BrowseCatalogFilterAlertsState());

  final ListSavedSearches _listSavedSearches;
  final CreateSavedSearch _createSavedSearch;
  final NotificationsRepository _notificationsRepository;
  final FilterAlertDeliveryOrchestrator _deliveryOrchestrator;

  String? _currentUserId;
  bool _hasSynchronizedAuth = false;
  int _sessionGeneration = 0;
  int _refreshGeneration = 0;

  Future<void> onAuthChanged(AuthState auth) async {
    if (isClosed) return;
    final userId = auth.status == AuthStatus.authenticated
        ? auth.user?.id
        : null;
    final firstSynchronization = !_hasSynchronizedAuth;
    final userChanged = !firstSynchronization && userId != _currentUserId;
    final sessionChanged = firstSynchronization || userChanged;
    if (sessionChanged) {
      _hasSynchronizedAuth = true;
      _currentUserId = userId;
      _sessionGeneration += 1;
      _refreshGeneration += 1;
      if (isClosed) return;
      if (userId == null || userChanged) {
        emit(
          const BrowseCatalogFilterAlertsState(
            phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          ),
        );
      }
    }

    if (userId != null) {
      final sessionGeneration = _sessionGeneration;
      try {
        await refresh();
      } catch (_) {
        if (_isCurrentSession(userId, sessionGeneration)) {
          emit(
            state.copyWith(
              phase: BrowseCatalogFilterAlertsLoadPhase.failure,
              bellBusy: false,
            ),
          );
        }
      }
    }
  }

  Future<void> refresh() async {
    if (isClosed) return;
    final userId = _currentUserId;
    if (userId == null) return;
    final sessionGeneration = _sessionGeneration;
    final refreshGeneration = ++_refreshGeneration;
    emit(
      state.copyWith(
        phase: BrowseCatalogFilterAlertsLoadPhase.loading,
        bellBusy: false,
      ),
    );
    final prefsRes = await _notificationsRepository.getMyPreferences();
    if (!_isCurrentRefresh(userId, sessionGeneration, refreshGeneration)) {
      return;
    }
    NotificationPreferences? p;
    switch (prefsRes) {
      case FailureResult():
        p = null;
      case Success(:final value):
        p = value;
    }

    final listRes = await _listSavedSearches();
    if (!_isCurrentRefresh(userId, sessionGeneration, refreshGeneration)) {
      return;
    }
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

  bool browseBellShowsActiveDraft(ListingDiscoveryCriteria draft) {
    if (state.phase != BrowseCatalogFilterAlertsLoadPhase.ready) return false;
    return state.deliveryFullyEnabledForCriteria(draft);
  }

  /// Catalog bell enables/disables filter-alert delivery for matching criteria.
  /// Saved-search deletion is managed on the Saved Searches page only.
  Future<BrowseCatalogBellOutcome> handleCatalogFilterBell({
    required ListingDiscoveryCriteria draftCriteria,
    required bool authenticated,
    required String autoName,
  }) async {
    if (isClosed) return BrowseCatalogBellOutcome.noop;
    final userId = _currentUserId;
    if (!authenticated || userId == null) {
      return BrowseCatalogBellOutcome.signedOut;
    }
    final sessionGeneration = _sessionGeneration;
    if (!discoveryCriteriaEligibleForFilterAlertPersist(draftCriteria)) {
      return BrowseCatalogBellOutcome.criteriaTooBroad;
    }

    final matched = state.matchedSavedSearch(draftCriteria);
    final deliveryOn = state.deliveryFullyEnabledForCriteria(draftCriteria);

    emit(state.copyWith(bellBusy: true));
    try {
      if (deliveryOn && matched != null) {
        final disableResult = await _deliveryOrchestrator.disableDeliveries(
          matched,
        );
        if (!_isCurrentSession(userId, sessionGeneration)) {
          return BrowseCatalogBellOutcome.noop;
        }
        switch (disableResult) {
          case FailureResult():
            emit(state.copyWith(bellBusy: false));
            await refresh();
            if (!_isCurrentSession(userId, sessionGeneration)) {
              return BrowseCatalogBellOutcome.noop;
            }
            return BrowseCatalogBellOutcome.prefsOrRowFailed;
          case Success():
            emit(state.copyWith(bellBusy: false));
            await refresh();
            if (!_isCurrentSession(userId, sessionGeneration)) {
              return BrowseCatalogBellOutcome.noop;
            }
            if (kDebugMode) {
              debugPrint('[catalogBell] outcome=deliveriesDisabled');
            }
            return BrowseCatalogBellOutcome.deliveriesDisabled;
        }
      }

      if (matched != null) {
        if (!Env.pushNotificationsEnabled) {
          emit(state.copyWith(bellBusy: false));
          return BrowseCatalogBellOutcome.criteriaSavedDeliveryUnavailable;
        }

        switch (await _deliveryOrchestrator.enableDeliveries(
          matched,
          sessionGuard: _deliverySessionGuard(userId, sessionGeneration),
        )) {
          case FailureResult(:final failure):
            if (!_isCurrentSession(userId, sessionGeneration)) {
              return BrowseCatalogBellOutcome.noop;
            }
            emit(state.copyWith(bellBusy: false));
            await refresh();
            if (!_isCurrentSession(userId, sessionGeneration)) {
              return BrowseCatalogBellOutcome.noop;
            }
            if (failure.message == 'filter_alert_delivery_prefs_save_failed' ||
                failure.message == 'filter_alert_delivery_prefs_load_failed') {
              return BrowseCatalogBellOutcome.prefsOrRowFailed;
            }
            return _browseOutcomeFromEnableFailure(failure.message);
          case Success(:final value):
            if (!_isCurrentSession(userId, sessionGeneration)) {
              return BrowseCatalogBellOutcome.noop;
            }
            final updated = state.savedSearches
                .map((s) => s.id == value.id ? value : s)
                .toList(growable: false);
            emit(state.copyWith(bellBusy: false, savedSearches: updated));
            await refresh();
            if (!_isCurrentSession(userId, sessionGeneration)) {
              return BrowseCatalogBellOutcome.noop;
            }
            return BrowseCatalogBellOutcome.deliveriesEnabled;
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
        if (!_isCurrentSession(userId, sessionGeneration)) {
          return BrowseCatalogBellOutcome.noop;
        }
        switch (save) {
          case FailureResult(:final failure):
            emit(state.copyWith(bellBusy: false));
            if (failure.message == 'max_saved_searches_reached') {
              return BrowseCatalogBellOutcome.maxSavedSearchesReached;
            }
            if (failure.message == 'duplicate_saved_search') {
              await refresh();
              if (!_isCurrentSession(userId, sessionGeneration)) {
                return BrowseCatalogBellOutcome.noop;
              }
              return BrowseCatalogBellOutcome.noop;
            }
            return BrowseCatalogBellOutcome.criteriaSaveFailed;
          case Success():
            break;
        }
        emit(state.copyWith(bellBusy: false));
        await refresh();
        if (!_isCurrentSession(userId, sessionGeneration)) {
          return BrowseCatalogBellOutcome.noop;
        }
        return BrowseCatalogBellOutcome.criteriaSavedDeliveryUnavailable;
      }

      final save = await _createSavedSearch(
        name: autoName,
        criteria: draftCriteria,
        alertsEnabled: false,
      );
      if (!_isCurrentSession(userId, sessionGeneration)) {
        return BrowseCatalogBellOutcome.noop;
      }
      late SavedSearch created;
      switch (save) {
        case FailureResult(:final failure):
          emit(state.copyWith(bellBusy: false));
          if (failure.message == 'max_saved_searches_reached') {
            return BrowseCatalogBellOutcome.maxSavedSearchesReached;
          }
          if (failure.message == 'duplicate_saved_search') {
            await refresh();
            if (!_isCurrentSession(userId, sessionGeneration)) {
              return BrowseCatalogBellOutcome.noop;
            }
            return BrowseCatalogBellOutcome.noop;
          }
          return BrowseCatalogBellOutcome.criteriaSaveFailed;
        case Success(:final value):
          created = value;
          emit(state.copyWith(savedSearches: [...state.savedSearches, value]));
      }

      switch (await _deliveryOrchestrator.enableDeliveries(
        created,
        sessionGuard: _deliverySessionGuard(userId, sessionGeneration),
      )) {
        case FailureResult(:final failure):
          if (!_isCurrentSession(userId, sessionGeneration)) {
            return BrowseCatalogBellOutcome.noop;
          }
          emit(state.copyWith(bellBusy: false));
          await refresh();
          if (!_isCurrentSession(userId, sessionGeneration)) {
            return BrowseCatalogBellOutcome.noop;
          }
          if (failure.message == 'filter_alert_delivery_prefs_save_failed' ||
              failure.message == 'filter_alert_delivery_prefs_load_failed') {
            return BrowseCatalogBellOutcome.prefsOrRowFailed;
          }
          return _browseOutcomeFromEnableFailure(failure.message);
        case Success(:final value):
          if (!_isCurrentSession(userId, sessionGeneration)) {
            return BrowseCatalogBellOutcome.noop;
          }
          final updated = state.savedSearches
              .map((s) => s.id == value.id ? value : s)
              .toList(growable: false);
          emit(state.copyWith(bellBusy: false, savedSearches: updated));
          await refresh();
          if (!_isCurrentSession(userId, sessionGeneration)) {
            return BrowseCatalogBellOutcome.noop;
          }
          return BrowseCatalogBellOutcome.deliveriesEnabled;
      }
    } catch (_) {
      if (!_isCurrentSession(userId, sessionGeneration)) {
        return BrowseCatalogBellOutcome.noop;
      }
      emit(state.copyWith(bellBusy: false));
      await refresh();
      if (!_isCurrentSession(userId, sessionGeneration)) {
        return BrowseCatalogBellOutcome.noop;
      }
      return BrowseCatalogBellOutcome.prefsOrRowFailed;
    }
  }

  bool _isCurrentSession(String userId, int sessionGeneration) {
    return !isClosed &&
        _currentUserId == userId &&
        _sessionGeneration == sessionGeneration;
  }

  FilterAlertDeliverySessionGuard _deliverySessionGuard(
    String userId,
    int sessionGeneration,
  ) {
    return FilterAlertDeliverySessionGuard(
      expectedUserId: userId,
      isSessionCurrent: () => _isCurrentSession(userId, sessionGeneration),
    );
  }

  bool _isCurrentRefresh(
    String userId,
    int sessionGeneration,
    int refreshGeneration,
  ) {
    return _isCurrentSession(userId, sessionGeneration) &&
        _refreshGeneration == refreshGeneration;
  }
}
