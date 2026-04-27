import 'package:flutter/material.dart';

/// Lightweight surface used by the listing details page to group
/// related content (summary, specs, contact) into rounded cards.
///
/// Visual rhythm is defined here so every section on the details page
/// inherits the same radius, padding, and surface color. This widget
/// is intentionally presentational: it does not own any state and
/// does not reach into a localization or theming layer beyond
/// `Theme.of(context)`.
class DetailsSectionCard extends StatelessWidget {
  const DetailsSectionCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(16),
  });

  /// Optional section title rendered as `titleMedium` above [child].
  final String? title;

  /// Main content of the card.
  final Widget child;

  /// Inner padding. Defaults to 16 on all sides to match the page's
  /// 16 px horizontal gutter.
  final EdgeInsetsGeometry padding;

  /// Shared corner radius of every details section.
  static const double radius = 20;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final title = this.title;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(radius),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
          ],
          child,
        ],
      ),
    );
  }
}
