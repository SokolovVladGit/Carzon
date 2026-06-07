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

  static const double columnWidth = 170;
  static const double columnGap = 14;

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

  BoxDecoration _canvasDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: AppTheme.editorialDarkCompareCanvasGradient(scheme),
          stops: const [0, 0.42, 1],
        ),
      );
    }
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFDFEFF),
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.035),
            const Color(0xFFF4F7FB),
          ),
          const Color(0xFFEFF3F8),
        ],
        stops: const [0, 0.48, 1],
      ),
    );
  }

  BoxDecoration _summaryCardDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return AppTheme.editorialDarkSectionCard(scheme, borderRadius: 26)!;
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(26),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.42)),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,
          Color.alphaBlend(
            scheme.primary.withValues(alpha: 0.026),
            const Color(0xFFF7FAFD),
          ),
        ],
      ),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF1E2A36).withValues(alpha: 0.09),
          blurRadius: 30,
          offset: const Offset(0, 16),
          spreadRadius: -14,
        ),
        BoxShadow(
          color: Colors.white.withValues(alpha: 0.78),
          blurRadius: 1,
          offset: const Offset(0, 1),
        ),
      ],
    );
  }

  BoxDecoration _toggleRowDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return AppTheme.editorialDarkSectionCard(scheme, borderRadius: 20)!;
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      color: Colors.white.withValues(alpha: 0.92),
      border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.42)),
      boxShadow: [
        BoxShadow(
          color: const Color(0xFF243447).withValues(alpha: 0.06),
          blurRadius: 22,
          offset: const Offset(0, 12),
          spreadRadius: -14,
        ),
      ],
    );
  }

  BoxDecoration _iconCapsuleDecoration(ColorScheme scheme, bool light) {
    if (!light) {
      return BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppTheme.editorialAccentColor(scheme).withValues(alpha: 0.34),
        ),
        gradient: RadialGradient(
          colors: [
            Color.alphaBlend(
              scheme.primary.withValues(alpha: 0.20),
              scheme.surfaceContainerHigh,
            ),
            scheme.surfaceContainerLow,
          ],
        ),
      );
    }
    return BoxDecoration(
      borderRadius: BorderRadius.circular(14),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          scheme.primary.withValues(alpha: 0.12),
          scheme.primary.withValues(alpha: 0.045),
        ],
      ),
      border: Border.all(color: scheme.primary.withValues(alpha: 0.10)),
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
          decoration: _canvasDecoration(scheme, light),
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 46),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DecoratedBox(
                  decoration: _summaryCardDecoration(scheme, light),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 42,
                              height: 42,
                              decoration: _iconCapsuleDecoration(scheme, light),
                              child: Icon(
                                Icons.compare_arrows_rounded,
                                size: 22,
                                color: light
                                    ? scheme.primary
                                    : AppTheme.editorialAccentColor(scheme),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.compareVehiclesTitle,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.45,
                                      height: 1.05,
                                      color: scheme.onSurface.withValues(
                                        alpha: light ? 0.98 : 0.98,
                                      ),
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: light
                                          ? scheme.primary.withValues(
                                              alpha: 0.07,
                                            )
                                          : Color.alphaBlend(
                                              scheme.primary.withValues(
                                                alpha: 0.12,
                                              ),
                                              scheme.surfaceContainerHigh,
                                            ),
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: scheme.primary.withValues(
                                          alpha: light ? 0.10 : 0.20,
                                        ),
                                      ),
                                    ),
                                    child: Text(
                                      l10n.compareVehicleCountShort(count),
                                      style: theme.textTheme.labelMedium
                                          ?.copyWith(
                                            color: light
                                                ? scheme.primary
                                                : AppTheme.editorialAccentColor(
                                                    scheme,
                                                  ),
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: -0.05,
                                          ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 13,
                                vertical: 8,
                              ),
                              foregroundColor: light
                                  ? scheme.onSurfaceVariant
                                  : scheme.onSurfaceVariant.withValues(
                                      alpha: 0.88,
                                    ),
                              backgroundColor: light
                                  ? const Color(
                                      0xFFF5F7FA,
                                    ).withValues(alpha: 0.92)
                                  : scheme.surfaceContainerHigh.withValues(
                                      alpha: 0.36,
                                    ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(999),
                                side: BorderSide(
                                  color: scheme.outlineVariant.withValues(
                                    alpha: light ? 0.34 : 0.26,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cardWidth = count >= 3
                                ? (constraints.maxWidth * 0.58)
                                      .clamp(188.0, 204.0)
                                      .toDouble()
                                : (constraints.maxWidth * 0.62)
                                      .clamp(204.0, 224.0)
                                      .toDouble();
                            return SingleChildScrollView(
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
                                        key: ValueKey(
                                          widget.items[i].listingId,
                                        ),
                                        slot: i < slots.length
                                            ? slots[i]
                                            : CompareResolvedSlot(
                                                item: widget.items[i],
                                                phase: CompareSlotPhase.loading,
                                              ),
                                        width: cardWidth,
                                        onRemove: () =>
                                            _remove(widget.items[i].listingId),
                                      ),
                                    ),
                                  const SizedBox(width: 14),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                DecoratedBox(
                  decoration: _toggleRowDecoration(scheme, light),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 13, 10, 13),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: _iconCapsuleDecoration(scheme, light),
                          child: Icon(
                            Icons.tune_rounded,
                            size: 19,
                            color: light
                                ? scheme.primary
                                : AppTheme.editorialAccentColor(scheme),
                          ),
                        ),
                        const SizedBox(width: 12),
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
