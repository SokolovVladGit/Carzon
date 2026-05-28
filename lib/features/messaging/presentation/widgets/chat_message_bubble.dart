import 'package:flutter/material.dart';

import '../../domain/entities/chat_message.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    required this.timeLabel,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isOutgoing;
  final String? timeLabel;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.only(
      topLeft: const Radius.circular(20),
      topRight: const Radius.circular(20),
      bottomLeft: Radius.circular(isOutgoing ? 20 : 6),
      bottomRight: Radius.circular(isOutgoing ? 6 : 20),
    );

    final bg = _bubbleColor(cs, isOutgoing: isOutgoing, isDark: isDark);
    final fg = isOutgoing ? cs.onPrimaryContainer : cs.onSurface;
    final align = isOutgoing ? Alignment.centerRight : Alignment.centerLeft;
    final shadowAlpha = isDark ? 0.12 : 0.04;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      child: Align(
        alignment: align,
        child: GestureDetector(
          onLongPress: onLongPress,
          behavior: HitTestBehavior.deferToChild,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.8,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
                border: isDark && !isOutgoing
                    ? Border.all(color: cs.outline.withValues(alpha: 0.26))
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: shadowAlpha),
                    blurRadius: isDark ? 8 : 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 11, 14, 9),
                child: Column(
                  crossAxisAlignment: isOutgoing
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.body,
                      softWrap: true,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: fg.withValues(alpha: isDark ? 0.96 : 1),
                        height: 1.4,
                      ),
                    ),
                    if (timeLabel != null && timeLabel!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        timeLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: fg.withValues(alpha: 0.58),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _bubbleColor(
    ColorScheme cs, {
    required bool isOutgoing,
    required bool isDark,
  }) {
    if (!isDark) {
      return isOutgoing ? cs.primaryContainer : cs.surfaceContainerHigh;
    }
    if (isOutgoing) {
      return Color.alphaBlend(
        cs.primary.withValues(alpha: 0.32),
        cs.surfaceContainerHigh,
      );
    }
    return Color.alphaBlend(
      cs.primary.withValues(alpha: 0.08),
      cs.surfaceContainerHighest,
    );
  }
}
