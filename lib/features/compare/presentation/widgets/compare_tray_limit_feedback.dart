import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import 'compare_floating_tray.dart';

/// Inline capsule shown when the compare set is full (replaces tray briefly).
class CompareTrayLimitFeedback extends StatelessWidget {
  const CompareTrayLimitFeedback({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final surface = isDark ? scheme.surfaceContainerHigh : Colors.white;
    final borderColor = scheme.outlineVariant.withValues(
      alpha: isDark ? 0.35 : 0.22,
    );
    final iconBg = scheme.primaryContainer.withValues(alpha: isDark ? 0.45 : 0.55);

    return Semantics(
      liveRegion: true,
      label:
          '${l10n.compareTrayMaxLimitTitle}. ${l10n.compareTrayMaxLimitHint}',
      child: Material(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(color: borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
          child: Row(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 20,
                    color: scheme.primary,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.compareTrayMaxLimitTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.compareTrayMaxLimitHint,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.92),
                        height: 1.25,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Same footprint as [CompareFloatingTray] for host positioning tests.
double compareTrayLimitFeedbackHeight() => CompareFloatingTray.height;
