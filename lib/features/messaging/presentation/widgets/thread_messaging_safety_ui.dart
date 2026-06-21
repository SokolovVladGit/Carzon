import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';

/// Confirmation before blocking the listing-conversation peer.
Future<bool> showThreadBlockConfirmationDialog(BuildContext context) async {
  final l10n = context.l10n;
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(l10n.messagingSafetyBlockConfirmTitle),
      content: Text(l10n.messagingSafetyBlockConfirmBody),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: Text(l10n.messagingSafetyBlockConfirmCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: Text(l10n.messagingSafetyBlockConfirmAction),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Compact banner when the current user blocked the peer.
class ThreadBlockedBanner extends StatelessWidget {
  const ThreadBlockedBanner({
    super.key,
    required this.blockedByMe,
    required this.messagingUnavailable,
  });

  final bool blockedByMe;
  final bool messagingUnavailable;

  @override
  Widget build(BuildContext context) {
    if (!blockedByMe && !messagingUnavailable) return const SizedBox.shrink();

    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    final title = blockedByMe
        ? l10n.messagingSafetyBlockedBannerTitle
        : l10n.messagingSafetySendUnavailable;
    final body = blockedByMe ? l10n.messagingSafetyBlockedBannerBody : null;

    return Material(
      color: cs.surfaceContainerHigh,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              blockedByMe ? CarzonIcons.userBlock : CarzonIcons.info,
              size: 20,
              color: cs.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (body != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      body,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
