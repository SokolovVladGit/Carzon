import 'dart:async';

import '../../../core/utils/logger.dart';
import '../../auth/presentation/bloc/auth_state.dart';

/// Auth-aware routing to listing details by [listingId] (filter-alert taps).
class FilterAlertListingNavigationCoordinator {
  FilterAlertListingNavigationCoordinator({
    required Stream<AuthState> authStateStream,
    required AuthState Function() authStateSnapshot,
    required void Function(String listingId) navigateToListingDetail,
    AppLogger? logger,
  }) : _authStateStream = authStateStream,
       _authStateSnapshot = authStateSnapshot,
       _navigateToListingDetail = navigateToListingDetail,
       _logger = logger ?? AppLogger('FilterAlertListingNav');

  final Stream<AuthState> _authStateStream;
  final AuthState Function() _authStateSnapshot;
  final void Function(String listingId) _navigateToListingDetail;
  final AppLogger _logger;

  StreamSubscription<AuthState>? _authSub;
  bool _listening = false;
  String? _pendingListingId;
  String? _lastNavigatedListingId;
  DateTime? _lastNavigationTime;

  void ensureStarted() {
    if (_listening) {
      return;
    }
    _listening = true;
    _authSub = _authStateStream.listen((_) => _tryFlushPending());
  }

  void requestOpenListing(String listingId) {
    final state = _authStateSnapshot();
    if (state.status == AuthStatus.authenticated && state.user != null) {
      _navigateWithDedup(listingId);
    } else {
      _pendingListingId = listingId;
    }
  }

  void _tryFlushPending() {
    final pending = _pendingListingId;
    if (pending == null) {
      return;
    }
    final state = _authStateSnapshot();
    if (state.status != AuthStatus.authenticated || state.user == null) {
      return;
    }
    _pendingListingId = null;
    _navigateWithDedup(pending);
  }

  void _navigateWithDedup(String listingId) {
    final now = DateTime.now();
    if (_lastNavigatedListingId == listingId &&
        _lastNavigationTime != null &&
        now.difference(_lastNavigationTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastNavigatedListingId = listingId;
    _lastNavigationTime = now;
    try {
      _navigateToListingDetail(listingId);
    } catch (e, st) {
      _logger.error('navigateToListingDetail failed', e, st);
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    _listening = false;
    _pendingListingId = null;
    _lastNavigatedListingId = null;
    _lastNavigationTime = null;
  }
}
