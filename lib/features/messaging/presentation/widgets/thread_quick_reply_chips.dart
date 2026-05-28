import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';

/// Marketplace quick replies for an empty thread (insert only; never send).
class ThreadQuickReplyChips extends StatelessWidget {
  const ThreadQuickReplyChips({super.key, required this.textController});

  final TextEditingController textController;

  void _insert(String text) {
    textController.text = text;
    textController.selection = TextSelection.collapsed(offset: text.length);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final replies = [
      l10n.messagingQuickReplyStillAvailable,
      l10n.messagingQuickReplyWhereToView,
      l10n.messagingQuickReplyNegotiable,
      l10n.messagingQuickReplyWhenCall,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.messagingQuickReplyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant.withValues(alpha: isDark ? 0.78 : 1),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: replies
                .map((t) {
                  return ActionChip(
                    label: Text(
                      t,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: cs.onSurface.withValues(
                          alpha: isDark ? 0.94 : 1,
                        ),
                      ),
                    ),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: isDark
                        ? Color.alphaBlend(
                            cs.primary.withValues(alpha: 0.10),
                            cs.surfaceContainerHigh,
                          )
                        : cs.surfaceContainerLow.withValues(alpha: 0.92),
                    side: BorderSide(
                      color: cs.outline.withValues(alpha: isDark ? 0.28 : 0.4),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 0,
                    ),
                    onPressed: () => _insert(t),
                  );
                })
                .toList(growable: false),
          ),
        ],
      ),
    );
  }
}
