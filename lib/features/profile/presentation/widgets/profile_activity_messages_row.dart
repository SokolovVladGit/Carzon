import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';

class ProfileActivityMessagesRow extends StatelessWidget {
  const ProfileActivityMessagesRow({
    super.key,
    required this.hasUnread,
    required this.showNoUnreadCopy,
    required this.unreadConversationCount,
    required this.onTap,
  });

  final bool hasUnread;
  final bool showNoUnreadCopy;
  final int unreadConversationCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final trailingIcon = Icon(
      CarzonIcons.chevronRight,
      size: 19,
      color: scheme.onSurfaceVariant.withValues(alpha: 0.48),
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(
                CarzonIcons.chat,
                size: 22,
                color: scheme.primary.withValues(alpha: 0.92),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.messagingTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.06,
                        height: 1.28,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (hasUnread || showNoUnreadCopy)
                      Text(
                        hasUnread
                            ? l10n.profileMessagesUnreadStatus
                            : l10n.profileMessagesNoUnreadStatus,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: hasUnread ? 0.95 : 0.72,
                          ),
                          height: 1.32,
                        ),
                      ),
                  ],
                ),
              ),
              if (hasUnread) ...[
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _ProfileUnreadCountBadge(
                    count: unreadConversationCount,
                  ),
                ),
                trailingIcon,
              ] else
                trailingIcon,
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact unread conversation count for Profile > Activity > Messages row.
///
/// Displays [count] as `1`-`99`, or localized overflow (e.g. `99+`) when
/// greater than `99`; [count] must be positive.
class _ProfileUnreadCountBadge extends StatelessWidget {
  const _ProfileUnreadCountBadge({required this.count});

  final int count;

  static String badgeLabel(BuildContext context, int count) {
    if (count > 99) return context.l10n.profileMessagesUnreadCountOverflow;
    return '$count';
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Container(
      key: const ValueKey('profile_messages_unread_count_badge'),
      constraints: const BoxConstraints(minWidth: 24, minHeight: 22),
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: scheme.error,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        badgeLabel(context, count),
        style: theme.textTheme.labelSmall?.copyWith(
          color: scheme.onError,
          fontWeight: FontWeight.w700,
          height: 1,
        ),
      ),
    );
  }
}
