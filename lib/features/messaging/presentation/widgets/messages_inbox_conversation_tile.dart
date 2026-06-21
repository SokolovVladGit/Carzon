import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/conversation.dart';

/// Messenger-style conversation row for the messages inbox.
class MessagesInboxConversationTile extends StatelessWidget {
  const MessagesInboxConversationTile({
    super.key,
    required this.conversation,
    required this.listingHeadlineFallback,
    required this.headline,
    required this.messagePreview,
    required this.timeText,
    required this.onTap,
  });

  final Conversation conversation;
  final String listingHeadlineFallback;
  final String headline;
  final String messagePreview;
  final String? timeText;
  final VoidCallback onTap;

  static const double avatarSize = 54;
  static const double _horizontalPadding = 18;
  static const double _verticalPadding = 12;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final unread = conversation.hasUnread;
    final isSupport = conversation.isSupportConversation;
    final accent = AppTheme.editorialAccentColor(cs);
    final onVar = cs.onSurfaceVariant;

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
      height: 1.18,
      fontSize: 16,
      color: cs.onSurface.withValues(alpha: light ? 1 : 0.96),
      letterSpacing: -0.25,
    );
    final previewStyle = theme.textTheme.bodyMedium?.copyWith(
      color: unread
          ? cs.onSurface.withValues(alpha: light ? 0.82 : 0.88)
          : onVar.withValues(alpha: light ? 0.88 : 0.7),
      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
      height: 1.28,
      fontSize: 14.5,
    );
    final timeStyle = theme.textTheme.labelSmall?.copyWith(
      color: unread ? accent : onVar.withValues(alpha: light ? 0.82 : 0.72),
      fontWeight: unread ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: 0.02,
      height: 1.15,
      fontSize: 12,
    );

    final rowBackground = unread
        ? (light
              ? Color.alphaBlend(
                  cs.primary.withValues(alpha: 0.045),
                  cs.surface,
                )
              : Color.alphaBlend(
                  accent.withValues(alpha: 0.075),
                  cs.surfaceContainerLow,
                ))
        : Colors.transparent;

    final tile = Material(
      color: rowBackground,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            _horizontalPadding,
            _verticalPadding,
            _horizontalPadding,
            _verticalPadding,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _InboxAvatar(
                url: isSupport
                    ? null
                    : conversation.listingCoverImageUrl?.trim(),
                isSupport: isSupport,
                accent: accent,
                light: light,
                unread: unread,
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            headline,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: titleStyle,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _InboxTimeLabel(timeText: timeText, style: timeStyle),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Text(
                            messagePreview,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: previewStyle,
                          ),
                        ),
                        if (unread) ...[
                          const SizedBox(width: 10),
                          _InboxUnreadBadge(
                            conversationId: conversation.id,
                            accentColor: accent,
                            light: light,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: headline,
      value: messagePreview,
      hint: unread ? 'Unread conversation' : null,
      child: tile,
    );
  }
}

class _InboxTimeLabel extends StatelessWidget {
  const _InboxTimeLabel({required this.timeText, required this.style});

  final String? timeText;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final trimmed = timeText?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return const SizedBox(width: 52);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 92),
      child: Text(
        trimmed,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.right,
        style: style,
      ),
    );
  }
}

/// Compact unread marker; [Conversation] exposes boolean [hasUnread] only.
class _InboxUnreadBadge extends StatelessWidget {
  const _InboxUnreadBadge({
    required this.conversationId,
    required this.accentColor,
    required this.light,
  });

  final String conversationId;
  final Color accentColor;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: DecoratedBox(
        key: ValueKey<String>('messages_inbox_unread_dot_$conversationId'),
        decoration: BoxDecoration(
          color: accentColor,
          shape: BoxShape.circle,
          border: Border.all(
            color: light
                ? Colors.white.withValues(alpha: 0.92)
                : accentColor.withValues(alpha: 0.2),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: accentColor.withValues(alpha: light ? 0.18 : 0.28),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: const SizedBox(width: 11, height: 11),
      ),
    );
  }
}

class _InboxAvatar extends StatelessWidget {
  const _InboxAvatar({
    this.url,
    this.isSupport = false,
    required this.accent,
    required this.light,
    this.unread = false,
  });

  final String? url;
  final bool isSupport;
  final Color accent;
  final bool light;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const size = MessagesInboxConversationTile.avatarSize;
    final resolved = url != null && url!.isNotEmpty ? url : null;

    Widget listingPlaceholder() => ColoredBox(
      color: cs.surfaceContainerHigh,
      child: Icon(
        Icons.directions_car_outlined,
        size: 24,
        color: cs.onSurfaceVariant.withValues(alpha: 0.45),
      ),
    );

    Widget supportPlaceholder() => DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accent.withValues(alpha: light ? 0.2 : 0.28),
            accent.withValues(alpha: light ? 0.08 : 0.12),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.support_agent_rounded,
          size: 26,
          color: accent.withValues(alpha: light ? 0.92 : 1),
        ),
      ),
    );

    final borderColor = unread
        ? accent.withValues(alpha: light ? 0.34 : 0.42)
        : isSupport
        ? accent.withValues(alpha: light ? 0.42 : 0.55)
        : cs.outlineVariant.withValues(alpha: light ? 0.38 : 0.45);

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: borderColor, width: isSupport ? 1.25 : 1),
          boxShadow: isSupport
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: light ? 0.14 : 0.22),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : [
                  BoxShadow(
                    color: cs.shadow.withValues(alpha: light ? 0.06 : 0.18),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: ClipOval(
          child: isSupport
              ? supportPlaceholder()
              : resolved == null
              ? listingPlaceholder()
              : Image.network(
                  resolved,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      listingPlaceholder(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: accent,
                        ),
                      ),
                    );
                  },
                ),
        ),
      ),
    );
  }
}
