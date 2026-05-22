import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/utils/result.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/buyer_listing_vin_report_source_result.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listings_repository.dart';
import '../utils/buyer_vin_report_ui_state.dart';
import 'buyer_vin_report_sheet.dart';
import 'vin_present_latin_badge.dart';

/// VIN row on listing details: state-aware CTA or muted absent state.
class ListingDetailsVinEntry extends StatefulWidget {
  const ListingDetailsVinEntry({super.key, required this.listing});

  final Listing listing;

  @override
  State<ListingDetailsVinEntry> createState() => _ListingDetailsVinEntryState();
}

class _ListingDetailsVinEntryState extends State<ListingDetailsVinEntry> {
  bool _loadingLookup = false;
  BuyerListingVinReportLookupResult? _lookup;
  bool _fetchFailed = false;

  @override
  void initState() {
    super.initState();
    if (widget.listing.vinStatus == ListingVinStatus.formatValid) {
      _prefetchReport();
    }
  }

  Future<void> _prefetchReport() async {
    setState(() => _loadingLookup = true);
    final repo = sl<ListingsRepository>();
    final out = await repo.fetchBuyerVinReportSources(widget.listing.id);
    if (!mounted) return;
    setState(() {
      _loadingLookup = false;
      switch (out) {
        case Success(:final value):
          _lookup = value;
          _fetchFailed = value.fetchFailed;
        case FailureResult():
          _fetchFailed = true;
          _lookup = null;
      }
    });
  }

  BuyerVinReportUiState get _uiState => resolveBuyerVinReportUiState(
    listingVinStatus: widget.listing.vinStatus,
    lookup: _lookup,
    loading: _loadingLookup,
    fetchFailed: _fetchFailed,
  );

  void _openReportSheet(BuildContext context) {
    showBuyerVinReportSheet(
      context,
      listingId: widget.listing.id,
      listingMake: widget.listing.make,
      listingModel: widget.listing.model,
      listingYear: widget.listing.year,
      initialLookup: _lookup,
      initialFetchFailed: _fetchFailed,
      initialLoading: _loadingLookup,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = _uiState;
    if (state == BuyerVinReportUiState.noVin) {
      return const _ListingDetailsVinAbsentState();
    }
    return _ListingDetailsVinCtaRow(
      listing: widget.listing,
      uiState: state,
      onTap: buyerVinReportCtaIsTappable(state)
          ? () => _openReportSheet(context)
          : null,
    );
  }
}

class _ListingDetailsVinCtaRow extends StatelessWidget {
  const _ListingDetailsVinCtaRow({
    required this.listing,
    required this.uiState,
    this.onTap,
  });

  final Listing listing;
  final BuyerVinReportUiState uiState;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final showGreen = buyerVinReportShowsSuccessBadge(uiState);
    final tappable = onTap != null;

    final (title, subtitle) = switch (uiState) {
      BuyerVinReportUiState.reportAvailable => (
        l10n.listingVinBadgeIndicated,
        l10n.listingVinReportOpenHint,
      ),
      BuyerVinReportUiState.loading => (
        l10n.listingVinBadgeIndicated,
        l10n.listingVinReportLoadingCta,
      ),
      BuyerVinReportUiState.pendingOrNotReady => (
        l10n.listingVinBadgeIndicated,
        l10n.listingVinReportPendingCta,
      ),
      BuyerVinReportUiState.noPublicData => (
        l10n.listingVinBadgeIndicated,
        l10n.listingVinReportNoDataCta,
      ),
      BuyerVinReportUiState.unavailableOrError => (
        l10n.listingVinBadgeIndicated,
        l10n.listingVinReportUnavailableCta,
      ),
      _ => (l10n.listingVinBadgeIndicated, l10n.listingVinReportOpenHint),
    };

    final surfaceAlpha = showGreen ? 0.38 : 0.24;
    final borderAlpha = showGreen ? 0.45 : 0.32;

    final child = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          showGreen
              ? const VinPresentLatinBadge()
              : const VinNeutralLatinBadge(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.25,
                    letterSpacing: -0.15,
                    color: tappable
                        ? null
                        : scheme.onSurface.withValues(alpha: 0.72),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (tappable) ...[
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              size: 22,
              color: scheme.onSurface.withValues(alpha: 0.45),
            ),
          ],
        ],
      ),
    );

    if (!tappable) {
      return Semantics(
        key: ValueKey('listing_vin_cta_${uiState.name}'),
        container: true,
        label: '$title. $subtitle',
        child: Material(
          color: scheme.surfaceContainerHighest.withValues(alpha: surfaceAlpha),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: scheme.outlineVariant.withValues(alpha: borderAlpha),
            ),
          ),
          child: child,
        ),
      );
    }

    return Semantics(
      button: true,
      label: '$title. $subtitle',
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: surfaceAlpha),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: borderAlpha),
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          key: const ValueKey('listing_vin_trust_badge_tap'),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
}

/// Muted inactive row when the seller did not provide a VIN.
class _ListingDetailsVinAbsentState extends StatelessWidget {
  const _ListingDetailsVinAbsentState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Semantics(
      key: const ValueKey('listing_vin_absent_state'),
      container: true,
      label: l10n.listingVinNotProvidedTitle,
      child: Material(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.22),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: scheme.outlineVariant.withValues(alpha: 0.32),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              const VinNeutralLatinBadge(),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.listingVinNotProvidedTitle,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                        color: scheme.onSurface.withValues(alpha: 0.55),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.listingVinNotProvidedHint,
                      style: theme.textTheme.bodySmall?.copyWith(
                        height: 1.35,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
