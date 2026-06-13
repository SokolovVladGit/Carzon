import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/chat_message.dart';
import '../utils/message_bubble_group_position.dart';

class ChatMessageBubble extends StatelessWidget {
  const ChatMessageBubble({
    super.key,
    required this.message,
    required this.isOutgoing,
    required this.timeLabel,
    this.groupPosition = MessageBubbleGroupPosition.single,
    this.showTimestamp = true,
    this.onLongPress,
  });

  final ChatMessage message;
  final bool isOutgoing;
  final String? timeLabel;
  final MessageBubbleGroupPosition groupPosition;
  final bool showTimestamp;
  final VoidCallback? onLongPress;

  static const double _radiusLarge = 18;
  static const double _radiusSmall = 5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = _borderRadius(isOutgoing: isOutgoing);
    final displayTimeLabel =
        showTimestamp && timeLabel != null && timeLabel!.isNotEmpty;

    final bg = _bubbleColor(cs, isOutgoing: isOutgoing, isDark: isDark);
    final fg = _foregroundColor(cs, isOutgoing: isOutgoing, isDark: isDark);
    final align = isOutgoing ? Alignment.centerRight : Alignment.centerLeft;
    final shadowAlpha = isDark ? 0.14 : (isOutgoing ? 0.08 : 0.05);

    return Padding(
      padding: _outerPadding(),
      child: Align(
        alignment: align,
        child: GestureDetector(
          onLongPress: onLongPress,
          behavior: HitTestBehavior.deferToChild,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.sizeOf(context).width * 0.78,
            ),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: bg,
                borderRadius: radius,
                border: _bubbleBorder(cs, isOutgoing: isOutgoing, isDark: isDark),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: shadowAlpha),
                    blurRadius: isDark ? 10 : 8,
                    offset: Offset(0, isOutgoing ? 3 : 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(15, 10, 15, 8),
                child: Column(
                  crossAxisAlignment: isOutgoing
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (message.body.isNotEmpty)
                      Text(
                        message.body,
                        softWrap: true,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          color: fg,
                          height: 1.42,
                          fontSize: 16,
                          letterSpacing: 0.1,
                        ),
                      ),
                    if (displayTimeLabel) ...[
                      if (message.body.isNotEmpty) const SizedBox(height: 4),
                      Text(
                        timeLabel!,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: fg.withValues(alpha: isDark ? 0.58 : 0.52),
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.2,
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

  Color _foregroundColor(
    ColorScheme cs, {
    required bool isOutgoing,
    required bool isDark,
  }) {
    if (isOutgoing) {
      return isDark
          ? cs.onPrimary.withValues(alpha: 0.96)
          : cs.onPrimaryContainer.withValues(alpha: 0.96);
    }
    return cs.onSurface.withValues(alpha: isDark ? 0.94 : 0.92);
  }

  Border? _bubbleBorder(
    ColorScheme cs, {
    required bool isOutgoing,
    required bool isDark,
  }) {
    if (isOutgoing) {
      if (isDark) {
        return Border.all(
          color: AppTheme.editorialAccentColor(cs).withValues(alpha: 0.22),
        );
      }
      return null;
    }
    return Border.all(
      color: cs.outlineVariant.withValues(alpha: isDark ? 0.32 : 0.28),
    );
  }

  EdgeInsets _outerPadding() {
    switch (groupPosition) {
      case MessageBubbleGroupPosition.single:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 5);
      case MessageBubbleGroupPosition.first:
        return const EdgeInsets.fromLTRB(16, 5, 16, 2);
      case MessageBubbleGroupPosition.middle:
        return const EdgeInsets.fromLTRB(16, 2, 16, 2);
      case MessageBubbleGroupPosition.last:
        return const EdgeInsets.fromLTRB(16, 2, 16, 5);
    }
  }

  BorderRadius _borderRadius({required bool isOutgoing}) {
    const large = Radius.circular(_radiusLarge);
    const small = Radius.circular(_radiusSmall);
    switch (groupPosition) {
      case MessageBubbleGroupPosition.single:
      case MessageBubbleGroupPosition.first:
        return BorderRadius.only(
          topLeft: large,
          topRight: large,
          bottomLeft: isOutgoing ? large : small,
          bottomRight: isOutgoing ? small : large,
        );
      case MessageBubbleGroupPosition.middle:
        return BorderRadius.only(
          topLeft: isOutgoing ? large : small,
          topRight: isOutgoing ? small : large,
          bottomLeft: isOutgoing ? large : small,
          bottomRight: isOutgoing ? small : large,
        );
      case MessageBubbleGroupPosition.last:
        return BorderRadius.only(
          topLeft: isOutgoing ? large : small,
          topRight: isOutgoing ? small : large,
          bottomLeft: large,
          bottomRight: large,
        );
    }
  }

  Color _bubbleColor(
    ColorScheme cs, {
    required bool isOutgoing,
    required bool isDark,
  }) {
    final accent = AppTheme.editorialAccentColor(cs);
    if (!isDark) {
      if (isOutgoing) {
        return Color.alphaBlend(
          accent.withValues(alpha: 0.18),
          cs.primaryContainer,
        );
      }
      return cs.surface;
    }
    if (isOutgoing) {
      return Color.alphaBlend(
        accent.withValues(alpha: 0.38),
        cs.surfaceContainerHigh,
      );
    }
    return Color.alphaBlend(
      accent.withValues(alpha: 0.06),
      cs.surfaceContainerHighest,
    );
  }
}
