import 'package:flutter/material.dart';

/// Compact “VIN” mark: Latin [V] in green (check-like), subtle [IN] — not verification.
class VinPresentLatinBadge extends StatelessWidget {
  const VinPresentLatinBadge({super.key, this.heroSize = false});

  /// Larger badge for buyer VIN report hero header.
  final bool heroSize;

  static const Color _vinPresentGreen = Color(0xFF1F9D57);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final vSize = heroSize ? 22.0 : 17.0;
    final inSize = heroSize ? 10.5 : 9.5;
    final padH = heroSize ? 12.0 : 8.0;
    final padV = heroSize ? 8.0 : 5.0;
    final radius = heroSize ? 14.0 : 10.0;

    return DecoratedBox(
      key: const ValueKey('vin_present_latin_badge'),
      decoration: BoxDecoration(
        color: _vinPresentGreen.withValues(alpha: heroSize ? 0.14 : 0.12),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: _vinPresentGreen.withValues(alpha: heroSize ? 0.32 : 0.28),
        ),
        boxShadow: heroSize
            ? [
                BoxShadow(
                  color: _vinPresentGreen.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                  spreadRadius: -2,
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'V',
              key: const ValueKey('vin_present_latin_badge_v'),
              style: TextStyle(
                fontSize: vSize,
                height: 1,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.6,
                color: _vinPresentGreen,
                fontStyle: FontStyle.normal,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 1),
              child: Text(
                'IN',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: inSize,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.35,
                  color: scheme.onSurface.withValues(alpha: 0.52),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Neutral VIN mark for non-success report states (not verification).
class VinNeutralLatinBadge extends StatelessWidget {
  const VinNeutralLatinBadge({super.key, this.heroSize = false});

  final bool heroSize;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final muted = scheme.onSurfaceVariant.withValues(alpha: 0.55);
    final vSize = heroSize ? 22.0 : 17.0;
    final inSize = heroSize ? 10.5 : 9.5;
    final padH = heroSize ? 12.0 : 8.0;
    final padV = heroSize ? 8.0 : 5.0;
    final radius = heroSize ? 14.0 : 10.0;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'V',
              style: TextStyle(
                fontSize: vSize,
                height: 1,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
                color: muted,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 2, bottom: 1),
              child: Text(
                'IN',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: inSize,
                  height: 1,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.35,
                  color: muted.withValues(alpha: 0.75),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
