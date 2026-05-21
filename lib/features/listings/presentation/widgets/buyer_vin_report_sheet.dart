import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/buyer_listing_vin_report_source_result.dart';
import '../../domain/repositories/listings_repository.dart';
import '../../../../core/utils/result.dart';
import '../utils/buyer_vin_report_date_format.dart';
import '../utils/nhtsa_vin_summary_display.dart';
import 'buyer_vin_manual_source_cards_section.dart';
import 'buyer_vin_report_limitation_section.dart';

/// Vertical space for sticky footer (button + padding) so scroll content clears it.
const double kBuyerVinReportStickyFooterBlockHeight = 76;

/// Extra scroll padding below last content for comfortable reading above the button.
const double kBuyerVinReportScrollContentEndGap = 20;

/// Opens buyer-facing VIN report. Does not display full VIN.
void showBuyerVinReportSheet(
  BuildContext context, {
  required String listingId,
  String? listingMake,
  String? listingModel,
  int? listingYear,
}) {
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _BuyerVinReportSheetContent(
      listingId: listingId,
      listingMake: listingMake,
      listingModel: listingModel,
      listingYear: listingYear,
    ),
  );
}

enum _VinListingCompare { uncertain, match, mismatch }

_VinListingCompare _compareVinToListing(
  String? listingMake,
  String? listingModel,
  int? listingYear,
  Map<String, dynamic>? summary,
) {
  String? norm(String? s) {
    if (s == null) return null;
    final t = s.trim().toLowerCase();
    return t.isEmpty ? null : t;
  }

  int? yr(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  final dm = norm(summary?['make']?.toString());
  final dmodel = norm(summary?['model']?.toString());
  final dy = yr(summary?['year']);
  final lm = norm(listingMake);
  final lmodel = norm(listingModel);
  final ly = listingYear;

  if (dm == null ||
      dmodel == null ||
      dy == null ||
      lm == null ||
      lmodel == null ||
      ly == null) {
    return _VinListingCompare.uncertain;
  }
  final same = dm == lm && dmodel == lmodel && dy == ly;
  return same ? _VinListingCompare.match : _VinListingCompare.mismatch;
}

class _BuyerVinReportSheetContent extends StatefulWidget {
  const _BuyerVinReportSheetContent({
    required this.listingId,
    this.listingMake,
    this.listingModel,
    this.listingYear,
  });

  final String listingId;
  final String? listingMake;
  final String? listingModel;
  final int? listingYear;

  @override
  State<_BuyerVinReportSheetContent> createState() =>
      _BuyerVinReportSheetContentState();
}

class _BuyerVinReportSheetContentState
    extends State<_BuyerVinReportSheetContent> {
  bool _loading = true;
  bool _failed = false;
  List<BuyerListingVinReportSourceResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final repo = sl<ListingsRepository>();
    final out = await repo.fetchBuyerVinReportSources(widget.listingId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (out) {
        case Success(:final value):
          _failed = value.fetchFailed;
          _results = value.results;
        case FailureResult():
          _failed = true;
          _results = const [];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.78;

    final scrollBottomPadding =
        kBuyerVinReportStickyFooterBlockHeight +
        kBuyerVinReportScrollContentEndGap;

    Widget scrollBody() {
      return SingleChildScrollView(
        key: const ValueKey('buyer_vin_report_sheet_scroll'),
        padding: EdgeInsets.only(bottom: scrollBottomPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.listingBuyerVinReportTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.2,
              ),
            ),
            const SizedBox(height: 16),
            if (_loading) ...[
              const SizedBox(height: 24),
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Text(
                l10n.listingBuyerVinReportLoading,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 24),
            ] else if (_failed)
              Text(
                l10n.listingBuyerVinReportLoadError,
                style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
              )
            else if (_results.isEmpty)
              _EmptyBuyerVinReportBody(l10n: l10n, theme: theme)
            else
              _BuyerVinReportWithSources(
                l10n: l10n,
                theme: theme,
                results: _results,
                listingMake: widget.listingMake,
                listingModel: widget.listingModel,
                listingYear: widget.listingYear,
              ),
          ],
        ),
      );
    }

    return SizedBox(
      height: maxSheetHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(child: scrollBody()),
            DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.surface,
                border: Border(
                  top: BorderSide(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
              ),
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.only(top: 12, bottom: 16 + bottomInset),
                  child: FilledButton(
                    key: const ValueKey('buyer_vin_report_sheet_close'),
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(l10n.listingBuyerVinReportClose),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBuyerVinReportBody extends StatelessWidget {
  const _EmptyBuyerVinReportBody({required this.l10n, required this.theme});

  final AppLocalizations l10n;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Column(
      key: const ValueKey('buyer_vin_empty'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingBuyerVinReportVinAddedBySeller,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.listingBuyerVinReportFullVinPrivate,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.listingBuyerVinReportPublicDataUnavailable,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.listingBuyerVinReportFormatOnlyExplanation,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 16),
        BuyerVinManualSourceCardsSection(l10n: l10n, theme: theme),
        const SizedBox(height: 14),
        Text(
          l10n.editListingVinReportLimitationNote,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.42,
            color: scheme.onSurfaceVariant,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
}

class _BuyerVinReportWithSources extends StatelessWidget {
  const _BuyerVinReportWithSources({
    required this.l10n,
    required this.theme,
    required this.results,
    this.listingMake,
    this.listingModel,
    this.listingYear,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final List<BuyerListingVinReportSourceResult> results;
  final String? listingMake;
  final String? listingModel;
  final int? listingYear;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final nhtsa = results
        .where((r) => r.sourceId == 'nhtsa_vpic')
        .toList(growable: false);
    final other = results
        .where((r) => r.sourceId != 'nhtsa_vpic')
        .toList(growable: false);

    Map<String, dynamic>? primaryNhtsaSummary;
    for (final r in nhtsa) {
      final m = r.normalizedSummary;
      if (m != null && m.isNotEmpty) {
        primaryNhtsaSummary = m;
        break;
      }
    }

    final compare = _compareVinToListing(
      listingMake,
      listingModel,
      listingYear,
      primaryNhtsaSummary,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingBuyerVinReportVinAddedBySeller,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 10),
        Text(
          l10n.listingBuyerVinReportFullVinPrivate,
          style: theme.textTheme.bodyLarge?.copyWith(height: 1.45),
        ),
        const SizedBox(height: 14),
        if (nhtsa.isNotEmpty && compare != _VinListingCompare.uncertain) ...[
          Text(
            l10n.listingBuyerVinReportCompareHint,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.42,
              color: scheme.onSurface.withValues(alpha: 0.88),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            compare == _VinListingCompare.match
                ? l10n.listingBuyerVinReportCompareMatch
                : l10n.listingBuyerVinReportCompareMismatch,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 14),
        ],
        if (nhtsa.isNotEmpty) ...[
          for (final r in nhtsa) ...[
            _NhtsaPublicDecodeSection(l10n: l10n, theme: theme, result: r),
            const SizedBox(height: 16),
          ],
        ],
        BuyerVinManualSourceCardsSection(l10n: l10n, theme: theme),
        const SizedBox(height: 16),
        if (other.isNotEmpty) ...[
          Text(
            l10n.listingBuyerVinReportSourcesSectionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final r in other) ...[
            _GenericSourceResultCard(l10n: l10n, theme: theme, result: r),
            const SizedBox(height: 14),
          ],
        ],
      ],
    );
  }
}

class _NhtsaPublicDecodeSection extends StatelessWidget {
  const _NhtsaPublicDecodeSection({
    required this.l10n,
    required this.theme,
    required this.result,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final BuyerListingVinReportSourceResult result;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final m = result.normalizedSummary;
    final when = result.fetchedAt ?? result.updatedAt;
    final groups = nhtsaVinSummaryGroupsFromMap(l10n, m);
    final hasGroups = groups.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (hasGroups) ...[
          DecoratedBox(
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: scheme.outlineVariant.withValues(alpha: 0.35),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < groups.length; i++) ...[
                    if (i > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Divider(
                          height: 1,
                          color: scheme.outlineVariant.withValues(alpha: 0.45),
                        ),
                      ),
                    _NhtsaSummaryGroupBlock(theme: theme, group: groups[i]),
                  ],
                ],
              ),
            ),
          ),
        ],
        if (nhtsaVinSummaryShowsCatalogCaution(m)) ...[
          const SizedBox(height: 10),
          Text(
            l10n.listingBuyerVinReportNhtsaCatalogDecodeCaution,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.42,
              color: scheme.onSurfaceVariant,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          l10n.listingBuyerVinReportNhtsaCatalogSourceLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: scheme.onSurface.withValues(alpha: 0.9),
          ),
        ),
        if (when != null) ...[
          const SizedBox(height: 12),
          Text(
            l10n.listingBuyerVinReportUpdatedLabel,
            style: theme.textTheme.labelLarge?.copyWith(
              color: scheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            formatBuyerVinReportDate(when),
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ],
        const SizedBox(height: 14),
        Text(
          l10n.listingBuyerVinReportBasicDecodeCatalogLine,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.5,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.listingBuyerVinReportBasicDecodeNotOfficialLine,
          style: theme.textTheme.bodyMedium?.copyWith(
            height: 1.45,
            color: scheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 12),
        BuyerVinReportLimitationSection(
          l10n: l10n,
          theme: theme,
          limitationCodes: result.limitationCodes,
        ),
      ],
    );
  }
}

class _NhtsaSummaryGroupBlock extends StatelessWidget {
  const _NhtsaSummaryGroupBlock({required this.theme, required this.group});

  final ThemeData theme;
  final NhtsaVinSummaryGroup group;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          group.title,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: scheme.onSurface.withValues(alpha: 0.88),
            letterSpacing: 0.1,
          ),
        ),
        const SizedBox(height: 8),
        for (final f in group.fields)
          f.stackValue
              ? _SummaryFieldStacked(
                  theme: theme,
                  label: f.label,
                  value: f.value,
                )
              : _SummaryFieldRow(theme: theme, label: f.label, value: f.value),
      ],
    );
  }
}

