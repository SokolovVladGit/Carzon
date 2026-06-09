import '../../domain/entities/chat_message.dart';
import 'message_bubble_group_position.dart';

/// Max gap between consecutive messages from the same sender to visually group.
const Duration kMessageBubbleGroupMaxGap = Duration(minutes: 3);

/// Flattened row for thread [ListView]: date headers alternate with messages.
sealed class ThreadListEntry {
  const ThreadListEntry();
}

/// Local calendar day start (year, month, day) for grouping.
final class ThreadDateHeaderEntry extends ThreadListEntry {
  const ThreadDateHeaderEntry(this.dayStart);

  /// Midnight local time for the message day.
  final DateTime dayStart;
}

final class ThreadMessageEntry extends ThreadListEntry {
  const ThreadMessageEntry(
    this.message, {
    this.groupPosition = MessageBubbleGroupPosition.single,
    this.showTimestamp = true,
  });

  final ChatMessage message;
  final MessageBubbleGroupPosition groupPosition;
  final bool showTimestamp;
}

bool _messagesGrouped(ChatMessage earlier, ChatMessage later) {
  if (earlier.senderId != later.senderId) return false;
  final gap = later.createdAt.difference(earlier.createdAt);
  return !gap.isNegative && gap <= kMessageBubbleGroupMaxGap;
}

MessageBubbleGroupPosition _groupPosition({
  required bool groupedWithPrevious,
  required bool groupedWithNext,
}) {
  if (!groupedWithPrevious && !groupedWithNext) {
    return MessageBubbleGroupPosition.single;
  }
  if (!groupedWithPrevious && groupedWithNext) {
    return MessageBubbleGroupPosition.first;
  }
  if (groupedWithPrevious && groupedWithNext) {
    return MessageBubbleGroupPosition.middle;
  }
  return MessageBubbleGroupPosition.last;
}

/// Builds [ThreadListEntry] list with a new header whenever the local date changes.
List<ThreadListEntry> buildThreadListEntries(List<ChatMessage> messages) {
  if (messages.isEmpty) return [];
  final out = <ThreadListEntry>[];
  DateTime? lastDay;
  for (var i = 0; i < messages.length; i++) {
    final m = messages[i];
    final local = m.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (lastDay == null || day != lastDay) {
      out.add(ThreadDateHeaderEntry(day));
      lastDay = day;
    }

    final previous = i > 0 ? messages[i - 1] : null;
    final next = i < messages.length - 1 ? messages[i + 1] : null;
    final groupedWithPrevious =
        previous != null && _messagesGrouped(previous, m);
    final groupedWithNext = next != null && _messagesGrouped(m, next);
    final groupPosition = _groupPosition(
      groupedWithPrevious: groupedWithPrevious,
      groupedWithNext: groupedWithNext,
    );

    out.add(
      ThreadMessageEntry(
        m,
        groupPosition: groupPosition,
        showTimestamp: !groupedWithNext,
      ),
    );
  }
  return out;
}
