import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/utils/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/buyer_listing_vin_report_source_result.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listings_repository.dart';
import '../utils/buyer_vin_report_date_format.dart';
import '../utils/buyer_vin_report_ui_state.dart';
import '../utils/nhtsa_vin_summary_display.dart';
import 'buyer_vin_manual_source_cards_section.dart';
import 'buyer_vin_report_limitation_section.dart';
import 'buyer_vin_report_sheet_ui.dart';

/// Vertical space for sticky footer (button + padding) so scroll content clears it.
const double kBuyerVinReportStickyFooterBlockHeight = 96;

/// Extra scroll padding below last content for comfortable reading above the button.
const double kBuyerVinReportScrollContentEndGap = 36;

/// Opens buyer-facing VIN report. Does not display full VIN.
void showBuyerVinReportSheet(
  BuildContext context, {
  required String listingId,
  String? listingMake,
  String? listingModel,
  int? listingYear,
  BuyerListingVinReportLookupResult? initialLookup,
  bool initialFetchFailed = false,
  bool initialLoading = false,
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
      initialLookup: initialLookup,
      initialFetchFailed: initialFetchFailed,
      initialLoading: initialLoading,
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

BuyerListingVinReportSourceResult? _primaryNhtsaResult(
  List<BuyerListingVinReportSourceResult> results,
) {
  for (final r in results) {
    if (r.sourceId == 'nhtsa_vpic') return r;
  }
  return null;
}

class _BuyerVinReportSheetContent extends StatefulWidget {
  const _BuyerVinReportSheetContent({
    required this.listingId,
    this.listingMake,
    this.listingModel,
    this.listingYear,
    this.initialLookup,
    this.initialFetchFailed = false,
    this.initialLoading = false,
  });

  final String listingId;
  final String? listingMake;
  final String? listingModel;
  final int? listingYear;
  final BuyerListingVinReportLookupResult? initialLookup;
  final bool initialFetchFailed;
  final bool initialLoading;

  @override
  State<_BuyerVinReportSheetContent> createState() =>
      _BuyerVinReportSheetContentState();
}

class _BuyerVinReportSheetContentState
    extends State<_BuyerVinReportSheetContent> {
  late bool _loading;
  bool _fetchFailed = false;
  List<BuyerListingVinReportSourceResult> _results = const [];

  @override
  void initState() {
    super.initState();
    _loading = widget.initialLoading;
    _fetchFailed = widget.initialFetchFailed;
    _results = widget.initialLookup?.results ?? const [];
    if (widget.initialLoading || widget.initialLookup == null) {
      _load();
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final repo = sl<ListingsRepository>();
    final out = await repo.fetchBuyerVinReportSources(widget.listingId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (out) {
        case Success(:final value):
          _fetchFailed = value.fetchFailed;
          _results = value.results;
        case FailureResult():
          _fetchFailed = true;
          _results = const [];
      }
    });
  }

  BuyerVinReportUiState get _uiState => resolveBuyerVinReportUiState(
    listingVinStatus: ListingVinStatus.formatValid,
    lookup: BuyerListingVinReportLookupResult(
      results: _results,
      fetchFailed: _fetchFailed,
    ),
    loading: _loading,
    fetchFailed: _fetchFailed,
  );

  BuyerVinReportHeroHeader _heroHeader({
    required AppLocalizations l10n,
    required ThemeData theme,
    required _VinListingCompare compare,
    required bool hasDisplayableDecode,
    BuyerListingVinReportSourceResult? nhtsa,
    required bool showSuccessVinBadge,
  }) {
    final hasCompare =
        hasDisplayableDecode && compare != _VinListingCompare.uncertain;
    final when = nhtsa?.fetchedAt ?? nhtsa?.updatedAt;
    final m = nhtsa?.normalizedSummary;

    return BuyerVinReportHeroHeader(
      theme: theme,
      reportTitle: l10n.listingBuyerVinReportTitle,
      vinAddedLine: l10n.listingBuyerVinReportVinAddedBySeller,
      vinPrivateLine: l10n.listingBuyerVinReportFullVinPrivate,
      compareHint: hasCompare ? l10n.listingBuyerVinReportCompareHint : null,
      compareResult: hasCompare
          ? (compare == _VinListingCompare.match
                ? l10n.listingBuyerVinReportCompareMatch
                : l10n.listingBuyerVinReportCompareMismatch)
          : null,
      compareIsMatch: hasCompare ? compare == _VinListingCompare.match : null,
      compareAvailableHint: hasDisplayableDecode && !hasCompare
          ? l10n.listingBuyerVinReportCompareHint
          : null,
      sourceLine: hasDisplayableDecode
          ? l10n.listingBuyerVinReportNhtsaCatalogSourceLine
          : null,
      updatedLabel: when != null ? l10n.listingBuyerVinReportUpdatedLabel : null,
      updatedDate: when != null ? formatBuyerVinReportDate(when) : null,
      basicDecodeLine: hasDisplayableDecode
          ? l10n.listingBuyerVinReportBasicDecodeCatalogLine
          : null,
      notOfficialLine: hasDisplayableDecode
          ? l10n.listingBuyerVinReportBasicDecodeNotOfficialLine
          : null,
      cautionLine: nhtsaVinSummaryShowsCatalogCaution(m)
          ? l10n.listingBuyerVinReportNhtsaCatalogDecodeCaution
          : null,
      showSuccessVinBadge: showSuccessVinBadge,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;
    final maxSheetHeight = MediaQuery.sizeOf(context).height * 0.86;

    final scrollBottomPadding =
        kBuyerVinReportStickyFooterBlockHeight +
        kBuyerVinReportScrollContentEndGap;

    final uiState = _uiState;
    final showSuccessBadge = buyerVinReportShowsSuccessBadge(uiState);

    final nhtsa = _primaryNhtsaResult(_results);
    final primarySummary = nhtsa?.normalizedSummary;
    final hasDisplayableDecode = buyerVinReportHasDisplayableSummary(
      primarySummary,
    );
    final compare = _compareVinToListing(
      widget.listingMake,
      widget.listingModel,
      widget.listingYear,
      primarySummary,
    );

    Widget bodyBelowHero() {
      if (uiState == BuyerVinReportUiState.loading) {
        return Column(
          key: const ValueKey('buyer_vin_report_loading'),
          children: [
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
            const SizedBox(height: 16),
            Text(
              l10n.listingVinReportLoadingCta,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
          ],
        );
      }

      return switch (uiState) {
        BuyerVinReportUiState.reportAvailable => _BuyerVinReportSpecSheetBody(
          key: const ValueKey('buyer_vin_report_spec'),
          l10n: l10n,
          theme: theme,
          results: _results,
        ),
        BuyerVinReportUiState.pendingOrNotReady => _BuyerVinReportStateBody(
          key: const ValueKey('buyer_vin_report_pending'),
          theme: theme,
          title: l10n.listingVinReportPendingTitle,
          body: l10n.listingVinReportPendingBody,
          showManualSources: true,
          l10n: l10n,
        ),
        BuyerVinReportUiState.noPublicData => _BuyerVinReportStateBody(
          key: const ValueKey('buyer_vin_report_no_data'),
          theme: theme,
          title: l10n.listingVinReportNoDataTitle,
          body: l10n.listingVinReportNoDataBody,
          note: l10n.listingVinReportNoDataNote,
          showManualSources: true,
          l10n: l10n,
        ),
        BuyerVinReportUiState.unavailableOrError => _BuyerVinReportStateBody(
          key: const ValueKey('buyer_vin_report_unavailable'),
          theme: theme,
          title: l10n.listingVinReportUnavailableTitle,
          body: l10n.listingVinReportUnavailableBody,
          l10n: l10n,
        ),
        _ => const SizedBox.shrink(),
      };
    }

    return SizedBox(
      height: maxSheetHeight,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                key: const ValueKey('buyer_vin_report_sheet_scroll'),
                padding: EdgeInsets.only(bottom: scrollBottomPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heroHeader(
                      l10n: l10n,
                      theme: theme,
                      compare: compare,
                      hasDisplayableDecode: hasDisplayableDecode,
                      nhtsa: nhtsa,
                      showSuccessVinBadge: showSuccessBadge,
                    ),
                    const SizedBox(height: 16),
                    bodyBelowHero(),
                  ],
                ),
              ),
            ),
            BuyerVinReportStickyFooter(
              theme: theme,
              bottomInset: bottomInset,
              closeLabel: l10n.listingBuyerVinReportClose,
              onClose: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }
}

class _BuyerVinReportStateBody extends StatelessWidget {
  const _BuyerVinReportStateBody({
    super.key,
    required this.theme,
    required this.title,
    required this.body,
    this.note,
    this.showManualSources = false,
    required this.l10n,
  });

  final ThemeData theme;
  final String title;
  final String body;
  final String? note;
  final bool showManualSources;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        BuyerVinReportStateMessageCard(
          theme: theme,
          title: title,
          body: body,
          note: note,
        ),
        if (showManualSources) ...[
          const SizedBox(height: 18),
          BuyerVinManualSourceCardsSection(l10n: l10n, theme: theme),
          const SizedBox(height: 12),
          Text(
            l10n.editListingVinReportLimitationNote,
            style: buyerVinReportMicrocopyStyle(theme),
          ),
        ],
      ],
    );
  }
}