class _GenericSourceResultCard extends StatelessWidget {
  const _GenericSourceResultCard({
    required this.l10n,
    required this.theme,
    required this.result,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final BuyerListingVinReportSourceResult result;

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  static int? _year(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString().trim());
  }

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final label = result.sourceLabel ?? result.sourceId;
    final when = result.fetchedAt ?? result.updatedAt;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.listingBuyerVinReportSourceHeading,
              style: theme.textTheme.labelLarge?.copyWith(
                color: scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: theme.textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            if (when != null) ...[
              const SizedBox(height: 10),
              Text(
                l10n.listingBuyerVinReportUpdatedLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                formatBuyerVinReportDate(when),
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
              ),
            ],
            ..._summaryRows(l10n, theme, result.normalizedSummary),
            BuyerVinReportLimitationSection(
              l10n: l10n,
              theme: theme,
              limitationCodes: result.limitationCodes,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _summaryRows(
    AppLocalizations l10n,
    ThemeData theme,
    Map<String, dynamic>? m,
  ) {
    if (m == null || m.isEmpty) return const [];
    final make = _str(m['make']);
    final model = _str(m['model']);
    final year = _year(m['year']);
    final body = _str(m['body_type']);
    final fuel = _str(m['fuel_type']);
    if (make == null &&
        model == null &&
        year == null &&
        body == null &&
        fuel == null) {
      return const [];
    }
    return [
      const SizedBox(height: 12),
      Text(
        l10n.editListingVinReportBasicInfoHeading,
        style: theme.textTheme.titleSmall?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      const SizedBox(height: 8),
      if (make != null)
        _SummaryFieldRow(
          theme: theme,
          label: l10n.editListingVinReportDecodedMakeLabel,
          value: make,
        ),
      if (model != null)
        _SummaryFieldRow(
          theme: theme,
          label: l10n.editListingVinReportDecodedModelLabel,
          value: model,
        ),
      if (year != null)
        _SummaryFieldRow(
          theme: theme,
          label: l10n.editListingVinReportDecodedYearLabel,
          value: '$year',
        ),
      if (body != null)
        _SummaryFieldRow(
          theme: theme,
          label: l10n.editListingVinReportDecodedBodyLabel,
          value: body,
        ),
      if (fuel != null)
        _SummaryFieldRow(
          theme: theme,
          label: l10n.editListingVinReportDecodedFuelLabel,
          value: fuel,
        ),
    ];
  }
}

class _SummaryFieldRow extends StatelessWidget {
  const _SummaryFieldRow({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 118,
            child: Text(
              label,
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurfaceVariant,
                height: 1.3,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                height: 1.4,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryFieldStacked extends StatelessWidget {
  const _SummaryFieldStacked({
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: scheme.onSurfaceVariant,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              height: 1.45,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
