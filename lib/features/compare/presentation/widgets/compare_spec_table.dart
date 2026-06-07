import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../models/compare_spec_models.dart';

/// Mobile-friendly compare spec grid with a fixed label column.
class CompareSpecTable extends StatelessWidget {
  const CompareSpecTable({
    super.key,
    required this.sections,
    required this.columnCount,
    required this.columnWidth,
    this.showSkeleton = false,
    this.emphasizeDifferences = false,
  });

  final List<CompareSpecSection> sections;
  final int columnCount;
  final double columnWidth;
  final bool showSkeleton;
  final bool emphasizeDifferences;

  static const double labelWidth = 142;
  static const double rowMinHeight = 52;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    if (sections.isEmpty && !showSkeleton) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var s = 0; s < sections.length; s++) ...[
          if (s > 0) const SizedBox(height: 18),
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: light
                  ? BoxDecoration(
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.26),
                      ),
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFFAFBFD),
                          Color(0xFFF6F8FB),
                        ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(
                            0xFF243447,
                          ).withValues(alpha: 0.07),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                          spreadRadius: -18,
                        ),
                      ],
                    )
                  : AppTheme.editorialDarkSectionCard(
                      scheme,
                      borderRadius: 24,
                    )!,
              child: Column(
                children: [
                  _SectionHeader(title: sections[s].title),
                  for (var r = 0; r < sections[s].rows.length; r++)
                    _SpecRowLine(
                      row: sections[s].rows[r],
                      columnWidth: columnWidth,
                      showSkeleton: showSkeleton,
                      showDivider: r < sections[s].rows.length - 1,
                      emphasizeDifferences: emphasizeDifferences,
                      showDifferenceTint:
                          emphasizeDifferences &&
                          !sections[s].rows[r].allValuesEqual,
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(15, 14, 15, 13),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: light
              ? [const Color(0xFFF3F7FA), const Color(0xFFFAFBFD)]
              : [
                  Color.alphaBlend(
                    scheme.primary.withValues(alpha: 0.12),
                    scheme.surfaceContainerHigh,
                  ),
                  Color.alphaBlend(
                    scheme.onSurface.withValues(alpha: 0.03),
                    scheme.surfaceContainerLow,
                  ),
                ],
        ),
        border: Border(
          bottom: BorderSide(
            color: light
                ? scheme.outlineVariant.withValues(alpha: 0.09)
                : scheme.outline.withValues(alpha: 0.18),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: light
                    ? scheme.primary.withValues(alpha: 0.12)
                    : AppTheme.editorialAccentColor(
                        scheme,
                      ).withValues(alpha: 0.30),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: light
                    ? [
                        scheme.primary.withValues(alpha: 0.11),
                        scheme.primary.withValues(alpha: 0.035),
                      ]
                    : [
                        Color.alphaBlend(
                          scheme.primary.withValues(alpha: 0.18),
                          scheme.surfaceContainerHigh,
                        ),
                        scheme.surfaceContainerLow,
                      ],
              ),
            ),
            child: Icon(
              Icons.view_week_rounded,
              size: 15,
              color: light
                  ? scheme.primary
                  : AppTheme.editorialAccentColor(scheme),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.04,
                color: light
                    ? scheme.onSurface.withValues(alpha: 0.82)
                    : scheme.onSurface.withValues(alpha: 0.92),
              ),
              textAlign: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpecRowLine extends StatelessWidget {
  const _SpecRowLine({
    required this.row,
    required this.columnWidth,
    required this.showSkeleton,
    required this.showDivider,
    required this.emphasizeDifferences,
    required this.showDifferenceTint,
  });

  final CompareSpecRow row;
  final double columnWidth;
  final bool showSkeleton;
  final bool showDivider;
  final bool emphasizeDifferences;
  final bool showDifferenceTint;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    final rowTint = showDifferenceTint
        ? (light
              ? Color.alphaBlend(
                  scheme.primary.withValues(alpha: 0.048),
                  const Color(0xFFFAFCFE),
                )
              : AppTheme.editorialDarkCompareDifferenceRowTint(scheme))
        : Colors.transparent;

    return Container(
      constraints: const BoxConstraints(
        minHeight: CompareSpecTable.rowMinHeight,
      ),
      decoration: BoxDecoration(
        color: rowTint,
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: light
                      ? scheme.outlineVariant.withValues(alpha: 0.075)
                      : scheme.outline.withValues(alpha: 0.14),
                ),
              )
            : null,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: CompareSpecTable.labelWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: light
                        ? [
                            const Color(0xFFF8FAFC).withValues(alpha: 0.70),
                            const Color(0xFFF8FAFC).withValues(alpha: 0.16),
                          ]
                        : [
                            scheme.surfaceContainerHigh.withValues(alpha: 0.20),
                            scheme.surfaceContainerHigh.withValues(alpha: 0.04),
                          ],
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(15, 13, 12, 13),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      row.label,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: light ? 0.82 : 0.82,
                        ),
                        fontWeight: FontWeight.w700,
                        height: 1.22,
                        letterSpacing: -0.05,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < row.values.length; i++)
                      Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                        child: SizedBox(
                          width: columnWidth,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(12, 13, 12, 13),
                            child: showSkeleton
                                ? _SkeletonBar(scheme: scheme)
                                : _ValueCell(
                                    value: row.values[i],
                                    highlighted: row.highlightIndices.contains(
                                      i,
                                    ),
                                    emphasizeDifferences: emphasizeDifferences,
                                  ),
                          ),
                        ),
                      ),
                    const SizedBox(width: 12),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ValueCell extends StatelessWidget {
  const _ValueCell({
    required this.value,
    required this.highlighted,
    required this.emphasizeDifferences,
  });

  final String value;
  final bool highlighted;
  final bool emphasizeDifferences;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;
    final isMissing = value.trim() == CompareSpecRow.missingToken;

    final text = Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
        color: isMissing
            ? scheme.onSurfaceVariant.withValues(alpha: light ? 0.55 : 0.62)
            : scheme.onSurface.withValues(alpha: light ? 1 : 0.94),
        height: 1.3,
        letterSpacing: -0.05,
      ),
    );

    if (!highlighted) return text;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: light
            ? Color.alphaBlend(
                scheme.primary.withValues(
                  alpha: emphasizeDifferences ? 0.095 : 0.055,
                ),
                const Color(0xFFF9FBFD),
              )
            : AppTheme.editorialDarkCompareValueHighlight(
                scheme,
                emphasize: emphasizeDifferences,
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: light
              ? scheme.primary.withValues(
                  alpha: emphasizeDifferences ? 0.15 : 0.06,
                )
              : AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: emphasizeDifferences ? 0.22 : 0.10),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        child: text,
      ),
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.scheme});

  final ColorScheme scheme;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        height: 12,
        width: double.infinity,
        decoration: BoxDecoration(
          color: scheme.onSurface.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
        ),
      ),
    );
  }
}
