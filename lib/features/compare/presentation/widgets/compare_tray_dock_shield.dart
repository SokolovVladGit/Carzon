import 'package:flutter/material.dart';

/// Tight opaque halo directly behind [CompareFloatingTray].
///
/// Sized to the capsule footprint (not full-width). Blocks feed imagery from
/// showing through shadow edges without a visible dock band.
class CompareTrayCapsuleBackplate extends StatelessWidget {
  const CompareTrayCapsuleBackplate({
    super.key,
    required this.surfaceColor,
    required this.child,
  });

  final Color surfaceColor;
  final Widget child;

  static const Key backplateKey = ValueKey<String>('compare_tray_capsule_backplate');

  /// Kept for tests that referenced the old shield key name.
  static const Key shieldKey = backplateKey;

  /// Slight expansion past the capsule (4–8 px per side).
  static const double haloPadding = 6;

  static const double cornerRadius = 30;

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: backplateKey,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: surfaceColor,
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        child: Padding(
          padding: const EdgeInsets.all(haloPadding),
          child: child,
        ),
      ),
    );
  }
}
