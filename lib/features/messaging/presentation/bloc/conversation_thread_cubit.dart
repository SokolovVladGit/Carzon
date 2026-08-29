import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../../../core/errors/content_moderation_failure.dart';
import '../../domain/entities/chat_attachment_upload.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/entities/user_report_reason.dart';
import '../../domain/messaging_failure_kind.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../../domain/utils/conversation_peer.dart';
import '../utils/messaging_failure_mapper.dart';
import 'conversation_thread_state.dart';

class ConversationThreadCubit extends Cubit<ConversationThreadState> {
  ConversationThreadCubit({
    required MessagingRepository repository,
    required String conversationId,
    required String currentUserId,
    Future<void> Function()? onReadReceiptSynced,
  }) : _repository = repository,
       _conversationId = conversationId,
       _currentUserId = currentUserId,
       _onReadReceiptSynced = onReadReceiptSynced,
       super(const ConversationThreadState());

  final MessagingRepository _repository;
  final String _conversationId;
  final String _currentUserId;
  final Future<void> Function()? _onReadReceiptSynced;

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
                  peerBlockedByMe: state.peerBlockedByMe,
                  messagingUnavailable: state.messagingUnavailable,
                ),
              );
              unawaited(_touchReadReceiptSilently());
              unawaited(_syncPeerBlockedByMe(conv));
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
              unawaited(_touchReadReceiptSilently());
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
              final nextMsgs = value;
              final prevMsgs = state.messages;
              if (!isClosed) {
                emit(
                  state.copyWith(
                    conversation: updatedConv,
                    messages: nextMsgs,
                    clearRefreshFailure: true,
                  ),
                );
                if (_messagesUnreadCursorMoved(prevMsgs, nextMsgs)) {
                  unawaited(_touchReadReceiptSilently());
                }
              }
          }
      }
    } finally {
      _silentFetchBusy = false;
    }
  }

  bool _messagesUnreadCursorMoved(
    List<ChatMessage> previous,
    List<ChatMessage> next,
  ) {
    if (previous.length != next.length) return true;
    if (previous.isEmpty) return false;
    if (next.isEmpty) return false;
    return previous.last.id != next.last.id;
  }

  Future<void> _touchReadReceiptSilently() async {
    final markResult = await _repository.markConversationRead(_conversationId);
    if (!isClosed) {
      switch (markResult) {
        case Success():
          final notify = _onReadReceiptSynced;
          if (notify != null) {
            try {
              await notify();
            } catch (_) {
              // Badge refresh must never break thread UI.
            }
          }
        case FailureResult():
          break;
      }
    }
  }

  Future<void> send(String rawBody) async {
    final body = rawBody.trim();
    if (body.isEmpty || state.sending) return;

    emit(state.copyWith(sending: true, clearLastSendFailure: true));
    final result = await _repository.sendMessage(_conversationId, body);
    switch (result) {
      case FailureResult(:final failure):
        final kind = messagingFailureKindFrom(failure);
        emit(
          state.copyWith(
            sending: false,
            lastSendFailureKind: kind,
            clearLastSendFailure: false,
            messagingUnavailable:
                kind == MessagingFailureKind.messagingBlocked ||
                state.messagingUnavailable,
          ),
        );
      case Success<String>():
        emit(state.copyWith(sending: false));
        _sendReloadInFlight = true;
        try {
          await load(showLoadingIndicator: false);
        } finally {
          _sendReloadInFlight = false;
        }
    }
  }

  Future<void> sendMessageWithAttachment(ChatAttachmentUpload upload) async {
    if (state.sending) return;

    emit(state.copyWith(sending: true, clearLastSendFailure: true));
    final result = await _repository.sendMessageWithAttachment(upload);
    switch (result) {
      case FailureResult(:final failure):
        final kind = messagingFailureKindFrom(failure);
        emit(
          state.copyWith(
            sending: false,
            lastSendFailureKind: kind,
            clearLastSendFailure: false,
            messagingUnavailable:
                kind == MessagingFailureKind.messagingBlocked ||
                state.messagingUnavailable,
          ),
        );
      case Success<String>():
        emit(state.copyWith(sending: false));
        _sendReloadInFlight = true;
        try {
          await load(showLoadingIndicator: false);
        } finally {
          _sendReloadInFlight = false;
        }
    }
  }

  Future<Uint8List?> downloadAttachmentBytes(String storagePath) async {
    final result = await _repository.downloadChatAttachmentBytes(storagePath);
    switch (result) {
      case Success(:final value):
        return Uint8List.fromList(value);
      case FailureResult():
        return null;
    }
  }

  Future<bool> blockPeer() async {
    if (state.blockActionInProgress || state.peerBlockedByMe) return false;
    emit(state.copyWith(blockActionInProgress: true));
    final result = await _repository.blockUser(_conversationId);
    switch (result) {
      case FailureResult():
        emit(state.copyWith(blockActionInProgress: false));
        return false;
      case Success():
        emit(
          state.copyWith(
            blockActionInProgress: false,
            peerBlockedByMe: true,
            messagingUnavailable: false,
          ),
        );
        return true;
    }
  }

  Future<bool> reportPeer({
    required UserReportReason reason,
    String? note,
  }) async {
    if (state.reportActionInProgress) return false;
    emit(
      state.copyWith(
        reportActionInProgress: true,
        lastReportContentRejected: false,
      ),
    );
    final result = await _repository.reportUser(
      conversationId: _conversationId,
      reason: reason,
      note: note,
    );
    switch (result) {
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            reportActionInProgress: false,
            lastReportContentRejected: isContentRejectedFailure(failure),
          ),
        );
        return false;
      case Success():
        emit(
          state.copyWith(
            reportActionInProgress: false,
            lastReportContentRejected: false,
          ),
        );
        return true;
    }
  }

  Future<void> _syncPeerBlockedByMe(Conversation conv) async {
    if (conv.isSupportConversation) return;
    final peerId = conversationPeerUserId(conv, _currentUserId);
    if (peerId == null) return;

    final result = await _repository.listBlockedUsers();
    if (isClosed) return;
    switch (result) {
      case FailureResult():
        return;
      case Success(:final value):
        final blocked = value.any((row) => row.blockedUserId == peerId);
        emit(state.copyWith(peerBlockedByMe: blocked));
    }
  }
}
