import 'package:equatable/equatable.dart';

import '../../domain/entities/conversation.dart';
import '../../domain/messaging_failure_kind.dart';

enum MessagesInboxStatus { initial, loading, success, failure }

class MessagesInboxState extends Equatable {
  const MessagesInboxState({
    this.status = MessagesInboxStatus.initial,
    this.conversations = const [],
    this.failureKind,
  });

  final MessagesInboxStatus status;
  final List<Conversation> conversations;
  final MessagingFailureKind? failureKind;

  MessagesInboxState copyWith({
    MessagesInboxStatus? status,
    List<Conversation>? conversations,
    MessagingFailureKind? failureKind,
    bool clearFailureKind = false,
  }) {
    return MessagesInboxState(
      status: status ?? this.status,
      conversations: conversations ?? this.conversations,
      failureKind: clearFailureKind ? null : (failureKind ?? this.failureKind),
    );
  }

  @override
  List<Object?> get props => [status, conversations, failureKind];
}
