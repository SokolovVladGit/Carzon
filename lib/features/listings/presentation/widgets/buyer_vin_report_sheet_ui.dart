import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../utils/nhtsa_vin_summary_display.dart';
import 'vin_present_latin_badge.dart';

/// Extra scroll/footer clearance so content stays above the floating compare tray
/// when the sheet is opened from listing details (tray remains in root overlay).
const double kBuyerVinReportCompareTrayScrollClearance = 80;

/// Calm product microcopy (notes, footnotes) — no aggressive italic.
TextStyle buyerVinReportMicrocopyStyle(ThemeData theme) {
  final scheme = theme.colorScheme;
  final isDark = theme.brightness == Brightness.dark;
  return theme.textTheme.bodySmall!.copyWith(
    height: 1.45,
    fontWeight: FontWeight.w400,
    fontSize: (theme.textTheme.bodySmall?.fontSize ?? 12) - 0.5,
    color: scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.68 : 0.72),
  );
}

BoxDecoration _buyerVinReportEditorialCard(
  ColorScheme scheme, {
  required double borderRadius,
}) {
  return AppTheme.editorialDarkSectionCard(scheme, borderRadius: borderRadius)!;
}

BoxDecoration _buyerVinReportDarkDataInset(ColorScheme scheme) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(10),
    color: scheme.surfaceContainerHigh.withValues(alpha: 0.42),
    border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
  );
}

/// Visual variants for buyer VIN report section cards.
enum BuyerVinReportSectionTone {
  summary,
  dataCore,
  dataSpecs,
  dataOrigin,
  sourceMeta,
  limitations,
  manualModule,
}

BoxDecoration buyerVinReportSectionDecoration(
  ColorScheme scheme,
  BuyerVinReportSectionTone tone,
) {
  if (scheme.brightness == Brightness.dark) {
    switch (tone) {
      case BuyerVinReportSectionTone.limitations:
        final warm = Color.alphaBlend(
          const Color(0xFFE8B87A).withValues(alpha: 0.16),
          scheme.surfaceContainerHigh,
        );
        return BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: warm,
          border: Border.all(
            color: const Color(0xFFD4A574).withValues(alpha: 0.38),
          ),
          boxShadow: [
            BoxShadow(
              color: scheme.primary.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
              spreadRadius: -4,
            ),
          ],
        );
      case BuyerVinReportSectionTone.manualModule:
        return _buyerVinReportEditorialCard(scheme, borderRadius: 14);
      default:
        return _buyerVinReportEditorialCard(scheme, borderRadius: 16);
    }
  }

  final radius = BorderRadius.circular(14);
  switch (tone) {
    case BuyerVinReportSectionTone.summary:
      return BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.surfaceContainerHigh.withValues(alpha: 0.55),
            scheme.surfaceContainerHighest.withValues(alpha: 0.38),
          ],
        ),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.42),
        ),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 6),
            spreadRadius: -4,
          ),
        ],
      );
    case BuyerVinReportSectionTone.dataCore:
      return BoxDecoration(
        borderRadius: radius,
        color: scheme.surface.withValues(alpha: 0.72),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.28),
        ),
      );
    case BuyerVinReportSectionTone.dataSpecs:
      return BoxDecoration(
        borderRadius: radius,
        color: scheme.surface.withValues(alpha: 0.68),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.26),
        ),
      );
    case BuyerVinReportSectionTone.dataOrigin:
      return BoxDecoration(
        borderRadius: radius,
        color: scheme.surface.withValues(alpha: 0.62),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.24),
        ),
      );
    case BuyerVinReportSectionTone.sourceMeta:
      return BoxDecoration(
        borderRadius: radius,
        color: scheme.surfaceContainerHigh.withValues(alpha: 0.28),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.34),
        ),
      );
    case BuyerVinReportSectionTone.limitations:
      final warm = Color.alphaBlend(
        const Color(0xFFFFF3E8).withValues(alpha: 0.55),
        scheme.surfaceContainerHigh.withValues(alpha: 0.35),
      );
      return BoxDecoration(
        borderRadius: radius,
        color: warm,
        border: Border.all(
          color: const Color(0xFFE8C9A8).withValues(alpha: 0.45),
        ),
      );
    case BuyerVinReportSectionTone.manualModule:
      return BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: scheme.surface,
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: scheme.shadow.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 3),
            spreadRadius: -2,
          ),
        ],
      );
  }
}

