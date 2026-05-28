import 'package:flutter/material.dart';

import '../../../../../core/theme/app_theme.dart';
import 'listings_filter_surface_card.dart';

/// Grouped block for the listings filter form (browse + alert editor).
///
/// Keeps title hierarchy and spacing consistent without heavy decoration.
class ListingsFilterSection extends StatelessWidget {
  const ListingsFilterSection({
    super.key,
    this.sectionIndex,
    required this.title,
    this.subtitle,
    required this.child,
    this.useCard = true,
  });

  /// Optional editorial index label (e.g. `01`).
  final String? sectionIndex;
  final String title;
  final String? subtitle;
  final Widget child;

  /// When true, wraps [child] in a soft editorial card surface.
  final bool useCard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final body = useCard ? ListingsFilterSurfaceCard(child: child) : child;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
      fontWeight: FontWeight.w700,
      letterSpacing: 0.08,
      height: 1.22,
      color: scheme.onSurface.withValues(alpha: light ? 0.92 : 0.98),
    );

    final subtitleAlpha = light ? 0.5 : 0.72;

    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sectionIndex != null) ...[
                _FilterSectionIndexBadge(label: sectionIndex!, theme: theme),
                const SizedBox(width: 10),
              ],
              Expanded(child: Text(title, style: titleStyle)),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: sectionIndex != null ? 46 : 0),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: subtitleAlpha,
                  ),
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
          ],
          SizedBox(height: subtitle != null ? 18 : 16),
          body,
        ],
      ),
    );
  }
}

class _FilterSectionIndexBadge extends StatelessWidget {
  const _FilterSectionIndexBadge({required this.label, required this.theme});

  final String label;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final cs = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    if (light) {
      return SizedBox(
        width: 30,
        child: Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Text(
            label,
            textAlign: TextAlign.right,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 0.45,
              height: 1.2,
              fontWeight: FontWeight.w600,
              color: cs.onSurface.withValues(alpha: 0.36),
            ),
          ),
        ),
      );
    }

    final decoration = AppTheme.editorialDarkStepBadge(cs)!;
    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: DecoratedBox(
        decoration: decoration,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              letterSpacing: 0.45,
              height: 1.2,
              fontWeight: FontWeight.w600,
              fontSize: 12,
              color: AppTheme.editorialAccentColor(cs).withValues(alpha: 0.92),
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ),
      ),
    );
  }
}
