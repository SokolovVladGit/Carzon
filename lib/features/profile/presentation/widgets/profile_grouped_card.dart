import 'package:flutter/material.dart';

Color profileSoftSurface(ColorScheme scheme, {required bool isDark}) {
  if (isDark) {
    return Color.alphaBlend(
      scheme.primary.withValues(alpha: 0.070),
      scheme.surfaceContainerLow,
    );
  }
  return Color.alphaBlend(
    scheme.primary.withValues(alpha: 0.026),
    scheme.surfaceContainerLowest,
  );
}

List<BoxShadow> profileCardShadow(ColorScheme scheme, {required bool isDark}) {
  return isDark
      ? [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.18),
            blurRadius: 26,
            offset: const Offset(0, 11),
          ),
        ]
      : [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.056),
            blurRadius: 26,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: scheme.primary.withValues(alpha: 0.026),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ];
}

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

    final cardFill = profileSoftSurface(scheme, isDark: isDark);
    final shadow = profileCardShadow(scheme, isDark: isDark);
    final radius = BorderRadius.circular(26);

    final innerPad =
        childPadding ??
        (title != null
            ? EdgeInsets.zero
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 10));

    return DecoratedBox(
      decoration: BoxDecoration(borderRadius: radius, boxShadow: shadow),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: radius,
          side: BorderSide(
            color: isDark
                ? scheme.outline.withValues(alpha: 0.28)
                : scheme.outlineVariant.withValues(alpha: 0.42),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.alphaBlend(
                  scheme.onSurface.withValues(alpha: isDark ? 0.028 : 0.012),
                  cardFill,
                ),
                cardFill,
                Color.alphaBlend(
                  scheme.primary.withValues(alpha: isDark ? 0.035 : 0.018),
                  cardFill,
                ),
              ],
              stops: const [0, 0.55, 1],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (title != null) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 17, 18, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title!,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.08,
                        ),
                      ),
                      if (subtitle != null && subtitle!.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: isDark ? 0.78 : 0.84,
                            ),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 18),
                  child: Divider(
                    height: 1,
                    thickness: 1,
                    endIndent: 18,
                    color: scheme.outline.withValues(
                      alpha: isDark ? 0.10 : 0.065,
                    ),
                  ),
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
    this.indent = 18,
    this.endIndent = 50,
  });

  final ColorScheme scheme;
  final bool isDark;
  final double indent;
  final double endIndent;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: indent),
      child: Divider(
        height: 1,
        thickness: 1,
        endIndent: endIndent,
        color: scheme.outline.withValues(alpha: isDark ? 0.080 : 0.045),
      ),
    );
  }
}