/// Premium section shell with title header.
class BuyerVinReportSectionCard extends StatelessWidget {
  const BuyerVinReportSectionCard({
    super.key,
    required this.theme,
    required this.tone,
    required this.title,
    required this.child,
    this.subtitle,
    this.leadingIcon,
    this.padding = const EdgeInsets.fromLTRB(14, 12, 14, 12),
  });

  final ThemeData theme;
  final BuyerVinReportSectionTone tone;
  final String title;
  final String? subtitle;
  final IconData? leadingIcon;
  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: buyerVinReportSectionDecoration(scheme, tone),
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (leadingIcon != null) ...[
                  Icon(
                    leadingIcon,
                    size: 18,
                    color: isDark
                        ? AppTheme.editorialAccentColor(
                            scheme,
                          ).withValues(alpha: 0.78)
                        : scheme.onSurfaceVariant.withValues(alpha: 0.85),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.1,
                          height: 1.2,
                          color: isDark
                              ? scheme.onSurface.withValues(alpha: 0.92)
                              : scheme.onSurface.withValues(alpha: 0.88),
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 3),
                        Text(
                          subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            height: 1.35,
                            color: scheme.onSurfaceVariant.withValues(
                              alpha: isDark ? 0.82 : 1,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

/// Compact hero: title, VIN badge, seller/privacy lines, optional compare result.
class BuyerVinReportHeroHeader extends StatelessWidget {
  const BuyerVinReportHeroHeader({
    super.key,
    required this.theme,
    required this.reportTitle,
    required this.vinAddedLine,
    required this.vinPrivateLine,
    this.compareResult,
    this.compareIsMatch,
    this.showSuccessVinBadge = false,
  });

  final ThemeData theme;
  final String reportTitle;
  final String vinAddedLine;
  final String vinPrivateLine;
  final String? compareResult;
  final bool? compareIsMatch;

  /// Green Latin V badge only when [BuyerVinReportUiState.reportAvailable].
  final bool showSuccessVinBadge;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final decoration = isDark
        ? _buyerVinReportEditorialCard(scheme, borderRadius: 14)
        : BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: scheme.surface.withValues(alpha: 0.82),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          );
    return DecoratedBox(
      key: const ValueKey('buyer_vin_report_hero_header'),
      decoration: decoration,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reportTitle,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1.15,
                          color: isDark
                              ? scheme.onSurface.withValues(alpha: 0.96)
                              : scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        vinAddedLine,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.35,
                          fontWeight: FontWeight.w500,
                          color: scheme.onSurface.withValues(
                            alpha: isDark ? 0.88 : 0.82,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: showSuccessVinBadge
                      ? const VinPresentLatinBadge(heroSize: true)
                      : const VinNeutralLatinBadge(heroSize: true),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              vinPrivateLine,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.4,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.84 : 0.95,
                ),
              ),
            ),
            if (compareResult != null) ...[
              const SizedBox(height: 10),
              _HeroCompareResultLine(
                theme: theme,
                text: compareResult!,
                isMatch: compareIsMatch == true,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _HeroCompareResultLine extends StatelessWidget {
  const _HeroCompareResultLine({
    required this.theme,
    required this.text,
    required this.isMatch,
  });

  final ThemeData theme;
  final String text;
  final bool isMatch;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final accent = isMatch ? scheme.primary : scheme.tertiary;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(
          isMatch ? Icons.check_circle_outline : Icons.info_outline_rounded,
          size: 16,
          color: accent.withValues(alpha: isDark ? 0.88 : 0.82),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: (isMatch
                    ? theme.textTheme.bodySmall
                    : theme.textTheme.bodyMedium)
                ?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: isMatch
                  ? accent.withValues(alpha: isDark ? 0.92 : 0.88)
                  : scheme.onSurface.withValues(alpha: isDark ? 0.9 : 0.86),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lightweight source/disclaimer footer below decoded data.
class BuyerVinReportFooterStrip extends StatelessWidget {
  const BuyerVinReportFooterStrip({
    super.key,
    required this.theme,
    this.sourceLine,
    this.updatedDate,
    this.disclaimerLine,
    this.cautionLine,
  });

  final ThemeData theme;
  final String? sourceLine;
  final String? updatedDate;
  final String? disclaimerLine;
  final String? cautionLine;

  @override
  Widget build(BuildContext context) {
    if (sourceLine == null &&
        updatedDate == null &&
        disclaimerLine == null &&
        cautionLine == null) {
      return const SizedBox.shrink();
    }

    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final muted = scheme.onSurfaceVariant.withValues(alpha: isDark ? 0.58 : 0.62);
    final noteStyle = theme.textTheme.labelSmall?.copyWith(
      height: 1.35,
      fontWeight: FontWeight.w400,
      fontSize: (theme.textTheme.labelSmall?.fontSize ?? 11) - 0.5,
      color: muted,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Divider(
            height: 1,
            thickness: 1,
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.14 : 0.18),
          ),
          const SizedBox(height: 8),
          if (sourceLine != null) Text(sourceLine!, style: noteStyle),
          if (updatedDate != null) ...[
            if (sourceLine != null) const SizedBox(height: 2),
            Text(updatedDate!, style: noteStyle),
          ],
          if (disclaimerLine != null) ...[
            if (sourceLine != null || updatedDate != null)
              const SizedBox(height: 3),
            Text(disclaimerLine!, style: noteStyle),
          ],
          if (cautionLine != null) ...[
            const SizedBox(height: 3),
            Text(cautionLine!, style: noteStyle),
          ],
        ],
      ),
    );
  }
}

/// Compact source/date metadata inside the hero.
class BuyerVinReportMetadataStrip extends StatelessWidget {
  const BuyerVinReportMetadataStrip({
    super.key,
    required this.theme,
    this.sourceLine,
    this.updatedLabel,
    this.updatedDate,
    this.basicDecodeLine,
    this.cautionLine,
  });

  final ThemeData theme;
  final String? sourceLine;
  final String? updatedLabel;
  final String? updatedDate;
  final String? basicDecodeLine;
  final String? cautionLine;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: isDark
          ? _buyerVinReportDarkDataInset(scheme)
          : BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.32),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (sourceLine != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.source_outlined,
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sourceLine!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            if (updatedLabel != null && updatedDate != null) ...[
              if (sourceLine != null) const SizedBox(height: 8),
              BuyerVinReportMetaRow(
                theme: theme,
                label: updatedLabel!,
                value: updatedDate!,
              ),
            ],
            if (basicDecodeLine != null) ...[
              if (sourceLine != null ||
                  (updatedLabel != null && updatedDate != null))
                const SizedBox(height: 8),
              Text(
                basicDecodeLine!,
                style: theme.textTheme.labelMedium?.copyWith(
                  height: 1.35,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface.withValues(alpha: 0.88),
                ),
              ),
            ],
            if (cautionLine != null) ...[
              const SizedBox(height: 6),
              Text(cautionLine!, style: buyerVinReportMicrocopyStyle(theme)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Core identity panel: 2-column grid for short fields + full-width long values.
class BuyerVinReportIdentityPanel extends StatelessWidget {
  const BuyerVinReportIdentityPanel({
    super.key,
    required this.theme,
    required this.fields,
  });

  final ThemeData theme;
  final List<NhtsaVinSummaryField> fields;

  static const Set<String> _gridKeys = {'make', 'model', 'year'};

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final gridFields = <NhtsaVinSummaryField>[];
    final longFields = <NhtsaVinSummaryField>[];

    for (final f in fields) {
      final key = f.fieldKey;
      if (key != null && _gridKeys.contains(key)) {
        gridFields.add(f);
      } else {
        longFields.add(f);
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (gridFields.isNotEmpty)
          DecoratedBox(
            decoration: isDark
                ? _buyerVinReportDarkDataInset(scheme)
                : BoxDecoration(
                    color: scheme.surface.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: scheme.outlineVariant.withValues(alpha: 0.22),
                    ),
                  ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final twoCol = constraints.maxWidth > 280;
                  if (!twoCol) {
                    return Column(
                      children: [
                        for (var i = 0; i < gridFields.length; i++) ...[
                          _IdentityGridCell(theme: theme, field: gridFields[i]),
                          if (i < gridFields.length - 1)
                            const SizedBox(height: 8),
                        ],
                      ],
                    );
                  }
                  return Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final f in gridFields)
                        SizedBox(
                          width: (constraints.maxWidth - 8) / 2,
                          child: _IdentityGridCell(theme: theme, field: f),
                        ),
                    ],
                  );
                },
              ),
            ),
          ),
        if (longFields.isNotEmpty) ...[
          if (gridFields.isNotEmpty) const SizedBox(height: 10),
          BuyerVinReportSpecTable(
            theme: theme,
            fields: longFields,
            compact: true,
          ),
        ],
      ],
    );
  }
}

