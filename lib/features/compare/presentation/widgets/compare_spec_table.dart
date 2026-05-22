import 'package:flutter/material.dart';

import '../models/compare_spec_models.dart';

/// Mobile-friendly compare spec grid with a fixed label column.
class CompareSpecTable extends StatelessWidget {
  const CompareSpecTable({
    super.key,
    required this.sections,
    required this.columnCount,
    required this.columnWidth,
    this.showSkeleton = false,
  });

  final List<CompareSpecSection> sections;
  final int columnCount;
  final double columnWidth;
  final bool showSkeleton;

  static const double labelWidth = 108;
  static const double rowMinHeight = 44;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    if (sections.isEmpty && !showSkeleton) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var s = 0; s < sections.length; s++) ...[
          if (s > 0) const SizedBox(height: 14),
          _SectionHeader(title: sections[s].title),
          const SizedBox(height: 8),
          Material(
            color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(
                color: scheme.outlineVariant.withValues(alpha: 0.22),
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                for (var r = 0; r < sections[s].rows.length; r++)
                  _SpecRowLine(
                    row: sections[s].rows[r],
                    columnWidth: columnWidth,
                    showSkeleton: showSkeleton,
                    showDivider: r < sections[s].rows.length - 1,
                  ),
              ],
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
    return Text(
      title,
      style: Theme.of(context).textTheme.titleSmall?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.05,
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
  });

  final CompareSpecRow row;
  final double columnWidth;
  final bool showSkeleton;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Container(
      constraints: const BoxConstraints(minHeight: CompareSpecTable.rowMinHeight),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                  color: scheme.outlineVariant.withValues(alpha: 0.18),
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
                padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    row.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
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
                      SizedBox(
                        width: columnWidth,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(8, 10, 8, 10),
                          child: showSkeleton
                              ? _SkeletonBar(scheme: scheme)
                              : _ValueCell(
                                  value: row.values[i],
                                  highlighted: row.highlightIndices.contains(i),
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
  const _ValueCell({required this.value, required this.highlighted});

  final String value;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isMissing = value.trim() == CompareSpecRow.missingToken;

    final text = Text(
      value,
      style: theme.textTheme.bodyMedium?.copyWith(
        fontWeight: highlighted ? FontWeight.w700 : FontWeight.w500,
        color: isMissing
            ? scheme.onSurfaceVariant.withValues(alpha: 0.55)
            : scheme.onSurface,
        height: 1.3,
      ),
    );

    if (!highlighted) return text;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(8),
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
