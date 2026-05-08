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

  Future<void> sync(AuthState auth) async {
    if (auth.status != AuthStatus.authenticated || auth.user == null) {
      emit(
        const MessagingUnreadSummaryState(
          phase: MessagingUnreadSummaryPhase.loaded,
          unreadConversationCount: 0,
        ),
      );
      return;
    }

    emit(
      state.copyWith(phase: MessagingUnreadSummaryPhase.loading),
    );

    final result = await _repository.getUnreadConversationCount();
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
}
