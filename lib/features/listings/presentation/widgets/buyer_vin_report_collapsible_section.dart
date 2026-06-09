import 'package:flutter/material.dart';

/// Low-priority collapsible block for buyer VIN report secondary content.
class BuyerVinReportCollapsibleSection extends StatelessWidget {
  const BuyerVinReportCollapsibleSection({
    super.key,
    required this.theme,
    required this.title,
    required this.child,
    this.initiallyExpanded = false,
    this.sectionKey,
  });

  final ThemeData theme;
  final String title;
  final Widget child;
  final bool initiallyExpanded;
  final String? sectionKey;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      key: sectionKey != null ? ValueKey(sectionKey) : null,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.32),
        ),
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.22),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: scheme.onSurface.withValues(alpha: 0.04),
        ),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.fromLTRB(14, 4, 8, 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          iconColor: scheme.onSurfaceVariant,
          collapsedIconColor: scheme.onSurfaceVariant,
          title: Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              height: 1.25,
              color: isDark
                  ? scheme.onSurface.withValues(alpha: 0.9)
                  : scheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
          children: [child],
        ),
      ),
    );
  }
}
