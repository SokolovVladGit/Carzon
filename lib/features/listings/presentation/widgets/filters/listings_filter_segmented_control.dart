import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Compact exclusive choices (currency, region, listing type).
///
/// Natural-width pills inside a soft shared shell. When every option fits on one
/// row, spare width is distributed as balanced gaps; otherwise pills wrap.
class ListingsFilterSegmentEntry<T> {
  const ListingsFilterSegmentEntry({required this.value, required this.label});

  final T value;
  final Widget label;
}

class ListingsFilterSegmentedControl<T> extends StatelessWidget {
  const ListingsFilterSegmentedControl({
    super.key,
    required this.value,
    required this.onChanged,
    required this.entries,
    this.minHeight = 44,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<ListingsFilterSegmentEntry<T>> entries;
  final double minHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final shellRadius = BorderRadius.circular(20);
    final shell = light
        ? Color.alphaBlend(
            scheme.surfaceContainerHighest.withValues(alpha: 0.10),
            scheme.surface.withValues(alpha: 0.36),
          )
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.05),
            scheme.surfaceContainerLow,
          );
    final shellBorder = light
        ? scheme.outlineVariant.withValues(alpha: 0.26)
        : scheme.outline.withValues(alpha: 0.32);

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: shellRadius,
          color: shell,
          border: Border.all(color: shellBorder),
          boxShadow: light
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.035),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                    spreadRadius: -4,
                  ),
                ]
              : [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.05),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                    spreadRadius: -3,
                  ),
                ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: constraints.maxWidth,
                child: Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  runAlignment: WrapAlignment.start,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final entry in entries)
                      _PremiumSegmentPill<T>(
                        minHeight: minHeight,
                        selected: entry.value == value,
                        child: entry.label,
                        onTap: () => onChanged(entry.value),
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _PremiumSegmentPill<T> extends StatelessWidget {
  const _PremiumSegmentPill({
    required this.minHeight,
    required this.selected,
    required this.child,
    required this.onTap,
  });

  final double minHeight;
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final accent = AppTheme.editorialAccentColor(scheme);
    final pillRadius = BorderRadius.circular(16);

    final selectedDecoration = BoxDecoration(
      borderRadius: pillRadius,
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: light
            ? [
                Color.alphaBlend(
                  scheme.primaryContainer.withValues(alpha: 0.58),
                  scheme.surface,
                ),
                Color.alphaBlend(
                  accent.withValues(alpha: 0.10),
                  scheme.surfaceContainerLowest,
                ),
              ]
            : [
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.20),
                  scheme.surfaceContainerHigh,
                ),
                Color.alphaBlend(
                  accent.withValues(alpha: 0.12),
                  scheme.surfaceContainerLow,
                ),
              ],
      ),
      border: Border.all(
        color: light
            ? accent.withValues(alpha: 0.22)
            : accent.withValues(alpha: 0.30),
      ),
    );

    final unselectedDecoration = BoxDecoration(
      borderRadius: pillRadius,
      color: Color.alphaBlend(
        scheme.outlineVariant.withValues(alpha: light ? 0.04 : 0.08),
        Colors.transparent,
      ),
      border: Border.all(
        color: scheme.outlineVariant.withValues(alpha: light ? 0.18 : 0.24),
      ),
    );

    final selectedTextColor = light
        ? scheme.onPrimaryContainer.withValues(alpha: 0.94)
        : scheme.onSurface.withValues(alpha: 0.96);
    final unselectedTextColor = scheme.onSurfaceVariant.withValues(
      alpha: light ? 0.74 : 0.82,
    );

    final labelStyle = theme.textTheme.labelLarge!.copyWith(
      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
      letterSpacing: selected ? -0.1 : 0,
      color: selected ? selectedTextColor : unselectedTextColor,
    );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: pillRadius,
        splashColor: scheme.onSurface.withValues(alpha: 0.038),
        highlightColor: scheme.onSurface.withValues(alpha: 0.018),
        child: Ink(
          decoration: selected ? selectedDecoration : unselectedDecoration,
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minHeight),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: selected ? 11 : 12,
                vertical: 10,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (selected) ...[
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: light
                          ? accent.withValues(alpha: 0.72)
                          : accent.withValues(alpha: 0.82),
                    ),
                    const SizedBox(width: 5),
                  ],
                  DefaultTextStyle(
                    style: labelStyle,
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
