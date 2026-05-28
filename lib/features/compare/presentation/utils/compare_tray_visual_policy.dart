import 'package:flutter/foundation.dart';

/// Visual toggles for compare-tray isolation audits (tests / local debugging).
///
/// Production uses [CompareTrayVisualPolicy.production]. Audit presets prove
/// which layer can cause the image strip behind the tray:
/// - [auditNoFly]: fly overlay off — artifact on remove ⇒ fly innocent
/// - [auditSolidThumbs]: no [Image.network] in tray
/// - [auditMinimal]: fly off + solid thumbs + direct tray (no transitions)
@immutable
class CompareTrayVisualPolicy {
  const CompareTrayVisualPolicy({
    this.renderFlyOverlay = true,
    this.solidTrayThumbnails = false,
  });

  /// When false, [CompareFlyToTrayOverlaySlot] is not built.
  final bool renderFlyOverlay;

  /// When true, tray thumbs are flat color chips (no network decode).
  final bool solidTrayThumbnails;

  static const CompareTrayVisualPolicy production = CompareTrayVisualPolicy();

  static const CompareTrayVisualPolicy auditNoFly = CompareTrayVisualPolicy(
    renderFlyOverlay: false,
  );

  static const CompareTrayVisualPolicy auditSolidThumbs =
      CompareTrayVisualPolicy(solidTrayThumbnails: true);

  static const CompareTrayVisualPolicy auditMinimal = CompareTrayVisualPolicy(
    renderFlyOverlay: false,
    solidTrayThumbnails: true,
  );
}
