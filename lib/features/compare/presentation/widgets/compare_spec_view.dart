import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/compare_item.dart';
import '../../domain/entities/compare_resolved_slot.dart';
import '../cubit/compare_cubit.dart';
import '../cubit/compare_page_cubit.dart';
import '../cubit/compare_page_state.dart';
import '../utils/compare_spec_builder.dart';
import '../models/compare_spec_models.dart';
import 'compare_spec_table.dart';
import 'compare_vehicle_column_header.dart';

/// Premium side-by-side comparison for 2–3 vehicles.
class CompareSpecView extends StatefulWidget {
  const CompareSpecView({
    super.key,
    required this.items,
    required this.onClear,
  });

  final List<CompareItem> items;
  final VoidCallback onClear;

  static const double columnWidth = 164;
  static const double columnGap = 12;

  @override
  State<CompareSpecView> createState() => _CompareSpecViewState();
}

class _CompareSpecViewState extends State<CompareSpecView> {
  bool _showOnlyDifferences = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _resolve());
  }

  @override
  void didUpdateWidget(CompareSpecView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameItems(oldWidget.items, widget.items)) {
      _resolve();
    }
  }

  bool _sameItems(List<CompareItem> a, List<CompareItem> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].listingId != b[i].listingId) return false;
    }
    return true;
  }

  void _resolve() {
    context.read<ComparePageCubit>().resolve(widget.items);
  }

  void _remove(String listingId) {
    context.read<CompareCubit>().remove(listingId);
  }

  BoxDecoration _summaryCardDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return AppTheme.editorialDarkSectionCard(scheme, borderRadius: 20)!;
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.24),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
      boxShadow: [
        BoxShadow(
          color: scheme.shadow.withValues(alpha: 0.06),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  BoxDecoration _toggleRowDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return AppTheme.editorialDarkSectionCard(scheme, borderRadius: 16)!;
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      color: scheme.surfaceContainerHighest.withValues(alpha: 0.26),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final light = theme.brightness == Brightness.light;

    return BlocBuilder<ComparePageCubit, ComparePageState>(
      builder: (context, pageState) {
        final slots = pageState.slots;
        final count = widget.items.length;
        final allSections = slots.isEmpty
            ? <CompareSpecSection>[]
            : CompareSpecBuilder(l10n, slots).buildSections();
        final visibleSections = _showOnlyDifferences
            ? filterOnlyDifferences(allSections)
            : allSections;
        final showSkeleton = pageState.isResolving && slots.isNotEmpty;
        final differingRowsCount = allSections.fold<int>(
          0,
          (acc, section) =>
              acc + section.rows.where((row) => !row.allValuesEqual).length,
        );

        return DecoratedBox(
          decoration: BoxDecoration(
            gradient: light
                ? null
                : LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: AppTheme.editorialDarkCompareCanvasGradient(scheme),
                    stops: const [0, 0.42, 1],
                  ),
            color: light ? scheme.surface : null,
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 34),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: _summaryCardDecoration(scheme, light),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.compareVehiclesTitle,
                                    style: theme.textTheme.titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.w800,
                                          letterSpacing: -0.15,
                                          color: scheme.onSurface.withValues(
                                            alpha: light ? 1 : 0.98,
                                          ),
                                        ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.compareVehicleCountShort(count),
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant.withValues(
                                        alpha: light ? 1 : 0.78,
                                      ),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              key: const ValueKey('compare_clear_button'),
                              onPressed: widget.onClear,
                              icon: Icon(
                                Icons.delete_outline_rounded,
                                size: 16,
                                color: light
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurfaceVariant.withValues(
                                        alpha: 0.88,
                                      ),
                              ),
                              label: Text(l10n.compareClear),
                              style: TextButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                                foregroundColor: light
                                    ? scheme.onSurfaceVariant
                                    : scheme.onSurfaceVariant.withValues(
                                        alpha: 0.88,
                                      ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (var i = 0; i < widget.items.length; i++)
                                Padding(
                                  padding: EdgeInsets.only(
                                    right: i < widget.items.length - 1
                                        ? CompareSpecView.columnGap
                                        : 0,
                                  ),
                                  child: CompareVehicleColumnHeader(
                                    key: ValueKey(widget.items[i].listingId),
                                    slot: i < slots.length
                                        ? slots[i]
                                        : CompareResolvedSlot(
                                            item: widget.items[i],
                                            phase: CompareSlotPhase.loading,
                                          ),
                                    width: 194,
                                    onRemove: () =>
                                        _remove(widget.items[i].listingId),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DecoratedBox(
                  decoration: _toggleRowDecoration(scheme, light),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                    child: Row(
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            gradient: light
                                ? null
                                : RadialGradient(
                                    colors: [
                                      Color.alphaBlend(
                                        scheme.primary.withValues(alpha: 0.22),
                                        scheme.surfaceContainerHigh,
                                      ),
                                      scheme.surfaceContainerLow,
                                    ],
                                  ),
                            color: light
                                ? scheme.primary.withValues(alpha: 0.12)
                                : null,
                            borderRadius: BorderRadius.circular(10),
                            border: light
                                ? null
                                : Border.all(
                                    color: AppTheme.editorialAccentColor(
                                      scheme,
                                    ).withValues(alpha: 0.35),
                                  ),
                          ),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 18,
                            color: light
                                ? scheme.primary
                                : AppTheme.editorialAccentColor(scheme),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.compareShowOnlyDifferences,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface.withValues(
                                    alpha: light ? 1 : 0.96,
                                  ),
                                ),
                              ),
                              if (differingRowsCount == 0)
                                Text(
                                  l10n.compareNoDifferences,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: light ? 1 : 0.76,
                                    ),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        Switch(
                          key: const ValueKey('compare_diff_toggle'),
                          value: _showOnlyDifferences,
                          onChanged: (v) =>
                              setState(() => _showOnlyDifferences = v),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                if (_showOnlyDifferences &&
                    !pageState.isResolving &&
                    visibleSections.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      l10n.compareNoDifferences,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant.withValues(
                          alpha: light ? 1 : 0.76,
                        ),
                      ),
                    ),
                  )
                else
                  CompareSpecTable(
                    sections: _showOnlyDifferences && visibleSections.isNotEmpty
                        ? visibleSections
                        : allSections,
                    columnCount: count,
                    columnWidth: CompareSpecView.columnWidth,
                    showSkeleton: showSkeleton,
                    emphasizeDifferences: _showOnlyDifferences,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
