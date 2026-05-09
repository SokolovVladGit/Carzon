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
    final radius = BorderRadius.circular(18.0);
    final shell = Color.alphaBlend(
      scheme.surfaceContainerHighest.withValues(alpha: 0.08),
      scheme.surface,
    );

    return Semantics(
      container: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: radius,
          color: shell,
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.22),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.03),
              blurRadius: 14,
              offset: const Offset(0, 5),
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
                    color: scheme.outlineVariant.withValues(alpha: 0.18),
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
    final bg = selected
        ? Color.alphaBlend(
            scheme.primaryContainer.withValues(alpha: 0.52),
            scheme.surface.withValues(alpha: 0.02),
          )
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
                    ? scheme.onPrimaryContainer.withValues(alpha: 0.94)
                    : scheme.onSurface.withValues(alpha: 0.74),
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
