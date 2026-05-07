import '../../domain/entities/chat_message.dart';

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
  const ThreadMessageEntry(this.message);

  final ChatMessage message;
}

/// Builds [ThreadListEntry] list with a new header whenever the local date changes.
List<ThreadListEntry> buildThreadListEntries(List<ChatMessage> messages) {
  if (messages.isEmpty) return [];
  final out = <ThreadListEntry>[];
  DateTime? lastDay;
  for (final m in messages) {
    final local = m.createdAt.toLocal();
    final day = DateTime(local.year, local.month, local.day);
    if (lastDay == null || day != lastDay) {
      out.add(ThreadDateHeaderEntry(day));
      lastDay = day;
    }
    out.add(ThreadMessageEntry(m));
  }
  return out;
}