/// Premium spec-sheet sections below the hero (NHTSA groups, limitations, manual).
class _BuyerVinReportSpecSheetBody extends StatelessWidget {
  const _BuyerVinReportSpecSheetBody({
    super.key,
    required this.l10n,
    required this.theme,
    required this.results,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final List<BuyerListingVinReportSourceResult> results;

  @override
  Widget build(BuildContext context) {
    final nhtsa = results
        .where((r) => r.sourceId == 'nhtsa_vpic')
        .toList(growable: false);
    final other = results
        .where((r) => r.sourceId != 'nhtsa_vpic')
        .toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nhtsa.isNotEmpty) ...[
          Text(
            l10n.editListingVinReportBasicInfoHeading,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 10),
          for (final r in nhtsa) ...[
            _NhtsaSpecSheetSection(l10n: l10n, theme: theme, result: r),
            const SizedBox(height: 12),
          ],
        ],
        BuyerVinManualSourceCardsSection(l10n: l10n, theme: theme),
        if (other.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            l10n.listingBuyerVinReportSourcesSectionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          for (final r in other) ...[
            _GenericSourceResultCard(l10n: l10n, theme: theme, result: r),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}

class _NhtsaSpecSheetSection extends StatelessWidget {
  const _NhtsaSpecSheetSection({
    required this.l10n,
    required this.theme,
    required this.result,
  });

  final AppLocalizations l10n;
  final ThemeData theme;
  final BuyerListingVinReportSourceResult result;

  @override
  Widget build(BuildContext context) {
    final groups = nhtsaVinSummaryGroupsFromMap(l10n, result.normalizedSummary);
    if (groups.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < groups.length; i++) ...[
          BuyerVinReportNhtsaGroupSection(
            theme: theme,
            group: groups[i],
            groupIndex: i,
          ),
          if (i < groups.length - 1) const SizedBox(height: 10),
        ],
        if (result.limitationCodes.isNotEmpty) ...[
          if (groups.isNotEmpty) const SizedBox(height: 10),
          BuyerVinReportLimitationSection(
            l10n: l10n,
            theme: theme,
            limitationCodes: result.limitationCodes,
          ),
        ],
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
    final label = result.sourceLabel ?? result.sourceId;
    final when = result.fetchedAt ?? result.updatedAt;
    final fields = _summaryFields(l10n, result.normalizedSummary);
    if (fields.isEmpty && when == null) return const SizedBox.shrink();

    return BuyerVinReportSectionCard(
      theme: theme,
      tone: BuyerVinReportSectionTone.dataCore,
      title: label,
      subtitle: l10n.listingBuyerVinReportSourceHeading,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (when != null) ...[
            BuyerVinReportMetaRow(
              theme: theme,
              label: l10n.listingBuyerVinReportUpdatedLabel,
              value: formatBuyerVinReportDate(when),
            ),
            if (fields.isNotEmpty) const SizedBox(height: 12),
          ],
          if (fields.isNotEmpty)
            BuyerVinReportIdentityPanel(theme: theme, fields: fields),
          BuyerVinReportLimitationSection(
            l10n: l10n,
            theme: theme,
            limitationCodes: result.limitationCodes,
            wrapInCard: false,
          ),
        ],
      ),
    );
  }

  List<NhtsaVinSummaryField> _summaryFields(
    AppLocalizations l10n,
    Map<String, dynamic>? m,
  ) {
    if (m == null || m.isEmpty) return const [];
    final make = _str(m['make']);
    final model = _str(m['model']);
    final year = _year(m['year']);
    final body = _str(m['body_type']);
    final fuel = _str(m['fuel_type']);
    final out = <NhtsaVinSummaryField>[];
    void add(
      String key,
      String label,
      String? value, {
      bool stack = false,
    }) {
      if (value == null) return;
      out.add(
        NhtsaVinSummaryField(
          label: label,
          value: value,
          stackValue: stack,
          fieldKey: key,
        ),
      );
    }

    add('make', l10n.editListingVinReportDecodedMakeLabel, make);
    add('model', l10n.editListingVinReportDecodedModelLabel, model);
    if (year != null) {
      add('year', l10n.editListingVinReportDecodedYearLabel, '$year');
    }
    add('body_type', l10n.editListingVinReportDecodedBodyLabel, body, stack: true);
    add('fuel_type', l10n.editListingVinReportDecodedFuelLabel, fuel);
    return out;
  }
}
