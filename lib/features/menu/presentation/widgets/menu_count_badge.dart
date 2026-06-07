import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

/// Compact count badge for menu rows (compare set size, etc.).
///
/// Renders nothing for [count] `<= 0`. Single-digit counts use a circle;
/// `10+` uses a pill so text stays legible.
class MenuCountBadge extends StatelessWidget {
  const MenuCountBadge({super.key, required this.count});

  final int count;

  static const double _compactSize = 22;
  static const double _pillMinHeight = 22;

  bool get _useCircle => count > 0 && count < 10;

  @override
  Widget build(BuildContext context) {
    if (count <= 0) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isDark
        ? AppTheme.editorialAccentColor(scheme)
        : scheme.primary;

    final background = Color.alphaBlend(
      accent.withValues(alpha: isDark ? 0.2 : 0.11),
      scheme.surfaceContainerHighest,
    );
    final foreground = accent.withValues(alpha: isDark ? 0.95 : 0.88);
    final border = accent.withValues(alpha: isDark ? 0.3 : 0.22);

    final textStyle = theme.textTheme.labelSmall?.copyWith(
      color: foreground,
      fontWeight: FontWeight.w700,
      height: 1,
      fontSize: 11.5,
    );

    final label = Text('$count', style: textStyle);

    if (_useCircle) {
      return Container(
        key: ValueKey('menu_count_badge_circle_$count'),
        width: _compactSize,
        height: _compactSize,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: background,
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
        child: label,
      );
    }

    return Container(
      key: ValueKey('menu_count_badge_pill_$count'),
      constraints: const BoxConstraints(minHeight: _pillMinHeight),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: border),
      ),
      child: label,
    );
  }
}
