import 'dart:async';

import '../../../core/utils/logger.dart';
import '../../auth/presentation/bloc/auth_state.dart';

/// Auth-aware routing for opening a message thread by [conversationId], shared
/// by remote-notification opens, local notification taps, etc.
class MessageConversationNavigationCoordinator {
  MessageConversationNavigationCoordinator({
    required Stream<AuthState> authStateStream,
    required AuthState Function() authStateSnapshot,
    required void Function(String conversationId) navigateToConversation,
    AppLogger? logger,
  }) : _authStateStream = authStateStream,
       _authStateSnapshot = authStateSnapshot,
       _navigateToConversation = navigateToConversation,
       _logger = logger ?? AppLogger('MessageConversationNav');

  final Stream<AuthState> _authStateStream;
  final AuthState Function() _authStateSnapshot;
  final void Function(String conversationId) _navigateToConversation;
  final AppLogger _logger;

  StreamSubscription<AuthState>? _authSub;
  bool _listening = false;
  String? _observedUserId;
  String? _lastNavigatedConversationId;
  DateTime? _lastNavigationTime;

  /// Subscribes to auth transitions once (idempotent).
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
        _lastNavigatedConversationId = null;
        _lastNavigationTime = null;
      }
    });
  }

  /// Entry point for any message thread navigation intent.
  void requestOpenThread(String conversationId) {
    final state = _authStateSnapshot();
    if (state.status == AuthStatus.authenticated && state.user != null) {
      _navigateWithDedup(conversationId);
    } else {
      // Conversation pushes are account-bound. Without a current authenticated
      // recipient context, discard instead of flushing under a future account.
      _logger.debug('Discarding account-bound notification navigation');
    }
  }

  void _navigateWithDedup(String conversationId) {
    final now = DateTime.now();
    if (_lastNavigatedConversationId == conversationId &&
        _lastNavigationTime != null &&
        now.difference(_lastNavigationTime!) < const Duration(seconds: 1)) {
      return;
    }
    _lastNavigatedConversationId = conversationId;
    _lastNavigationTime = now;
    try {
      _navigateToConversation(conversationId);
    } catch (e, st) {
      _logger.error('navigateToConversation failed', e, st);
    }
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    _authSub = null;
    _listening = false;
    _observedUserId = null;
    _lastNavigatedConversationId = null;
    _lastNavigationTime = null;
  }
}
