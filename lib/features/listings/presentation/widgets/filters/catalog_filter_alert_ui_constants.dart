import 'package:flutter/material.dart';

/// Amber accent shared by catalog browse filter-alert affordances (header bell + FAB badge).
abstract final class CatalogFilterAlertAccent {
  static final Color amber = Colors.amber.shade700;

  /// Test hook for amber bell ornament on discovery filter FAB.
  static const Key discoveryFilterFABAlertBellKey = ValueKey<Object>(
    'catalog_browse_discovery_filter_fab_alert_bell',
  );

  /// Test hook for the **saved-but-delivery-off** ornament on the
  /// discovery filter FAB. Rendered only when saved criteria matches the
  /// currently applied catalog feed and delivery is not fully enabled
  /// (push-disabled build, prefs off, or `notifications_enabled=false`).
  /// Must never appear simultaneously with
  /// [discoveryFilterFABAlertBellKey]; active delivery wins.
  static const Key discoveryFilterFABSavedNoDeliveryBellKey = ValueKey<Object>(
    'catalog_browse_discovery_filter_fab_saved_no_delivery_bell',
  );

  /// Test hook for the in-sheet bell when criteria are saved but delivery
  /// is unavailable (push-disabled build or prefs/row flag off). Visually
  /// distinct from the strong amber delivery-on state.
  static const Key sheetBellSavedNoDeliveryIconKey = ValueKey<Object>(
    'catalog_browse_filter_alert_sheet_bell_saved_no_delivery',
  );

  /// Test hook for the in-sheet inline notice rendered when the user
  /// taps the bell on criteria the cubit rejects as too broad
  /// (`BrowseCatalogBellOutcome.criteriaTooBroad`). The notice replaces
  /// the previous root-snackbar bleed: it must appear inside the open
  /// filter sheet only and never on the main listings page after the
  /// sheet closes.
  static const Key sheetTooBroadNoticeKey = ValueKey<Object>(
    'catalog_browse_filter_alert_sheet_too_broad_notice',
  );

  /// Outlined inactive bell stroke (readable on bright sheets).
  static Color inactiveStroke(ColorScheme scheme) =>
      scheme.onSurface.withValues(alpha: 0.45);

  /// "Saved, delivery pending" bell foreground — muted amber that reads
  /// as intentional yet does not mimic the fully-active delivery glyph.
  static Color savedNoDelivery(ColorScheme scheme) => Color.alphaBlend(
    amber.withValues(alpha: 0.55),
    scheme.onSurface.withValues(alpha: 0.32),
  );
}
