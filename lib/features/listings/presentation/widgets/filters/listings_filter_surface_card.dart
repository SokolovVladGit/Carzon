import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';

/// Soft editorial “block” surface for grouped filter controls.
class ListingsFilterSurfaceCard extends StatelessWidget {
  const ListingsFilterSurfaceCard({super.key, required this.child});

  final Widget child;

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final light = Theme.of(context).brightness == Brightness.light;
    final r = BorderRadius.circular(_radius);

    final decoration =
        AppTheme.editorialDarkSectionCard(scheme, borderRadius: _radius) ??
        BoxDecoration(
          borderRadius: r,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomRight,
            colors: [
              Color.alphaBlend(
                scheme.onSurface.withValues(alpha: 0.028),
                Color.alphaBlend(
                  scheme.surfaceContainerHigh.withValues(alpha: 0.18),
                  Color.alphaBlend(
                    scheme.surfaceContainerLow.withValues(alpha: 0.08),
                    scheme.surface,
                  ),
                ),
              ),
              Color.alphaBlend(
                scheme.surfaceContainerHighest.withValues(alpha: 0.11),
                scheme.surface,
              ),
              Color.alphaBlend(
                scheme.surfaceContainerHighest.withValues(alpha: 0.06),
                scheme.surface,
              ),
            ],
            stops: const [0, 0.55, 1],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withValues(alpha: 0.13),
          ),
          boxShadow: light
              ? [
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.05),
                    blurRadius: 26,
                    offset: const Offset(0, 10),
                    spreadRadius: -2,
                  ),
                  BoxShadow(
                    color: scheme.shadow.withValues(alpha: 0.02),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        );

    return DecoratedBox(
      decoration: decoration,
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}
