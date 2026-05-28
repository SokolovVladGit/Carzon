import 'package:flutter/material.dart';

/// Compact row of exclusive choices (currency, future toggles).
///
/// Selected state is a soft tint — avoids harsh “default Flutter” blocks.
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
    this.height = 46,
  });

  final T value;
  final ValueChanged<T> onChanged;
  final List<ListingsFilterSegmentEntry<T>> entries;
  final double height;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final radius = BorderRadius.circular(18.0);
    final shell = light
        ? Color.alphaBlend(
            scheme.surfaceContainerHighest.withValues(alpha: 0.08),
            scheme.surface,
          )
        : Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.06),
            scheme.surfaceContainerLow,
          );
    final shellBorder = light
        ? scheme.outlineVariant.withValues(alpha: 0.22)
        : scheme.outline.withValues(alpha: 0.30);

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: shell,
          border: Border.all(color: shellBorder),
          boxShadow: light
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.03),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ]
              : [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.04),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Row(
            children: [
              for (var i = 0; i < entries.length; i++) ...[
                if (i > 0)
                  Container(
                    width: 1,
                    height: height,
                    color: light
                        ? scheme.outlineVariant.withValues(alpha: 0.18)
                        : scheme.outline.withValues(alpha: 0.24),
                  ),
                Expanded(
                  child: _Segment<T>(
                    height: height,
                    selected: entries[i].value == value,
                    child: entries[i].label,
                    onTap: () => onChanged(entries[i].value),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Segment<T> extends StatelessWidget {
  const _Segment({
    required this.height,
    required this.selected,
    required this.child,
    required this.onTap,
  });

  final double height;
  final bool selected;
  final Widget child;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final bg = selected
        ? (light
              ? Color.alphaBlend(
                  scheme.primaryContainer.withValues(alpha: 0.52),
                  scheme.surface.withValues(alpha: 0.02),
                )
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.22),
                  scheme.surfaceContainerHigh,
                ))
        : Colors.transparent;
    return Material(
      color: bg,
      child: InkWell(
        onTap: onTap,
        overlayColor: WidgetStatePropertyAll(
          scheme.primary.withValues(alpha: 0.07),
        ),
        child: SizedBox(
          height: height,
          child: Center(
            child: DefaultTextStyle(
              style: theme.textTheme.labelLarge!.copyWith(
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                color: selected
                    ? (light
                          ? scheme.onPrimaryContainer.withValues(alpha: 0.94)
                          : scheme.onSurface.withValues(alpha: 0.96))
                    : scheme.onSurfaceVariant.withValues(
                        alpha: light ? 0.74 : 0.82,
                      ),
              ),
              textAlign: TextAlign.center,
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
