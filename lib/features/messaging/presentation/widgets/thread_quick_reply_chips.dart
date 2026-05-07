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
    final replies = [
      l10n.messagingQuickReplyStillAvailable,
      l10n.messagingQuickReplyWhereToView,
      l10n.messagingQuickReplyNegotiable,
      l10n.messagingQuickReplyWhenCall,
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.messagingQuickReplyHint,
            textAlign: TextAlign.center,
            style: theme.textTheme.labelMedium?.copyWith(
              color: cs.onSurfaceVariant,
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
                    label: Text(t, style: theme.textTheme.labelLarge),
                    visualDensity: VisualDensity.compact,
                    backgroundColor: cs.surfaceContainerLow.withValues(
                      alpha: 0.92,
                    ),
                    side: BorderSide(
                      color: cs.outlineVariant.withValues(alpha: 0.4),
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
