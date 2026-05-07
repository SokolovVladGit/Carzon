import 'package:equatable/equatable.dart';

import '../../domain/entities/chat_message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/messaging_failure_kind.dart';

enum ConversationThreadStatus { initial, loading, success, failure }

class ConversationThreadState extends Equatable {
  const ConversationThreadState({
    this.status = ConversationThreadStatus.initial,
    this.conversation,
    this.messages = const [],
    this.sending = false,
    this.failureKind,
    this.lastSendFailureKind,
    this.refreshFailureKind,
  });

  final ConversationThreadStatus status;
  final Conversation? conversation;
  final List<ChatMessage> messages;
  final bool sending;
  final MessagingFailureKind? failureKind;
  final MessagingFailureKind? lastSendFailureKind;

  /// Set when [ConversationThreadCubit.refresh] fails; cleared on success refresh.
  final MessagingFailureKind? refreshFailureKind;

  ConversationThreadState copyWith({
    ConversationThreadStatus? status,
    Conversation? conversation,
    List<ChatMessage>? messages,
    bool? sending,
    MessagingFailureKind? failureKind,
    bool clearFailureKind = false,
    MessagingFailureKind? lastSendFailureKind,
    bool clearLastSendFailure = false,
    MessagingFailureKind? refreshFailureKind,
    bool clearRefreshFailure = false,
  }) {
    return ConversationThreadState(
      status: status ?? this.status,
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      sending: sending ?? this.sending,
      failureKind: clearFailureKind ? null : (failureKind ?? this.failureKind),
      lastSendFailureKind: clearLastSendFailure
          ? null
          : (lastSendFailureKind ?? this.lastSendFailureKind),
      refreshFailureKind: clearRefreshFailure
          ? null
          : (refreshFailureKind ?? this.refreshFailureKind),
    );
  }

  @override
  List<Object?> get props => [
    status,
    conversation,
    messages,
    sending,
    failureKind,
    lastSendFailureKind,
    refreshFailureKind,
  ];
}
