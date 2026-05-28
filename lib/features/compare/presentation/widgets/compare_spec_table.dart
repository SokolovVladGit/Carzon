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

  static const double labelWidth = 118;
  static const double rowMinHeight = 48;

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
          if (s > 0) const SizedBox(height: 14),
          Material(
            color: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            clipBehavior: Clip.antiAlias,
            child: DecoratedBox(
              decoration: light
                  ? BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.2,
                      ),
                      border: Border.all(
                        color: scheme.outlineVariant.withValues(alpha: 0.2),
                      ),
                      borderRadius: BorderRadius.circular(16),
                    )
                  : AppTheme.editorialDarkSectionCard(
                      scheme,
                      borderRadius: 16,
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
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: light
            ? scheme.surfaceContainerHighest.withValues(alpha: 0.34)
            : Color.alphaBlend(
                scheme.primary.withValues(alpha: 0.10),
                scheme.surfaceContainerHigh,
              ),
        border: Border(
          bottom: BorderSide(
            color: light
                ? scheme.outlineVariant.withValues(alpha: 0.16)
                : scheme.outline.withValues(alpha: 0.26),
          ),
        ),
      ),
      child: Text(
        title,
        style: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w800,
          letterSpacing: -0.05,
          color: light
              ? scheme.onSurfaceVariant
              : scheme.onSurface.withValues(alpha: 0.92),
        ),
        textAlign: TextAlign.left,
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
              ? scheme.primary.withValues(alpha: 0.05)
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
                      ? scheme.outlineVariant.withValues(alpha: 0.18)
                      : scheme.outline.withValues(alpha: 0.24),
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
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 11, 8, 11),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    row.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: light ? 1 : 0.82,
                      ),
                      fontWeight: FontWeight.w600,
                      height: 1.25,
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
                      DecoratedBox(
                        decoration: BoxDecoration(
                          border: i == 0
                              ? null
                              : Border(
                                  left: BorderSide(
                                    color: scheme.outlineVariant.withValues(
                                      alpha: light ? 0.16 : 0.22,
                                    ),
                                  ),
                                ),
                        ),
                        child: SizedBox(
                          width: columnWidth,
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(10, 11, 10, 11),
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
      ),
    );

    if (!highlighted) return text;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppTheme.editorialDarkCompareValueHighlight(
          scheme,
          emphasize: emphasizeDifferences,
        ),
        borderRadius: BorderRadius.circular(8),
        border: !light && emphasizeDifferences
            ? Border.all(
                color: AppTheme.editorialAccentColor(
                  scheme,
                ).withValues(alpha: 0.22),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
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
