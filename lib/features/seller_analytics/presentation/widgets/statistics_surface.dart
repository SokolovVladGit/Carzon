import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/floating_capsule_nav.dart';

/// Shared spacing and chrome for the Statistics editorial dashboard.
abstract final class StatisticsLayout {
  static const double radius = 24;
  static const double sectionGap = 26;
  static const double listingsTitleGap = 12;
  static const double listingGap = 8;
  static const double itemRadius = 18;
  static const double chartPlotHeight = 188;
  static const double chartAxisBand = 16;
  static const double yAxisWidth = 26;
  static const EdgeInsets pagePadding = EdgeInsets.fromLTRB(
    20,
    8,
    20,
    kFloatingCapsuleNavClearance + 12,
  );
  static const EdgeInsets modulePadding = EdgeInsets.fromLTRB(18, 12, 18, 14);
}

class StatisticsGroupedSurface extends StatelessWidget {
  const StatisticsGroupedSurface({
    super.key,
    required this.child,
    this.padding,
    this.emphasized = false,
    this.quiet = false,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final bool emphasized;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    final borderAlpha = quiet ? (isDark ? 0.20 : 0.28) : (isDark ? 0.32 : 0.40);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StatisticsLayout.radius),
        boxShadow: quiet
            ? const []
            : [
                BoxShadow(
                  color: scheme.shadow.withValues(alpha: isDark ? 0.10 : 0.035),
                  blurRadius: emphasized ? 18 : 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StatisticsLayout.radius),
          side: BorderSide(
            color: AppTheme.softCardBorderColor(
              scheme,
            ).withValues(alpha: borderAlpha),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: emphasized
                ? AppTheme.editorialModuleAtmosphereWash(scheme)
                : AppTheme.softCardGroupedGradient(scheme),
          ),
          child: padding == null
              ? child
              : Padding(padding: padding!, child: child),
        ),
      ),
    );
  }
}

class StatisticsSectionTitle extends StatelessWidget {
  const StatisticsSectionTitle({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w800,
        letterSpacing: -0.12,
      ),
    );
  }
}

class StatisticsWhisperLabel extends StatelessWidget {
  const StatisticsWhisperLabel({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelSmall?.copyWith(
        color: scheme.onSurfaceVariant.withValues(alpha: 0.82),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.7,
      ),
    );
  }
}

class StatisticsHairline extends StatelessWidget {
  const StatisticsHairline({super.key, this.indent = 0});

  final double indent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return Divider(
      height: 1,
      indent: indent,
      endIndent: indent,
      color: scheme.outline.withValues(alpha: isDark ? 0.10 : 0.06),
    );
  }
}

class StatisticsTonalCell extends StatelessWidget {
  const StatisticsTonalCell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface.withValues(alpha: isDark ? 0.16 : 0.36),
        borderRadius: BorderRadius.circular(StatisticsLayout.itemRadius),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        child: child,
      ),
    );
  }
}

class StatisticsListingCard extends StatelessWidget {
  const StatisticsListingCard({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = scheme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(StatisticsLayout.itemRadius),
      ),
      child: Material(
        color: Colors.transparent,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(StatisticsLayout.itemRadius),
          side: BorderSide(
            color: AppTheme.softCardBorderColor(
              scheme,
            ).withValues(alpha: isDark ? 0.16 : 0.22),
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.softCardGroupedGradient(scheme),
          ),
          child: child,
        ),
      ),
    );
  }
}

class StatisticsSupportMetric extends StatelessWidget {
  const StatisticsSupportMetric({
    super.key,
    required this.label,
    required this.value,
    this.wrapLabel = false,
  });

  final String label;
  final String value;
  final bool wrapLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Semantics(
      label: '$label $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
              height: 1.05,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            maxLines: wrapLabel ? 2 : 1,
            overflow: wrapLabel ? TextOverflow.clip : TextOverflow.ellipsis,
            softWrap: wrapLabel,
            style:
                (wrapLabel
                        ? theme.textTheme.labelSmall
                        : theme.textTheme.labelMedium)
                    ?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.9),
                      fontWeight: FontWeight.w500,
                      height: wrapLabel ? 1.15 : null,
                    ),
          ),
        ],
      ),
    );
  }
}