class _IdentityGridCell extends StatelessWidget {
  const _IdentityGridCell({required this.theme, required this.field});

  final ThemeData theme;
  final NhtsaVinSummaryField field;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: isDark
          ? BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: Color.alphaBlend(
                scheme.onSurface.withValues(alpha: 0.04),
                scheme.surfaceContainerHigh.withValues(alpha: 0.65),
              ),
              border: Border.all(color: scheme.outline.withValues(alpha: 0.22)),
            )
          : BoxDecoration(
              color: scheme.surface.withValues(alpha: 0.65),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.25),
              ),
            ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              field.label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.82 : 1,
                ),
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              field.value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.35,
                letterSpacing: -0.05,
                color: isDark ? scheme.onSurface.withValues(alpha: 0.94) : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Top report summary (privacy + optional listing compare).
class BuyerVinReportSummaryIntroCard extends StatelessWidget {
  const BuyerVinReportSummaryIntroCard({
    super.key,
    required this.theme,
    required this.vinAddedLine,
    required this.vinPrivateLine,
    this.compareHint,
    this.compareResult,
    this.compareIsMatch,
  });

  final ThemeData theme;
  final String vinAddedLine;
  final String vinPrivateLine;
  final String? compareHint;
  final String? compareResult;
  final bool? compareIsMatch;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return DecoratedBox(
      decoration: buyerVinReportSectionDecoration(
        scheme,
        BuyerVinReportSectionTone.summary,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.description_outlined,
                  size: 20,
                  color: scheme.primary.withValues(alpha: 0.75),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    vinAddedLine,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            _SummaryBullet(
              theme: theme,
              icon: Icons.lock_outline_rounded,
              text: vinPrivateLine,
            ),
            if (compareHint != null && compareResult != null) ...[
              const SizedBox(height: 12),
              DecoratedBox(
                decoration: BoxDecoration(
                  color:
                      (compareIsMatch == true
                              ? scheme.primaryContainer
                              : scheme.tertiaryContainer)
                          .withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.35),
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        compareHint!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          height: 1.35,
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        compareResult!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          height: 1.4,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SummaryBullet extends StatelessWidget {
  const _SummaryBullet({
    required this.theme,
    required this.icon,
    required this.text,
  });

  final ThemeData theme;
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

/// Source / date / decode disclaimer block.
class BuyerVinReportSourceMetaCard extends StatelessWidget {
  const BuyerVinReportSourceMetaCard({
    super.key,
    required this.theme,
    required this.sourceLine,
    required this.basicDecodeLine,
    required this.notOfficialLine,
    this.updatedLabel,
    this.updatedDate,
    this.cautionLine,
  });

  final ThemeData theme;
  final String sourceLine;
  final String basicDecodeLine;
  final String notOfficialLine;
  final String? updatedLabel;
  final String? updatedDate;
  final String? cautionLine;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return BuyerVinReportSectionCard(
      theme: theme,
      tone: BuyerVinReportSectionTone.sourceMeta,
      title: sourceLine,
      leadingIcon: Icons.source_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cautionLine != null) ...[
            Text(cautionLine!, style: buyerVinReportMicrocopyStyle(theme)),
            const SizedBox(height: 10),
          ],
          if (updatedLabel != null && updatedDate != null)
            BuyerVinReportMetaRow(
              theme: theme,
              label: updatedLabel!,
              value: updatedDate!,
            ),
          if (updatedLabel != null && updatedDate != null)
            const SizedBox(height: 10),
          Text(
            basicDecodeLine,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            notOfficialLine,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.42,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class BuyerVinReportMetaRow extends StatelessWidget {
  const BuyerVinReportMetaRow({
    super.key,
    required this.theme,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 108,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.35,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}

BuyerVinReportSectionTone buyerVinReportToneForGroupIndex(int index) {
  return switch (index) {
    0 => BuyerVinReportSectionTone.dataCore,
    1 => BuyerVinReportSectionTone.dataSpecs,
    _ => BuyerVinReportSectionTone.dataOrigin,
  };
}

IconData? buyerVinReportIconForGroupIndex(int index) {
  return switch (index) {
    0 => Icons.directions_car_outlined,
    1 => Icons.tune_rounded,
    _ => Icons.public_outlined,
  };
}

/// NHTSA group rendered as a premium spec-sheet section.
class BuyerVinReportNhtsaGroupSection extends StatelessWidget {
  const BuyerVinReportNhtsaGroupSection({
    super.key,
    required this.theme,
    required this.group,
    required this.groupIndex,
  });

  final ThemeData theme;
  final NhtsaVinSummaryGroup group;
  final int groupIndex;

  @override
  Widget build(BuildContext context) {
    final tone = buyerVinReportToneForGroupIndex(groupIndex);
    final isCore = groupIndex == 0;
    final isSpecs = tone == BuyerVinReportSectionTone.dataSpecs;

    Widget body;
    if (isCore) {
      body = BuyerVinReportIdentityPanel(theme: theme, fields: group.fields);
    } else if (isSpecs) {
      body = BuyerVinReportSpecTable(theme: theme, fields: group.fields);
    } else {
      body = BuyerVinReportSpecTable(
        theme: theme,
        fields: group.fields,
        compact: true,
      );
    }

    return BuyerVinReportSectionCard(
      theme: theme,
      tone: tone,
      title: group.title,
      leadingIcon: buyerVinReportIconForGroupIndex(groupIndex),
      padding: EdgeInsets.fromLTRB(14, 12, 14, isSpecs ? 10 : 12),
      child: body,
    );
  }
}

/// Premium spec rows with dividers and adaptive stacked layout.
class BuyerVinReportSpecTable extends StatelessWidget {
  const BuyerVinReportSpecTable({
    super.key,
    required this.theme,
    required this.fields,
    this.compact = false,
  });

  final ThemeData theme;
  final List<NhtsaVinSummaryField> fields;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    return DecoratedBox(
      decoration: isDark
          ? _buyerVinReportDarkDataInset(scheme)
          : BoxDecoration(
              color: scheme.surface.withValues(alpha: compact ? 0.5 : 0.58),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Column(
          children: [
            for (var i = 0; i < fields.length; i++) ...[
              BuyerVinReportSpecRow(
                theme: theme,
                label: fields[i].label,
                value: fields[i].value,
                forceStacked: fields[i].stackValue,
                striped: i.isOdd,
                isLast: i == fields.length - 1,
              ),
              if (i < fields.length - 1)
                Divider(
                  height: 1,
                  thickness: 1,
                  color: scheme.outlineVariant.withValues(
                    alpha: isDark ? 0.18 : 0.22,
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Single spec row — compact row or stacked for long catalog strings.
class BuyerVinReportSpecRow extends StatelessWidget {
  const BuyerVinReportSpecRow({
    super.key,
    required this.theme,
    required this.label,
    required this.value,
    this.forceStacked = false,
    this.striped = false,
    this.isLast = false,
  });

  final ThemeData theme;
  final String label;
  final String value;
  final bool forceStacked;
  final bool striped;
  final bool isLast;

  static const int _stackedCharThreshold = 24;

  bool get _useStacked =>
      forceStacked || value.characters.length > _stackedCharThreshold;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final bg = striped
        ? scheme.onSurface.withValues(alpha: isDark ? 0.03 : 0.018)
        : Colors.transparent;

    return ColoredBox(
      color: bg,
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, 10, 12, isLast ? 10 : 10),
        child: _useStacked
            ? _StackedSpecContent(theme: theme, label: label, value: value)
            : _InlineSpecContent(theme: theme, label: label, value: value),
      ),
    );
  }
}

class _InlineSpecContent extends StatelessWidget {
  const _InlineSpecContent({
    required this.theme,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 124,
          child: Text(
            label,
            style: theme.textTheme.labelMedium?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              height: 1.3,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.4,
              fontWeight: FontWeight.w500,
              letterSpacing: -0.05,
            ),
          ),
        ),
      ],
    );
  }
}

class _StackedSpecContent extends StatelessWidget {
  const _StackedSpecContent({
    required this.theme,
    required this.label,
    required this.value,
  });

  final ThemeData theme;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
            height: 1.3,
            letterSpacing: 0.05,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.5,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.02,
          ),
        ),
      ],
    );
  }
}

/// Polished non-spec state body (pending / no data / error).
class BuyerVinReportStateMessageCard extends StatelessWidget {
  const BuyerVinReportStateMessageCard({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    this.note,
    this.tone = BuyerVinReportSectionTone.sourceMeta,
    this.icon = Icons.info_outline_rounded,
  });

  final ThemeData theme;
  final String title;
  final String body;
  final String? note;
  final BuyerVinReportSectionTone tone;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return BuyerVinReportSectionCard(
      theme: theme,
      tone: tone,
      title: title,
      leadingIcon: icon,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            body,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.48,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.9),
            ),
          ),
          if (note != null) ...[
            const SizedBox(height: 10),
            Text(note!, style: buyerVinReportMicrocopyStyle(theme)),
          ],
        ],
      ),
    );
  }
}

/// Fill for buyer VIN report floating CTA — slightly lifted primary for crisp white label.
Color buyerVinReportCtaFill(ColorScheme scheme) {
  return Color.alphaBlend(Colors.white.withValues(alpha: 0.1), scheme.primary);
}

/// Floating bottom action bar for buyer VIN report sheet.
class BuyerVinReportStickyFooter extends StatelessWidget {
  const BuyerVinReportStickyFooter({
    super.key,
    required this.theme,
    required this.bottomInset,
    required this.closeLabel,
    required this.onClose,
  });

