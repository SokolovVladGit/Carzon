import 'package:flutter/material.dart';

/// Soft editorial “block” surface for grouped filter controls.
class ListingsFilterSurfaceCard extends StatelessWidget {
  const ListingsFilterSurfaceCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    const radius = 22.0;
    final r = BorderRadius.circular(radius);

    final base = scheme.surface;
    final topSheen = Color.alphaBlend(
      scheme.surfaceContainerHigh.withValues(alpha: 0.18),
      Color.alphaBlend(
        scheme.surfaceContainerLow.withValues(alpha: 0.08),
        base,
      ),
    );
    final mid = Color.alphaBlend(
      scheme.surfaceContainerHighest.withValues(alpha: 0.11),
      base,
    );
    final lower = Color.alphaBlend(
      scheme.surfaceContainerHighest.withValues(alpha: 0.06),
      base,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: r,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(
              scheme.onSurface.withValues(alpha: 0.028),
              topSheen,
            ),
            mid,
            lower,
          ],
          stops: const [0, 0.55, 1],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.13),
        ),
        boxShadow: [
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
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(20), child: child),
    );
  }
}
