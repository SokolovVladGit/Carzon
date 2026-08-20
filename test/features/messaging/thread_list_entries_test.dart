import 'package:carzon/features/messaging/domain/entities/chat_message.dart';
import 'package:carzon/features/messaging/presentation/utils/message_bubble_group_position.dart';
import 'package:carzon/features/messaging/presentation/utils/thread_list_entries.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final base = DateTime.utc(2026, 5, 2, 10);

  ChatMessage message({
    required String id,
    required String senderId,
    required DateTime createdAt,
    String body = 'hi',
  }) => ChatMessage(
    id: id,
    conversationId: 'conv-1',
    senderId: senderId,
    body: body,
    createdAt: createdAt,
  );

  test(
    'grouped outgoing messages preserve positions and all show timestamps',
    () {
      final messages = [
        message(id: 'm1', senderId: 'u1', createdAt: base),
        message(
          id: 'm2',
          senderId: 'u1',
          createdAt: base.add(const Duration(minutes: 1)),
        ),
        message(
          id: 'm3',
          senderId: 'u1',
          createdAt: base.add(const Duration(minutes: 2)),
        ),
        message(
          id: 'm4',
          senderId: 'u2',
          createdAt: base.add(const Duration(minutes: 3)),
        ),
      ];

      final entries = buildThreadListEntries(messages);
      final messageEntries = entries.whereType<ThreadMessageEntry>().toList();

      expect(messageEntries, hasLength(4));
      expect(messageEntries[0].groupPosition, MessageBubbleGroupPosition.first);
      expect(messageEntries[0].showTimestamp, isTrue);
      expect(
        messageEntries[1].groupPosition,
        MessageBubbleGroupPosition.middle,
      );
      expect(messageEntries[1].showTimestamp, isTrue);
      expect(messageEntries[2].groupPosition, MessageBubbleGroupPosition.last);
      expect(messageEntries[2].showTimestamp, isTrue);
      expect(
        messageEntries[3].groupPosition,
        MessageBubbleGroupPosition.single,
      );
      expect(messageEntries[3].showTimestamp, isTrue);
    },
  );

  test('grouped incoming messages all show timestamps', () {
    final messages = [
      message(id: 'm1', senderId: 'peer', createdAt: base),
      message(
        id: 'm2',
        senderId: 'peer',
        createdAt: base.add(const Duration(minutes: 1)),
      ),
    ];

    final entries = buildThreadListEntries(
      messages,
    ).whereType<ThreadMessageEntry>().toList();

    expect(entries[0].groupPosition, MessageBubbleGroupPosition.first);
    expect(entries[1].groupPosition, MessageBubbleGroupPosition.last);
    expect(entries.every((e) => e.showTimestamp), isTrue);
  });

  test('alternating senders remain single and all show timestamps', () {
    final messages = [
      message(id: 'm1', senderId: 'u1', createdAt: base),
      message(
        id: 'm2',
        senderId: 'peer',
        createdAt: base.add(const Duration(minutes: 1)),
      ),
      message(
        id: 'm3',
        senderId: 'u1',
        createdAt: base.add(const Duration(minutes: 2)),
      ),
    ];

    final entries = buildThreadListEntries(
      messages,
    ).whereType<ThreadMessageEntry>().toList();

    expect(
      entries.every(
        (e) => e.groupPosition == MessageBubbleGroupPosition.single,
      ),
      isTrue,
    );
    expect(entries.every((e) => e.showTimestamp), isTrue);
  });

  test('does not group messages separated by more than three minutes', () {
    final messages = [
      message(id: 'm1', senderId: 'u1', createdAt: base),
      message(
        id: 'm2',
        senderId: 'u1',
        createdAt: base.add(const Duration(minutes: 4)),
      ),
    ];

    final entries = buildThreadListEntries(messages);
    final messageEntries = entries.whereType<ThreadMessageEntry>().toList();

    expect(messageEntries[0].groupPosition, MessageBubbleGroupPosition.single);
    expect(messageEntries[1].groupPosition, MessageBubbleGroupPosition.single);
    expect(messageEntries.every((e) => e.showTimestamp), isTrue);
  });

  test('still renders isolated messages and date headers', () {
    final messages = [
      message(id: 'm1', senderId: 'u1', createdAt: base),
      message(
        id: 'm2',
        senderId: 'u2',
        createdAt: base.add(const Duration(days: 1)),
      ),
    ];

    final entries = buildThreadListEntries(messages);

    expect(entries.whereType<ThreadDateHeaderEntry>(), hasLength(2));
    expect(entries.whereType<ThreadMessageEntry>(), hasLength(2));
    expect(
      entries.whereType<ThreadMessageEntry>().every(
        (e) => e.groupPosition == MessageBubbleGroupPosition.single,
      ),
      isTrue,
    );
    expect(
      entries.whereType<ThreadMessageEntry>().every((e) => e.showTimestamp),
      isTrue,
    );
  });
}