  final ThemeData theme;
  final double bottomInset;
  final String closeLabel;
  final VoidCallback onClose;

  static const double _pillHeight = 52;
  static const double _pillRadius = 26;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final fill = buyerVinReportCtaFill(scheme);
    final fadeTop = isDark
        ? scheme.surfaceContainerLow.withValues(alpha: 0)
        : scheme.surface.withValues(alpha: 0);
    final fadeBottom = isDark
        ? Color.alphaBlend(
            scheme.surfaceContainerHigh.withValues(alpha: 0.92),
            scheme.surface,
          )
        : scheme.surface.withValues(alpha: 0.85);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IgnorePointer(
          child: Container(
            height: 28,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [fadeTop, fadeBottom],
              ),
            ),
          ),
        ),
        if (isDark)
          DecoratedBox(
            decoration:
                AppTheme.editorialDarkFilterFooter(scheme) ??
                BoxDecoration(color: scheme.surface),
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, 12 + bottomInset),
              child: Material(
                key: const ValueKey('buyer_vin_report_sheet_close'),
                color: fill,
                elevation: 0,
                borderRadius: BorderRadius.circular(_pillRadius),
                child: InkWell(
                  onTap: onClose,
                  borderRadius: BorderRadius.circular(_pillRadius),
                  child: SizedBox(
                    width: double.infinity,
                    height: _pillHeight,
                    child: Center(
                      child: Text(
                        closeLabel,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.15,
                          height: 1.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          )
        else
          Padding(
            padding: EdgeInsets.fromLTRB(20, 4, 20, 12 + bottomInset),
            child: Material(
              key: const ValueKey('buyer_vin_report_sheet_close'),
              color: fill,
              elevation: 2,
              shadowColor: scheme.shadow.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(_pillRadius),
              child: InkWell(
                onTap: onClose,
                borderRadius: BorderRadius.circular(_pillRadius),
                child: SizedBox(
                  width: double.infinity,
                  height: _pillHeight,
                  child: Center(
                    child: Text(
                      closeLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.15,
                        height: 1.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
