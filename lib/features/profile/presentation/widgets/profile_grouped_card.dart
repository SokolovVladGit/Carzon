import 'package:flutter/material.dart';

class ProfileGroupedCard extends StatelessWidget {
  const ProfileGroupedCard({
    super.key,
    required this.child,
    this.title,
    this.subtitle,
    this.childPadding,
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final EdgeInsetsGeometry? childPadding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final shadow = isDark
        ? const <BoxShadow>[]
        : [
            BoxShadow(
              color: scheme.shadow.withValues(alpha: 0.065),
              blurRadius: 20,
              offset: const Offset(0, 7),
            ),
          ];

    final Color cardFill = isDark
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            scheme.surfaceTint.withValues(alpha: 0.035),
            scheme.surfaceContainerLowest,
          );

    final innerPad =
        childPadding ??
        (title != null
            ? const EdgeInsets.fromLTRB(4, 4, 4, 8)
            : const EdgeInsets.all(12));

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        boxShadow: shadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardFill,
            border: Border.all(
              color: scheme.outline.withValues(alpha: isDark ? 0.26 : 0.17),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.06,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: 0.9,
                            ),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outline.withValues(alpha: isDark ? 0.18 : 0.13),
                  indent: 16,
                  endIndent: 16,
                ),
              ],
              Padding(padding: innerPad, child: child),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileMutedDivider extends StatelessWidget {
  const ProfileMutedDivider({
    super.key,
    required this.scheme,
    required this.isDark,
  });

  final ColorScheme scheme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Divider(
        height: 1,
        thickness: 1,
        endIndent: 16,
        color: scheme.outline.withValues(alpha: isDark ? 0.16 : 0.11),
      ),
    );
  }
}
