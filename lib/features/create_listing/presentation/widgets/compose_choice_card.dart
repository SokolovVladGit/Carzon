import 'package:flutter/material.dart';

/// Single selectable card for deal type and market — consistent premium control.
class ComposeChoiceCard extends StatelessWidget {
  const ComposeChoiceCard({
    super.key,
    required this.label,
    required this.selected,
    required this.enabled,
    required this.onTap,
    required this.theme,
    this.compact = false,
    this.labelTextAlign = TextAlign.start,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool compact;
  final TextAlign labelTextAlign;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final bg = selected
        ? Color.alphaBlend(
            cs.onSurface.withValues(
              alpha: br == Brightness.light ? 0.07 : 0.11,
            ),
            cs.surfaceContainerLowest,
          )
        : Color.alphaBlend(
            cs.outlineVariant.withValues(alpha: 0.045),
            cs.surfaceContainerLowest,
          );

    return Opacity(
      opacity: enabled ? 1 : 0.48,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(14),
          splashColor: cs.onSurface.withValues(alpha: 0.038),
          highlightColor: cs.onSurface.withValues(alpha: 0.018),
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: bg,
              border: Border.all(
                color: selected
                    ? cs.onSurface.withValues(
                        alpha: br == Brightness.light ? 0.26 : 0.34,
                      )
                    : cs.outlineVariant.withValues(alpha: 0.30),
                width: selected ? 1.15 : 1,
              ),
            ),
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 12 : 14,
              vertical: compact ? 11 : 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    textAlign: labelTextAlign,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                      height: 1.2,
                      letterSpacing: -0.12,
                      color: cs.onSurface.withValues(
                        alpha: selected ? 1 : 0.82,
                      ),
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check_rounded,
                    size: 22,
                    color: cs.onSurface.withValues(alpha: 0.62),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
