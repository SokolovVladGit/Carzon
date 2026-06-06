import 'package:flutter/material.dart';

import '../../../../shared/ui/carzon_icons.dart';

class ProfileSettingsNavigationRow extends StatelessWidget {
  const ProfileSettingsNavigationRow({
    super.key,
    required this.rowKey,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.theme,
    required this.scheme,
    required this.onTap,
  });

  final Key rowKey;
  final IconData icon;
  final String title;
  final String subtitle;
  final ThemeData theme;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 10, top: 6, bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: rowKey,
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: scheme.primary.withValues(alpha: 0.92),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant.withValues(
                            alpha: 0.82,
                          ),
                          height: 1.32,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  CarzonIcons.chevronRight,
                  size: 19,
                  color: scheme.onSurfaceVariant.withValues(alpha: 0.48),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
