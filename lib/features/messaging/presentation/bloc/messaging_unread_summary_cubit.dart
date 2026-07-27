import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/messaging_repository.dart';
import 'messaging_unread_summary_state.dart';

/// Unread conversation summary for global badges (listings masthead, profile).
///
/// Failures use [MessagingUnreadSummaryPhase.failure] while preserving the last
/// successful count so callers can distinguish RPC errors from a definitive zero.
class MessagingUnreadSummaryCubit extends Cubit<MessagingUnreadSummaryState> {
  MessagingUnreadSummaryCubit(this._repository)
    : super(
        const MessagingUnreadSummaryState(
          phase: MessagingUnreadSummaryPhase.initial,
        ),
      );

  final MessagingRepository _repository;

  String? _currentUserId;
  bool _hasSynchronizedAuth = false;
  int _sessionGeneration = 0;
  int _syncGeneration = 0;

  Future<void> sync(AuthState auth) async {
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
      _syncGeneration += 1;
      if (isClosed) return;
      if (userId == null || userChanged) {
        emit(
          const MessagingUnreadSummaryState(
            phase: MessagingUnreadSummaryPhase.loaded,
            unreadConversationCount: 0,
          ),
        );
      }
    }

    if (userId == null) {
      return;
    }

    final sessionGeneration = _sessionGeneration;
    final syncGeneration = ++_syncGeneration;
    emit(state.copyWith(phase: MessagingUnreadSummaryPhase.loading));

    final result = await _repository.getUnreadConversationCount();
    if (!_isCurrentSync(userId, sessionGeneration, syncGeneration)) return;
    switch (result) {
      case FailureResult():
        emit(
          MessagingUnreadSummaryState(
            phase: MessagingUnreadSummaryPhase.failure,
            unreadConversationCount: state.unreadConversationCount,
          ),
        );
      case Success(:final value):
        final n = value < 0 ? 0 : value;
        emit(
          MessagingUnreadSummaryState(
            phase: MessagingUnreadSummaryPhase.loaded,
            unreadConversationCount: n,
          ),
        );
    }
  }

  bool _isCurrentSync(
    String userId,
    int sessionGeneration,
    int syncGeneration,
  ) {
    return !isClosed &&
        _currentUserId == userId &&
        _sessionGeneration == sessionGeneration &&
        _syncGeneration == syncGeneration;
  }
}
