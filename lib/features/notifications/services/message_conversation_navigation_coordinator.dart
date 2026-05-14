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
  String? _pendingConversationId;
  String? _lastNavigatedConversationId;
  DateTime? _lastNavigationTime;

  /// Subscribes to auth transitions once (idempotent).
  void ensureStarted() {
    if (_listening) {
      return;
    }
    _listening = true;
    _authSub = _authStateStream.listen((_) => _tryFlushPending());
  }

  /// Entry point for any message thread navigation intent.
  void requestOpenThread(String conversationId) {
    final state = _authStateSnapshot();
    if (state.status == AuthStatus.authenticated && state.user != null) {
      _navigateWithDedup(conversationId);
    } else {
      _pendingConversationId = conversationId;
    }
  }

  void _tryFlushPending() {
    final pending = _pendingConversationId;
    if (pending == null) {
      return;
    }
    final state = _authStateSnapshot();
    if (state.status != AuthStatus.authenticated || state.user == null) {
      return;
    }
    _pendingConversationId = null;
    _navigateWithDedup(pending);
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
    _pendingConversationId = null;
    _lastNavigatedConversationId = null;
    _lastNavigationTime = null;
  }
}
