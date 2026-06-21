import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/buyer_listing_vin_report_source_result.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listings_repository.dart';
import '../utils/buyer_vin_report_date_format.dart';
import '../utils/buyer_vin_report_ui_state.dart';
import '../utils/nhtsa_vin_summary_display.dart';
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
  final isDark = Theme.of(context).brightness == Brightness.dark;
  showModalBottomSheet<void>(
    context: context,
    useSafeArea: true,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: isDark ? Colors.transparent : null,
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
    required bool showSuccessVinBadge,
  }) {
    final hasCompare =
        hasDisplayableDecode && compare != _VinListingCompare.uncertain;

    return BuyerVinReportHeroHeader(
      theme: theme,
      reportTitle: l10n.listingBuyerVinReportTitle,
      vinAddedLine: l10n.listingBuyerVinReportVinAddedBySeller,
      vinPrivateLine: l10n.listingBuyerVinReportFullVinPrivate,
      compareResult: hasCompare
          ? (compare == _VinListingCompare.match
                ? l10n.listingBuyerVinReportCompareMatch
                : l10n.listingBuyerVinReportCompareMismatch)
          : null,
      compareIsMatch: hasCompare ? compare == _VinListingCompare.match : null,
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
    final isDark = theme.brightness == Brightness.dark;

    final scrollBottomPadding =
        kBuyerVinReportStickyFooterBlockHeight +
        kBuyerVinReportScrollContentEndGap +
        (isDark ? kBuyerVinReportCompareTrayScrollClearance : 0);

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
            Center(
              child: CircularProgressIndicator(
                color: isDark ? AppTheme.editorialAccentColor(scheme) : null,
                strokeWidth: 2.5,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.listingVinReportLoadingCta,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.84 : 1,
                ),
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
        ),
        BuyerVinReportUiState.noPublicData => _BuyerVinReportStateBody(
          key: const ValueKey('buyer_vin_report_no_data'),
          theme: theme,
          title: l10n.listingVinReportNoDataTitle,
          body: l10n.listingVinReportNoDataBody,
          note: l10n.listingVinReportNoDataNote,
        ),
        BuyerVinReportUiState.unavailableOrError => _BuyerVinReportStateBody(
          key: const ValueKey('buyer_vin_report_unavailable'),
          theme: theme,
          title: l10n.listingVinReportUnavailableTitle,
          body: l10n.listingVinReportUnavailableBody,
        ),
        _ => const SizedBox.shrink(),
      };
    }

    return Material(
      color: isDark ? Colors.transparent : scheme.surface,
      child: DecoratedBox(
        decoration: isDark
            ? BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: AppTheme.editorialDarkFilterCanvasGradient(scheme),
                  stops: const [0, 0.28, 1],
                ),
              )
            : const BoxDecoration(),
        child: SizedBox(
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
  });

  final ThemeData theme;
  final String title;
  final String body;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return BuyerVinReportStateMessageCard(
      theme: theme,
      title: title,
      body: body,
      note: note,
    );
  }
}

/// Standard buyer limitation bullets — always the same concise set in the report.
const List<String> kBuyerVinReportStandardLimitationCodes = [
  'basic_decode_only',
];

/// Premium spec-sheet sections below the hero (NHTSA groups, limitations, footer).
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

    final nhtsaPrimary = nhtsa.isNotEmpty ? nhtsa.first : null;
    final footer = BuyerVinReportFooterStrip(
      theme: theme,
      sourceLine: l10n.listingBuyerVinReportNhtsaCatalogSourceLine,
      updatedDate: () {
        final when = nhtsaPrimary?.fetchedAt ?? nhtsaPrimary?.updatedAt;
        if (when == null) return null;
        return '${l10n.listingBuyerVinReportUpdatedLabel}: ${formatBuyerVinReportDate(when)}';
      }(),
      disclaimerLine: l10n.listingBuyerVinReportBasicDecodeNotOfficialLine,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (nhtsa.isNotEmpty)
          for (var i = 0; i < nhtsa.length; i++) ...[
            _NhtsaSpecSheetSection(l10n: l10n, theme: theme, result: nhtsa[i]),
            if (i < nhtsa.length - 1) const SizedBox(height: 10),
          ],
        const SizedBox(height: 12),
        BuyerVinReportLimitationSection(
          l10n: l10n,
          theme: theme,
          limitationCodes: kBuyerVinReportStandardLimitationCodes,
        ),
        const SizedBox(height: 10),
        footer,
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
      ],
    );
  }
}
