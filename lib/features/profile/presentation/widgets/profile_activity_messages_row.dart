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
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          splashFactory: InkRipple.splashFactory,
          splashColor: scheme.onSurface.withValues(alpha: 0.038),
          highlightColor: Colors.transparent,
          child: Ink(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 12.5, 6, 12.5),
              child: Row(
                children: [
                  _ProfileActivityIconCapsule(scheme: scheme, isDark: isDark),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.messagingTitle,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.04,
                            height: 1.28,
                            color: scheme.onSurface.withValues(alpha: 0.94),
                          ),
                        ),
                        if (hasUnread || showNoUnreadCopy) ...[
                          const SizedBox(height: 4),
                          Text(
                            hasUnread
                                ? l10n.profileMessagesUnreadStatus
                                : l10n.profileMessagesNoUnreadStatus,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: hasUnread
                                    ? 0.88
                                    : (isDark ? 0.70 : 0.74),
                              ),
                              height: 1.32,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (hasUnread) ...[
                    _ProfileUnreadCountBadge(count: unreadConversationCount),
                    const SizedBox(width: 9),
                  ],
                  _ProfileChevronGlyph(scheme: scheme, isDark: isDark),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileActivityIconCapsule extends StatelessWidget {
  const _ProfileActivityIconCapsule({
    required this.scheme,
    required this.isDark,
  });

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: isDark ? 0.14 : 0.085),
          scheme.surfaceContainerLowest,
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.18),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Icon(
        CarzonIcons.chat,
        size: 19,
        color: scheme.primary.withValues(alpha: isDark ? 0.90 : 0.84),
      ),
    );
  }
}

class _ProfileChevronGlyph extends StatelessWidget {
  const _ProfileChevronGlyph({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 32,
      child: Icon(
        CarzonIcons.chevronRight,
        size: 18,
        color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.56 : 0.42),
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
    final isDark = theme.brightness == Brightness.dark;
    return Container(
      key: const ValueKey('profile_messages_unread_count_badge'),
      constraints: const BoxConstraints(minWidth: 26, minHeight: 24),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Color.alphaBlend(
          scheme.error.withValues(alpha: isDark ? 0.82 : 0.88),
          scheme.surfaceContainerHighest,
        ),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.error.withValues(alpha: isDark ? 0.28 : 0.20),
        ),
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
