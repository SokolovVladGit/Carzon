import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../../../l10n/app_localizations.dart';
import '../../domain/validation/listing_valid_years.dart';

/// Result from [showListingYearWheelPickSheet]. The future is `null` if the
/// sheet was dismissed without confirming.
sealed class ListingYearPickerOutcome {}

/// User tapped «Сбросить» when allowed.
final class ListingYearPickerClear extends ListingYearPickerOutcome {}

/// User confirmed a year via «Готово».
final class ListingYearPickerChosen extends ListingYearPickerOutcome {
  ListingYearPickerChosen(this.year);

  final int year;
}

/// Wheel-style picker; use [showListingYearWheelPickSheet] for filters, or
/// [showListingYearPickSheet] when only a confirmed integer is needed.
Future<ListingYearPickerOutcome?> showListingYearWheelPickSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required String sheetTitle,
  int? selectedYear,
  required bool allowClear,
}) {
  return showModalBottomSheet<ListingYearPickerOutcome?>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetCtx) => _ListingYearWheelSheetBody(
      l10n: l10n,
      sheetTitle: sheetTitle,
      selectedYear: selectedYear,
      allowClear: allowClear,
    ),
  );
}

/// Opens year wheel sheet; returns the chosen year, or `null` if dismissed.
///
/// When [selectedYear] is set, it is pre-centered in the wheel; otherwise the
/// wheel starts on the newest available year (model-year practice).
Future<int?> showListingYearPickSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  String? sheetTitle,
  int? selectedYear,
}) async {
  final out = await showListingYearWheelPickSheet(
    context: context,
    l10n: l10n,
    sheetTitle: sheetTitle ?? l10n.createListingChooseYear,
    selectedYear: selectedYear,
    allowClear: false,
  );
  if (out is ListingYearPickerChosen) return out.year;
  return null;
}

class _ListingYearWheelSheetBody extends StatefulWidget {
  const _ListingYearWheelSheetBody({
    required this.l10n,
    required this.sheetTitle,
    required this.selectedYear,
    required this.allowClear,
  });

  final AppLocalizations l10n;
  final String sheetTitle;
  final int? selectedYear;
  final bool allowClear;

  @override
  State<_ListingYearWheelSheetBody> createState() =>
      _ListingYearWheelSheetBodyState();
}

class _ListingYearWheelSheetBodyState
    extends State<_ListingYearWheelSheetBody> {
  late final List<int> _yearsNewestFirst;
  late final FixedExtentScrollController _wheel;
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _yearsNewestFirst = listingYearsOrderedNewestFirst();
    assert(_yearsNewestFirst.isNotEmpty, 'years list');

    final want = widget.selectedYear;
    var idx = 0;
    if (want != null) {
      final i = _yearsNewestFirst.indexOf(want);
      if (i >= 0) idx = i;
    }
    _selectedIndex = idx;
    _wheel = FixedExtentScrollController(initialItem: idx);
  }

  @override
  void dispose() {
    _wheel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);

    final media = MediaQuery.of(context);
    final maxUsable = math.min(
      media.size.height * 0.9,
      math.max(200.0, media.size.height * 0.45),
    );
    final sheetHeight = math.max(
      widget.allowClear ? 340.0 : 300.0,
      math.min(media.size.height * 0.48, maxUsable),
    );

    final pickerFg = scheme.onSurface.withValues(alpha: 0.94);
    final pickerMuted = scheme.onSurface.withValues(alpha: 0.42);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: SizedBox(
          height: sheetHeight,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 2, 20, 4),
                child: Text(
                  widget.sheetTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.2,
                    color: scheme.onSurface.withValues(alpha: 0.92),
                  ),
                ),
              ),
              Divider(
                height: 1,
                thickness: 1,
                color: scheme.outlineVariant.withValues(alpha: 0.22),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 4, 12, 0),
                child: Row(
                  children: [
                    if (widget.allowClear)
                      TextButton(
                        onPressed: () =>
                            Navigator.maybePop<ListingYearPickerOutcome?>(
                              context,
                              ListingYearPickerClear(),
                            ),
                        child: Text(widget.l10n.filterClear),
                      )
                    else
                      const SizedBox(width: 8),
                    const Spacer(),
                    TextButton(
                      onPressed: () =>
                          Navigator.maybePop<ListingYearPickerOutcome?>(
                            context,
                            ListingYearPickerChosen(
                              _yearsNewestFirst[_selectedIndex],
                            ),
                          ),
                      child: Text(widget.l10n.commonDone),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: CupertinoTheme(
                      data: CupertinoTheme.of(context).copyWith(
                        textTheme: CupertinoTextThemeData(
                          textStyle:
                              theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: pickerFg,
                              ) ??
                              TextStyle(fontSize: 20, color: pickerFg),
                        ),
                      ),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ColoredBox(
                            color: scheme.surfaceContainerHighest.withValues(
                              alpha: 0.09,
                            ),
                          ),
                          Center(
                            child: Container(
                              height: 42,
                              margin: const EdgeInsets.symmetric(
                                horizontal: 10,
                              ),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                  bottom: BorderSide(
                                    color: scheme.outlineVariant.withValues(
                                      alpha: 0.28,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          CupertinoPicker(
                            scrollController: _wheel,
                            itemExtent: 40,
                            magnification: 1.08,
                            useMagnifier: true,
                            onSelectedItemChanged: (int i) {
                              setState(() => _selectedIndex = i);
                            },
                            squeeze: 1.06,
                            children: [
                              for (
                                var idx = 0;
                                idx < _yearsNewestFirst.length;
                                idx++
                              )
                                Center(
                                  child: AnimatedDefaultTextStyle(
                                    duration: const Duration(milliseconds: 120),
                                    style:
                                        theme.textTheme.titleMedium?.copyWith(
                                          fontWeight: idx == _selectedIndex
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: idx == _selectedIndex
                                              ? pickerFg
                                              : pickerMuted,
                                          letterSpacing: -0.1,
                                        ) ??
                                        TextStyle(
                                          fontSize: 19,
                                          fontWeight: idx == _selectedIndex
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: idx == _selectedIndex
                                              ? pickerFg
                                              : pickerMuted,
                                        ),
                                    child: Text('${_yearsNewestFirst[idx]}'),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(height: media.padding.bottom > 8 ? 0 : 8),
            ],
          ),
        ),
      ),
    );
  }
}
