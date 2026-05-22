import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/app_localizations_x.dart';
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

  static const double columnWidth = 132;
  static const double columnGap = 10;

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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      l10n.compareVehicleCountShort(count),
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  TextButton(
                    key: const ValueKey('compare_clear_button'),
                    onPressed: widget.onClear,
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      foregroundColor: scheme.onSurfaceVariant,
                    ),
                    child: Text(l10n.compareClear),
                  ),
                ],
              ),
              const SizedBox(height: 8),
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
                          width: CompareSpecView.columnWidth,
                          onRemove: () => _remove(widget.items[i].listingId),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Material(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.2),
                  ),
                ),
                child: SwitchListTile(
                  key: const ValueKey('compare_diff_toggle'),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  title: Text(
                    l10n.compareShowOnlyDifferences,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  value: _showOnlyDifferences,
                  onChanged: (v) => setState(() => _showOnlyDifferences = v),
                ),
              ),
              const SizedBox(height: 16),
              if (_showOnlyDifferences &&
                  !pageState.isResolving &&
                  visibleSections.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    l10n.compareNoDifferences,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
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
                ),
            ],
          ),
        );
      },
    );
  }

}
