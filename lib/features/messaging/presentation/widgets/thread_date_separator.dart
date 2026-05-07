import 'package:flutter/material.dart';

/// Subtle centered date pill between message groups.
class ThreadDateSeparator extends StatelessWidget {
  const ThreadDateSeparator({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Center(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cs.surfaceContainerLow.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: cs.outlineVariant.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withValues(
                  alpha: theme.brightness == Brightness.dark ? 0.12 : 0.05,
                ),
                blurRadius: 4,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
            child: Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: cs.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.15,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
