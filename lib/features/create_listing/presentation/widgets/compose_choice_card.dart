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
    this.stableSelectionIndicator = false,
    this.singleLineScaleDown = false,
  });

  final String label;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;
  final ThemeData theme;
  final bool compact;
  final TextAlign labelTextAlign;
  final bool stableSelectionIndicator;
  final bool singleLineScaleDown;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final br = theme.brightness;
    final light = br == Brightness.light;
    final bg = selected
        ? Color.alphaBlend(
            cs.primary.withValues(alpha: light ? 0.13 : 0.22),
            cs.surfaceContainerLowest,
          )
        : Color.alphaBlend(
            (light ? cs.primary : cs.outlineVariant).withValues(
              alpha: light ? 0.042 : 0.070,
            ),
            cs.surfaceContainerLowest,
          );
    final borderColor = selected
        ? cs.primary.withValues(alpha: light ? 0.38 : 0.48)
        : cs.outlineVariant.withValues(alpha: light ? 0.30 : 0.34);

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
              borderRadius: BorderRadius.circular(18),
              gradient: selected
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color.alphaBlend(
                          cs.primary.withValues(alpha: light ? 0.060 : 0.10),
                          bg,
                        ),
                        bg,
                      ],
                    )
                  : null,
              color: selected ? null : bg,
              border: Border.all(
                color: borderColor,
                width: selected ? 1.15 : 1,
              ),
              boxShadow: light
                  ? [
                      BoxShadow(
                        color: cs.shadow.withValues(
                          alpha: selected ? 0.060 : 0.030,
                        ),
                        blurRadius: selected ? 18 : 12,
                        offset: const Offset(0, 5),
                      ),
                    ]
                  : const <BoxShadow>[],
            ),
            padding: EdgeInsets.symmetric(
              horizontal: stableSelectionIndicator ? 12 : (compact ? 14 : 16),
              vertical: compact ? 12 : 15,
            ),
            child: Row(
              children: [
                Expanded(
                  child: singleLineScaleDown
                      ? FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: AlignmentDirectional.centerStart,
                          child: Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            textAlign: labelTextAlign,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: selected
                                  ? FontWeight.w800
                                  : FontWeight.w600,
                              height: 1.2,
                              letterSpacing: -0.12,
                              color: cs.onSurface.withValues(
                                alpha: selected ? 0.96 : 0.82,
                              ),
                            ),
                          ),
                        )
                      : Text(
                          label,
                          textAlign: labelTextAlign,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: selected
                                ? FontWeight.w800
                                : FontWeight.w600,
                            height: 1.2,
                            letterSpacing: -0.12,
                            color: cs.onSurface.withValues(
                              alpha: selected ? 0.96 : 0.82,
                            ),
                          ),
                        ),
                ),
                if (stableSelectionIndicator) const SizedBox(width: 8),
                if (stableSelectionIndicator)
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: selected
                        ? DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: cs.primary.withValues(
                                alpha: light ? 0.12 : 0.22,
                              ),
                            ),
                            child: Icon(
                              Icons.check_rounded,
                              size: 17,
                              color: cs.primary.withValues(
                                alpha: light ? 0.90 : 0.98,
                              ),
                            ),
                          )
                        : null,
                  ),
                if (selected && !stableSelectionIndicator)
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: cs.primary.withValues(alpha: light ? 0.12 : 0.22),
                    ),
                    alignment: Alignment.center,
                    child: Icon(
                      Icons.check_rounded,
                      size: 17,
                      color: cs.primary.withValues(alpha: light ? 0.90 : 0.98),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
