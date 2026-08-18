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
  String? _observedUserId;
  String? _lastNavigatedListingId;
  DateTime? _lastNavigationTime;

  void ensureStarted() {
    if (_listening) {
      return;
    }
    _listening = true;
    _observedUserId = _authStateSnapshot().user?.id;
    _authSub = _authStateStream.listen((state) {
      final nextUserId = state.status == AuthStatus.authenticated
          ? state.user?.id
          : null;
      if (_observedUserId != nextUserId) {
        _observedUserId = nextUserId;
        _lastNavigatedListingId = null;
        _lastNavigationTime = null;
      }
    });
  }

  void requestOpenListing(String listingId) {
    // Listing details are public. Route immediately instead of retaining a
    // recipient-specific intent across an authentication boundary.
    _navigateWithDedup(listingId);
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
    _observedUserId = null;
    _lastNavigatedListingId = null;
    _lastNavigationTime = null;
  }
}
