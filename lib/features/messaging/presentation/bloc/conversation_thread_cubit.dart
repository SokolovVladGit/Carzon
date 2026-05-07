import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../utils/messaging_failure_mapper.dart';
import 'conversation_thread_state.dart';

class ConversationThreadCubit extends Cubit<ConversationThreadState> {
  ConversationThreadCubit({
    required MessagingRepository repository,
    required String conversationId,
  }) : _repository = repository,
       _conversationId = conversationId,
       super(const ConversationThreadState());

  final MessagingRepository _repository;
  final String _conversationId;

  int _mainFetchDepth = 0;
  bool _silentFetchBusy = false;

  /// True while [load](showLoadingIndicator: false) runs after send success,
  /// so [silentRefresh] waits out the post-send pipeline without relying on
  /// [ConversationThreadState.sending] (which is cleared before reload).
  bool _sendReloadInFlight = false;

  bool get _mainFetchBusy => _mainFetchDepth > 0;

  void _enterMainFetch() => _mainFetchDepth++;
  void _leaveMainFetch() => _mainFetchDepth--;

  /// Loads conversation and messages. When [showLoadingIndicator] is false,
  /// keeps the current UI (e.g. after send) instead of flipping to loading.
  Future<void> load({bool showLoadingIndicator = true}) async {
    if (showLoadingIndicator) {
      emit(
        state.copyWith(
          status: ConversationThreadStatus.loading,
          clearFailureKind: true,
          clearLastSendFailure: true,
          clearRefreshFailure: true,
        ),
      );
    } else {
      emit(
        state.copyWith(
          clearFailureKind: true,
          clearLastSendFailure: true,
          clearRefreshFailure: true,
        ),
      );
    }

    await _fetchAndEmit();
  }

  Future<void> _fetchAndEmit() async {
    _enterMainFetch();
    try {
      final convResult = await _repository.getConversation(_conversationId);
      switch (convResult) {
        case FailureResult(:final failure):
          emit(
            state.copyWith(
              status: ConversationThreadStatus.failure,
              failureKind: messagingFailureKindFrom(failure),
            ),
          );
        case Success(:final value):
          final conv = value;
          final msgResult = await _repository.getMessages(_conversationId);
          switch (msgResult) {
            case FailureResult(:final failure):
              emit(
                state.copyWith(
                  status: ConversationThreadStatus.failure,
                  conversation: conv,
                  failureKind: messagingFailureKindFrom(failure),
                ),
              );
            case Success(:final value):
              emit(
                ConversationThreadState(
                  status: ConversationThreadStatus.success,
                  conversation: conv,
                  messages: value,
                ),
              );
          }
      }
    } finally {
      _leaveMainFetch();
    }
  }

  /// Pull-to-refresh: reload without full-screen loading when already showing
  /// messages; surfaces failures via [ConversationThreadState.refreshFailureKind].
  Future<void> refresh() async {
    if (state.status != ConversationThreadStatus.success) {
      await load();
      return;
    }
    final conv = state.conversation;
    if (conv == null) {
      await load();
      return;
    }

    emit(state.copyWith(clearRefreshFailure: true));

    _enterMainFetch();
    try {
      final convResult = await _repository.getConversation(_conversationId);
      switch (convResult) {
        case FailureResult(:final failure):
          emit(
            state.copyWith(
              refreshFailureKind: messagingFailureKindFrom(failure),
            ),
          );
        case Success(:final value):
          final updatedConv = value;
          final msgResult = await _repository.getMessages(_conversationId);
          switch (msgResult) {
            case FailureResult(:final failure):
              emit(
                state.copyWith(
                  refreshFailureKind: messagingFailureKindFrom(failure),
                ),
              );
            case Success(:final value):
              emit(
                state.copyWith(
                  conversation: updatedConv,
                  messages: value,
                  clearRefreshFailure: true,
                ),
              );
          }
      }
    } finally {
      _leaveMainFetch();
    }
  }

  /// Periodic background refresh: same reads as [refresh], no loading state,
  /// no [refreshFailureKind], no user-visible failure.
  Future<void> silentRefresh() async {
    if (state.status != ConversationThreadStatus.success) return;
    if (state.conversation == null) return;
    if (state.sending || _sendReloadInFlight) return;
    if (_mainFetchBusy) return;
    if (_silentFetchBusy) return;

    _silentFetchBusy = true;
    try {
      final convResult = await _repository.getConversation(_conversationId);
      switch (convResult) {
        case FailureResult():
          return;
        case Success(:final value):
          final updatedConv = value;
          final msgResult = await _repository.getMessages(_conversationId);
          switch (msgResult) {
            case FailureResult():
              return;
            case Success(:final value):
              if (!isClosed) {
                emit(
                  state.copyWith(
                    conversation: updatedConv,
                    messages: value,
                    clearRefreshFailure: true,
                  ),
                );
              }
          }
      }
    } finally {
      _silentFetchBusy = false;
    }
  }

  Future<void> send(String rawBody) async {
    final body = rawBody.trim();
    if (body.isEmpty || state.sending) return;

    emit(state.copyWith(sending: true, clearLastSendFailure: true));
    final result = await _repository.sendMessage(_conversationId, body);
    switch (result) {
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            sending: false,
            lastSendFailureKind: messagingFailureKindFrom(failure),
            clearLastSendFailure: false,
          ),
        );
      case Success():
        emit(state.copyWith(sending: false));
        _sendReloadInFlight = true;
        try {
          await load(showLoadingIndicator: false);
        } finally {
          _sendReloadInFlight = false;
        }
    }
  }
}
