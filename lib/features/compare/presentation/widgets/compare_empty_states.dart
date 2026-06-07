import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/compare_item.dart';
import 'compare_snapshot_tile.dart';

/// Empty compare set (0 vehicles).
class CompareEmptyState extends StatelessWidget {
  const CompareEmptyState({super.key, required this.onBrowseListings});

  final VoidCallback onBrowseListings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CompareStateScaffold(
      title: l10n.compareVehiclesTitle,
      body: l10n.compareEmptyBody,
      primaryLabel: l10n.compareGoToListings,
      onPrimary: onBrowseListings,
    );
  }
}

/// One vehicle in compare — need at least two.
class CompareNeedOneMoreState extends StatelessWidget {
  const CompareNeedOneMoreState({
    super.key,
    required this.item,
    required this.onBrowseListings,
  });

  final CompareItem item;
  final VoidCallback onBrowseListings;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return _CompareStateScaffold(
      title: l10n.compareAddOneMoreTitle,
      body: l10n.compareAddOneMoreBody,
      primaryLabel: l10n.compareGoToListings,
      onPrimary: onBrowseListings,
      child: Padding(
        padding: const EdgeInsets.only(top: 20),
        child: CompareSnapshotTile(snapshot: item.snapshot),
      ),
    );
  }
}

class _CompareStateScaffold extends StatelessWidget {
  const _CompareStateScaffold({
    required this.title,
    required this.body,
    required this.primaryLabel,
    required this.onPrimary,
    this.child,
  });

  final String title;
  final String body;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final light = theme.brightness == Brightness.light;

    return DecoratedBox(
      decoration: _emptyCanvasDecoration(scheme, light),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 42),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            DecoratedBox(
              decoration: _emptyCardDecoration(scheme, light),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                child: _emptyContent(
                  theme: theme,
                  scheme: scheme,
                  light: light,
                  title: title,
                  body: body,
                  child: child,
                  primaryLabel: primaryLabel,
                  onPrimary: onPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  BoxDecoration _emptyCanvasDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.editorialDarkCompareCanvasGradient(scheme),
          stops: const [0, 0.5, 1],
        ),
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFDFEFF),
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.035),
            const Color(0xFFF5F8FC),
          ),
          const Color(0xFFEFF3F8),
        ],
      ),
    );
  }

  BoxDecoration _emptyCardDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return AppTheme.editorialDarkSectionCard(scheme, borderRadius: 26)!;
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.42)),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white, Color(0xFFF8FAFD)],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF243447).withValues(alpha: 0.085),
          blurRadius: 30,
          offset: const Offset(0, 16),
          spreadRadius: -14,
        ),
      ],
    );
  }
}

Widget _emptyContent({
  required ThemeData theme,
  required ColorScheme scheme,
  required bool light,
  required String title,
  required String body,
  required Widget? child,
  required String primaryLabel,
  required VoidCallback onPrimary,
}) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Align(
        alignment: Alignment.centerLeft,
        child: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: light
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      scheme.primary.withValues(alpha: 0.13),
                      scheme.primary.withValues(alpha: 0.04),
                    ],
                  )
                : RadialGradient(
                    colors: [
                      Color.alphaBlend(
                        scheme.primary.withValues(alpha: 0.20),
                        scheme.surfaceContainerHigh,
                      ),
                      scheme.surfaceContainerLow,
                    ],
                  ),
            border: Border.all(
              color: light
                  ? scheme.primary.withValues(alpha: 0.12)
                  : AppTheme.editorialAccentColor(
                      scheme,
                    ).withValues(alpha: 0.34),
            ),
          ),
          child: Icon(
            Icons.compare_arrows_rounded,
            size: 25,
            color: light
                ? scheme.primary
                : AppTheme.editorialAccentColor(scheme),
          ),
        ),
      ),
      const SizedBox(height: 18),
      Text(
        title,
        style: theme.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.45,
          color: scheme.onSurface.withValues(alpha: light ? 0.98 : 0.98),
        ),
      ),
      const SizedBox(height: 10),
      Text(
        body,
        style: theme.textTheme.bodyMedium?.copyWith(
          height: 1.48,
          color: scheme.onSurfaceVariant.withValues(alpha: light ? 0.86 : 0.76),
          fontWeight: FontWeight.w500,
        ),
      ),
      ?child,
      const SizedBox(height: 24),
      FilledButton(
        key: const ValueKey('compare_browse_listings_button'),
        onPressed: onPrimary,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: light ? 2 : 0,
          shadowColor: scheme.primary.withValues(alpha: 0.18),
        ),
        child: Text(primaryLabel),
      ),
    ],
  );
}
