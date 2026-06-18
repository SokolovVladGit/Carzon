import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Inner budget block inside section 02 (price bounds + listing currency).
class ListingsFilterBudgetPanel extends StatelessWidget {
  const ListingsFilterBudgetPanel({super.key, required this.child});

  final Widget child;

  static const double _radius = 18;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;

    final decoration =
        AppTheme.editorialDarkSectionCard(scheme, borderRadius: _radius) ??
        BoxDecoration(
          borderRadius: BorderRadius.circular(_radius),
          border: Border.all(
            color: light
                ? scheme.outlineVariant.withValues(alpha: 0.2)
                : scheme.outline.withValues(alpha: 0.28),
          ),
          color: light
              ? Color.alphaBlend(
                  scheme.surfaceContainerHighest.withValues(alpha: 0.2),
                  scheme.surface,
                )
              : Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.05),
                  scheme.surfaceContainerLow,
                ),
          boxShadow: light
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.035),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [
                  BoxShadow(
                    color: scheme.primary.withValues(alpha: 0.04),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                    spreadRadius: -2,
                  ),
                ],
        );

    return DecoratedBox(
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
        child: child,
      ),
    );
  }
}
