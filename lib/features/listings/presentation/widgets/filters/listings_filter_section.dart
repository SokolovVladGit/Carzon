import 'package:flutter/material.dart';

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
    final body = useCard ? ListingsFilterSurfaceCard(child: child) : child;

    final titleStyle = theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.08,
          height: 1.22,
          color: scheme.onSurface.withValues(alpha: 0.92),
        ) ??
        theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.1,
          color: scheme.onSurface.withValues(alpha: 0.92),
        );

    return Padding(
      padding: const EdgeInsets.only(bottom: 34),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sectionIndex != null) ...[
                SizedBox(
                  width: 30,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      sectionIndex!,
                      textAlign: TextAlign.right,
                      style: theme.textTheme.labelMedium?.copyWith(
                        letterSpacing: 0.45,
                        height: 1.2,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface.withValues(alpha: 0.36),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(title, style: titleStyle),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 10),
            Padding(
              padding: EdgeInsets.only(left: sectionIndex != null ? 40 : 0),
              child: Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurface.withValues(alpha: 0.5),
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
