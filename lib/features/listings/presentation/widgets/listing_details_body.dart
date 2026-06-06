import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../shared/ui/carzon_icons.dart';
import '../../../sellers/presentation/widgets/seller_trust_section.dart';
import '../../domain/entities/listing.dart';
import '../utils/listing_details_uri_launcher.dart';
import '../utils/listing_formatters.dart';
import '../utils/report_listing_mailto.dart';
import 'listing_details_vin_entry.dart';

String? _nonEmptyTrimmedDescription(Listing listing) {
  final raw = listing.description;
  if (raw == null) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

/// Below-hero content block: specs list, public-contact notice,
/// seller trust, optional report action.
///
/// Behavior, visuals, and localization keys are unchanged from the
/// previous same-library `part`; all inputs are passed explicitly.
class BelowHeroContent extends StatelessWidget {
  const BelowHeroContent({
    super.key,
    required this.listing,
    required this.reportEmail,
    required this.uriLauncher,
  });

  final Listing listing;
  final String? reportEmail;
  final ListingDetailsUriLauncher? uriLauncher;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final hasReport = reportEmail != null && reportEmail!.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        _DetailsList(listing: listing),
        if (_nonEmptyTrimmedDescription(listing) case final desc?) ...[
          const SizedBox(height: 28),
          _ListingDescriptionBlock(text: desc),
        ],
        const SizedBox(height: 24),
        if (listing.sellerId != null &&
            listing.sellerId!.trim().isNotEmpty) ...[
          SellerTrustSection(sellerId: listing.sellerId!.trim()),
        ],
        Text(
          l10n.contactPublicNotice,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        if (hasReport) ...[
          const SizedBox(height: 16),
          _ReportLink(
            listing: listing,
            recipientEmail: reportEmail!,
            launcher: uriLauncher ?? launchExternalUri,
          ),
        ],
      ],
    );
  }
}

/// Free-text seller description (shown only when non-empty).
class _ListingDescriptionBlock extends StatelessWidget {
  const _ListingDescriptionBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.listingDetailsDescriptionSection,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          text,
          style: theme.textTheme.bodyLarge?.copyWith(
            height: 1.45,
            color: theme.colorScheme.onSurface.withValues(alpha: 0.92),
          ),
        ),
      ],
    );
  }
}

/// Flat details list. Rows use editorial label/value layout; empty values omitted.
class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.listing});

  final Listing listing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;

    bool hasValue(String v) => v.trim().isNotEmpty;

    final rows = <_DetailsRowData>[
      if (hasValue(listing.make))
        _DetailsRowData(l10n.listingFieldMake, listing.make.trim()),
      if (hasValue(listing.model))
        _DetailsRowData(l10n.listingFieldModel, listing.model.trim()),
      _DetailsRowData(l10n.listingFieldYear, listing.year.toString()),
      _DetailsRowData(
        l10n.listingFieldMileage,
        formatKm(l10n, listing.mileageKm),
      ),
      _DetailsRowData(l10n.listingFieldType, formatType(l10n, listing.type)),
      if (listing.bodyType != null)
        _DetailsRowData(
          l10n.listingFieldBodyType,
          formatListingBodyType(l10n, listing.bodyType!),
        ),
      if (hasValue(listing.city))
        _DetailsRowData(l10n.listingFieldCity, listing.city.trim()),
      if (listing.fuelType != null)
        _DetailsRowData(
          l10n.listingFuelType,
          formatListingFuelType(l10n, listing.fuelType!),
        ),
      if (listing.engineDisplacementLiters != null)
        _DetailsRowData(
          l10n.listingEngineDisplacement,
          formatEngineDisplacementForDisplay(
            l10n,
            listing.engineDisplacementLiters,
          ),
        ),
      if (listing.enginePowerHp != null)
        _DetailsRowData(
          l10n.listingEnginePower,
          formatEnginePowerHpDisplay(l10n, listing.enginePowerHp),
        ),
      if (listing.drivetrain != null)
        _DetailsRowData(
          l10n.listingDrivetrain,
          formatListingDrivetrain(l10n, listing.drivetrain!),
        ),
      if (listing.registration != null &&
          listing.registration!.trim().isNotEmpty)
        _DetailsRowData(l10n.listingRegistration, listing.registration!.trim()),
      _DetailsRowData(l10n.listingFieldPosted, formatDate(listing.createdAt)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.listingDetailsSpecs,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: -0.1,
          ),
        ),
        const SizedBox(height: 14),
        ListingDetailsVinEntry(listing: listing),
        const SizedBox(height: 12),
        for (var i = 0; i < rows.length; i++)
          _ListingSpecRow(
            data: rows[i],
            showBottomDivider: i < rows.length - 1,
          ),
      ],
    );
  }
}

class _DetailsRowData {
  const _DetailsRowData(this.label, this.value);
  final String label;
  final String value;
}

/// Two-column spec row: muted label left, strong value right; optional
/// full-width row divider only (no label/value connector).
class _ListingSpecRow extends StatelessWidget {
  const _ListingSpecRow({required this.data, required this.showBottomDivider});

  final _DetailsRowData data;
  final bool showBottomDivider;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final dividerAlpha = isDark ? 0.26 : 0.16;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 13),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 46,
                child: Text(
                  data.label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant.withValues(alpha: 0.78),
                    fontWeight: FontWeight.w400,
                    letterSpacing: 0.06,
                    height: 1.38,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                flex: 54,
                child: Text(
                  data.value,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurface.withValues(alpha: 0.95),
                    fontWeight: FontWeight.w600,
                    height: 1.38,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (showBottomDivider)
          Divider(
            height: 1,
            thickness: 0.5,
            color: scheme.outlineVariant.withValues(alpha: dividerAlpha),
          ),
      ],
    );
  }
}

/// Low-emphasis "Report listing" link kept at the bottom of scroll
/// content. Launch behavior unchanged from the previous surface so
/// the existing mailto unit/widget tests keep asserting the same URI.
class _ReportLink extends StatelessWidget {
  const _ReportLink({
    required this.listing,
    required this.recipientEmail,
    required this.launcher,
  });

  final Listing listing;
  final String recipientEmail;
  final ListingDetailsUriLauncher launcher;

  Future<void> _onTap(BuildContext context) async {
    final uri = buildReportListingMailto(
      l10n: context.l10n,
      listing: listing,
      recipientEmail: recipientEmail,
    );
    try {
      final ok = await launcher(uri);
      if (!ok && context.mounted) _showError(context);
    } catch (_) {
      if (context.mounted) _showError(context);
    }
  }

  void _showError(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(context.l10n.reportListingMailFailed)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.reportListingDescription,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => _onTap(context),
            icon: const Icon(CarzonIcons.report),
            label: Text(l10n.reportListing),
          ),
        ),
      ],
    );
  }
}
