import 'package:equatable/equatable.dart';

enum MessagingUnreadSummaryPhase { initial, loading, loaded, failure }

/// Global unread-thread summary for menu/listings badges and Profile activity row.
///
/// [unreadConversationCount] is the last server-authoritative value from a
/// successful [getUnreadConversationCount] while authenticated. It is preserved
/// across [MessagingUnreadSummaryPhase.loading] and
/// [MessagingUnreadSummaryPhase.failure] so UI can stay fail-closed without
/// treating RPC errors as a definitive “zero unread”.
class MessagingUnreadSummaryState extends Equatable {
  const MessagingUnreadSummaryState({
    required this.phase,
    this.unreadConversationCount = 0,
  });

  final MessagingUnreadSummaryPhase phase;
  final int unreadConversationCount;

  bool get hasLoadError => phase == MessagingUnreadSummaryPhase.failure;

  bool get hasUnread => unreadConversationCount > 0;

  /// Dot / numeric badge: show only when we have a positive preserved count and
  /// are not in the uninitialized [initial] phase (includes [loading] to avoid
  /// flicker while refreshing).
  bool get shouldShowUnreadIndicator =>
      unreadConversationCount > 0 &&
      (phase == MessagingUnreadSummaryPhase.loading ||
          phase == MessagingUnreadSummaryPhase.loaded ||
          phase == MessagingUnreadSummaryPhase.failure);

  MessagingUnreadSummaryState copyWith({
    MessagingUnreadSummaryPhase? phase,
    int? unreadConversationCount,
  }) {
    return MessagingUnreadSummaryState(
      phase: phase ?? this.phase,
      unreadConversationCount:
          unreadConversationCount ?? this.unreadConversationCount,
    );
  }

  @override
  List<Object?> get props => [phase, unreadConversationCount];
}
