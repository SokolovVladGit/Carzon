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
    final isDark = theme.brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 7),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: rowKey,
          borderRadius: BorderRadius.circular(18),
          splashFactory: InkRipple.splashFactory,
          splashColor: scheme.onSurface.withValues(alpha: 0.038),
          highlightColor: Colors.transparent,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(18)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(11, 12.5, 6, 12.5),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ProfileRowIconCapsule(
                    icon: icon,
                    scheme: scheme,
                    isDark: isDark,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.04,
                            height: 1.28,
                            color: scheme.onSurface.withValues(alpha: 0.94),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: isDark ? 0.76 : 0.80,
                            ),
                            height: 1.32,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: _ProfileSettingsChevron(
                      scheme: scheme,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileSettingsChevron extends StatelessWidget {
  const _ProfileSettingsChevron({required this.scheme, required this.isDark});

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 26,
      height: 32,
      child: Icon(
        CarzonIcons.chevronRight,
        size: 18,
        color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.56 : 0.42),
      ),
    );
  }
}

class _ProfileRowIconCapsule extends StatelessWidget {
  const _ProfileRowIconCapsule({
    required this.icon,
    required this.scheme,
    required this.isDark,
  });

  final IconData icon;
  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Color.alphaBlend(
          scheme.primary.withValues(alpha: isDark ? 0.14 : 0.085),
          scheme.surfaceContainerLowest,
        ),
        border: Border.all(
          color: scheme.primary.withValues(alpha: isDark ? 0.26 : 0.18),
        ),
        boxShadow: isDark
            ? const <BoxShadow>[]
            : [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Icon(
        icon,
        size: 19,
        color: scheme.primary.withValues(alpha: isDark ? 0.90 : 0.84),
      ),
    );
  }
}
