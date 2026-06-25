import 'package:flutter/material.dart';

/// Accent shared by catalog browse filter-alert affordances (header bell + FAB badge).
abstract final class CatalogFilterAlertAccent {
  static final Color amber = Colors.amber.shade700;

  /// Test hook for amber bell ornament on discovery filter FAB when delivery
  /// is fully enabled for the applied criteria.
  static const Key discoveryFilterFABAlertBellKey = ValueKey<Object>(
    'catalog_browse_discovery_filter_fab_alert_bell',
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
}
