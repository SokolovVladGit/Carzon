import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/conversation.dart';
import '../utils/thread_listing_copy.dart';

/// Messenger-style conversation row for the messages inbox.
class MessagesInboxConversationTile extends StatelessWidget {
  const MessagesInboxConversationTile({
    super.key,
    required this.conversation,
    required this.listingHeadlineFallback,
    required this.messagePreview,
    required this.timeText,
    required this.onTap,
  });

  final Conversation conversation;
  final String listingHeadlineFallback;
  final String messagePreview;
  final String? timeText;
  final VoidCallback onTap;

  static const double avatarSize = 56;
  static const double _horizontalPadding = 16;
  static const double _verticalPadding = 10;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final unread = conversation.hasUnread;
    final headline = threadListingPrimaryLine(
      conversation,
      listingHeadlineFallback,
    );
    final accent = AppTheme.editorialAccentColor(cs);
    final onVar = cs.onSurfaceVariant;

    final titleStyle = theme.textTheme.titleSmall?.copyWith(
      fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
      height: 1.2,
      color: cs.onSurface.withValues(alpha: light ? 1 : 0.96),
      letterSpacing: -0.2,
    );
    final previewStyle = theme.textTheme.bodyMedium?.copyWith(
      color: unread
          ? cs.onSurface.withValues(alpha: light ? 0.78 : 0.84)
          : onVar.withValues(alpha: light ? 0.92 : 0.72),
      fontWeight: unread ? FontWeight.w500 : FontWeight.w400,
      height: 1.25,
      fontSize: 14,
    );
    final timeStyle = theme.textTheme.labelSmall?.copyWith(
      color: unread
          ? accent
          : onVar.withValues(alpha: light ? 0.88 : 0.78),
      fontWeight: unread ? FontWeight.w600 : FontWeight.w500,
      letterSpacing: 0.05,
      height: 1.2,
    );

    final rowBackground = unread
        ? (light
            ? cs.primary.withValues(alpha: 0.05)
            : accent.withValues(alpha: 0.09))
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
              _InboxAvatar(url: conversation.listingCoverImageUrl?.trim()),
              const SizedBox(width: 12),
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
                        const SizedBox(width: 8),
                        _InboxTimeLabel(
                          timeText: timeText,
                          style: timeStyle,
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
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
                          const SizedBox(width: 8),
                          _InboxUnreadBadge(
                            conversationId: conversation.id,
                            accentColor: accent,
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
      return const SizedBox(width: 56);
    }
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 88),
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
  });

  final String conversationId;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        key: ValueKey<String>('messages_inbox_unread_dot_$conversationId'),
        width: 10,
        height: 10,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: accentColor,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.35),
                blurRadius: 4,
                spreadRadius: 0,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InboxAvatar extends StatelessWidget {
  const _InboxAvatar({this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    const size = MessagesInboxConversationTile.avatarSize;
    final resolved = url != null && url!.isNotEmpty ? url : null;

    Widget placeholder() => ColoredBox(
      color: cs.surfaceContainerHighest,
      child: Icon(
        Icons.directions_car_outlined,
        size: 26,
        color: cs.onSurfaceVariant.withValues(alpha: 0.42),
      ),
    );

    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: cs.outlineVariant.withValues(alpha: 0.32),
            width: 0.75,
          ),
        ),
        child: ClipOval(
          child: resolved == null
              ? placeholder()
              : Image.network(
                  resolved,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => placeholder(),
                  loadingBuilder: (context, child, progress) {
                    if (progress == null) return child;
                    return Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppTheme.editorialAccentColor(cs),
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
