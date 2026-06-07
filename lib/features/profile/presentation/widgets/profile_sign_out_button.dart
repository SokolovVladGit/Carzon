import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';

class ProfileSignOutButton extends StatelessWidget {
  const ProfileSignOutButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fg = scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.78 : 0.68);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('profileSignOutButton'),
        onTap: onPressed,
        borderRadius: BorderRadius.circular(16),
        splashFactory: InkRipple.splashFactory,
        splashColor: scheme.onSurface.withValues(alpha: 0.030),
        highlightColor: Colors.transparent,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Color.alphaBlend(
              scheme.primary.withValues(alpha: isDark ? 0.04 : 0.022),
              isDark ? scheme.surfaceContainerLow : scheme.surface,
            ),
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.16 : 0.12),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12.5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CarzonIcons.signOut, size: 17, color: fg),
                const SizedBox(width: 8),
                Text(
                  l10n.profileSignOut,
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.02,
                    color: fg,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
