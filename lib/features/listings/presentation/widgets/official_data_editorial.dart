import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Card shell decoration aligned with loaded official-data sections.
BoxDecoration officialDataPendingCardDecoration(ThemeData theme) {
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  if (isDark) {
    return AppTheme.editorialDarkSectionCard(scheme, borderRadius: 16)!;
  }

  return BoxDecoration(
    color: scheme.surfaceContainerLowest,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(
      color: scheme.outlineVariant.withValues(alpha: 0.28),
    ),
  );
}

/// Designed icon anchor for pending editorial status cards.
class OfficialDataPendingIconAnchor extends StatelessWidget {
  const OfficialDataPendingIconAnchor({
    super.key,
    required this.theme,
    required this.icon,
  });

  final ThemeData theme;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final decoration = isDark
        ? BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.38),
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.16),
                  scheme.surfaceContainerHigh,
                ),
                scheme.surfaceContainerLow,
              ],
            ),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: scheme.primaryContainer.withValues(alpha: 0.42),
            border: Border.all(
              color: scheme.primary.withValues(alpha: 0.14),
            ),
          );

    return SizedBox(
      width: 40,
      height: 40,
      child: DecoratedBox(
        decoration: decoration,
        child: Icon(
          icon,
          size: 20,
          color: scheme.primary.withValues(alpha: isDark ? 0.92 : 0.86),
        ),
      ),
    );
  }
}

/// Compact in-progress status pill for pending editorial cards.
class OfficialDataPendingStatusChip extends StatelessWidget {
  const OfficialDataPendingStatusChip({
    super.key,
    required this.theme,
    required this.icon,
  });

  final ThemeData theme;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.2 : 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Icon(
          icon,
          size: 13,
          color: scheme.primary.withValues(alpha: isDark ? 0.9 : 0.82),
        ),
      ),
    );
  }
}

/// Source-only badge row (no updated date) for pending card footers.
class OfficialDataSourceBadge extends StatelessWidget {
  const OfficialDataSourceBadge({
    super.key,
    required this.theme,
    required this.label,
    this.labelKey,
  });

  final ThemeData theme;
  final String label;
  final Key? labelKey;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        child: Text(
          key: labelKey,
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.12,
            color: scheme.primary.withValues(alpha: isDark ? 0.94 : 0.9),
          ),
        ),
      ),
    );
  }
}

/// Muted scope/limitation footnote for pending card footers.
class OfficialDataPendingFootnote extends StatelessWidget {
  const OfficialDataPendingFootnote({
    super.key,
    required this.theme,
    required this.text,
    this.textKey,
  });

  final ThemeData theme;
  final String text;
  final Key? textKey;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(
            Icons.info_outline_rounded,
            size: 14,
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.62 : 0.68,
            ),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            key: textKey,
            text,
            style: theme.textTheme.labelSmall?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.76 : 0.82,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Compact source badge + optional updated date for official-data sections.
class OfficialDataSourceHeader extends StatelessWidget {
  const OfficialDataSourceHeader({
    super.key,
    required this.theme,
    required this.sourceLabel,
    required this.sourceKey,
    this.updatedDateLabel,
    this.updatedDateKey,
  });

  final ThemeData theme;
  final String sourceLabel;
  final Key sourceKey;
  final String? updatedDateLabel;
  final Key? updatedDateKey;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.primary.withValues(alpha: isDark ? 0.14 : 0.08),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            child: Text(
              key: sourceKey,
              sourceLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.w600,
                letterSpacing: 0.12,
                color: scheme.primary.withValues(alpha: isDark ? 0.94 : 0.9),
              ),
            ),
          ),
        ),
        if (updatedDateLabel != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              key: updatedDateKey,
              updatedDateLabel!,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.76 : 0.82,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// Small strong count stat for summary headers.
class OfficialDataCountStat extends StatelessWidget {
  const OfficialDataCountStat({
    super.key,
    required this.theme,
    required this.label,
    this.statKey,
  });

  final ThemeData theme;
  final String label;
  final Key? statKey;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.38)
            : scheme.primaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        child: Text(
          key: statKey,
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
            color: isDark
                ? scheme.onSurface.withValues(alpha: 0.92)
                : scheme.onPrimaryContainer.withValues(alpha: 0.92),
          ),
        ),
      ),
    );
  }
}

/// Refined editorial category chip.
class OfficialDataCategoryChip extends StatelessWidget {
  const OfficialDataCategoryChip({
    super.key,
    required this.theme,
    required this.label,
  });

  final ThemeData theme;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: isDark
            ? scheme.primary.withValues(alpha: 0.1)
            : scheme.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.18 : 0.14),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        child: Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w500,
            letterSpacing: 0.02,
            color: scheme.onSurface.withValues(alpha: isDark ? 0.86 : 0.78),
          ),
        ),
      ),
    );
  }
}

/// Calm premium “show more” action — not a primary button, better than plain link.
class OfficialDataShowMoreAction extends StatelessWidget {
  const OfficialDataShowMoreAction({
    super.key,
    required this.theme,
    required this.label,
    required this.onPressed,
    this.actionKey,
  });

  final ThemeData theme;
  final String label;
  final VoidCallback onPressed;
  final Key? actionKey;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: actionKey,
        onTap: onPressed,
        borderRadius: BorderRadius.circular(10),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.32),
            ),
            color: isDark
                ? scheme.surfaceContainerHigh.withValues(alpha: 0.22)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.28),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.05,
                    color: scheme.primary.withValues(alpha: isDark ? 0.92 : 0.88),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  Icons.expand_more_rounded,
                  size: 18,
                  color: scheme.primary.withValues(alpha: isDark ? 0.88 : 0.82),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Subtle premium gradient/tint for Model Passport metric tiles (light + dark).
BoxDecoration modelPassportMetricSurfaceDecoration(ThemeData theme) {
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;

  return BoxDecoration(
    borderRadius: BorderRadius.circular(12),
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              scheme.primary.withValues(alpha: 0.18),
              scheme.surfaceContainerHigh.withValues(alpha: 0.42),
            ]
          : [
              scheme.primaryContainer.withValues(alpha: 0.55),
              scheme.surface.withValues(alpha: 0.95),
            ],
    ),
  );
}

/// Optional light-theme elevation for the primary combined-consumption tile.
List<BoxShadow>? modelPassportMetricPrimaryShadow(
  ThemeData theme, {
  required bool isPrimaryHighlight,
}) {
  if (!isPrimaryHighlight || theme.brightness == Brightness.dark) {
    return null;
  }
  return [
    BoxShadow(
      color: theme.colorScheme.primary.withValues(alpha: 0.06),
      blurRadius: 10,
      offset: const Offset(0, 3),
    ),
  ];
}
