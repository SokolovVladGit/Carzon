import 'package:flutter/material.dart';

/// Subtle centered date pill between message groups.
class ThreadDateSeparator extends StatelessWidget {
  const ThreadDateSeparator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: light
                ? cs.surface.withValues(alpha: 0.92)
                : cs.surfaceContainerLow.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: light ? 0.32 : 0.38),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(alpha: light ? 0.04 : 0.14),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: cs.onSurfaceVariant.withValues(alpha: light ? 0.88 : 0.82),
                fontWeight: FontWeight.w600,
                letterSpacing: 0.25,
                fontSize: 11.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
