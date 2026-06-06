import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/owner_listing_vin_report_status.dart';
import '../../domain/entities/owner_listing_vin_source_result.dart';
import '../utils/edit_listing_owner_vin_report_ui.dart';

class EditListingOwnerVinStatusSection extends StatelessWidget {
  const EditListingOwnerVinStatusSection({
    super.key,
    required this.listingVinStatus,
    required this.ownerVinReportStatus,
    required this.ownerVinReportLookupFailed,
    required this.ownerVinSourceResults,
    required this.ownerVinSourceResultsLookupFailed,
  });

  final ListingVinStatus listingVinStatus;
  final OwnerListingVinReportStatus? ownerVinReportStatus;
  final bool ownerVinReportLookupFailed;
  final List<OwnerListingVinSourceResult> ownerVinSourceResults;
  final bool ownerVinSourceResultsLookupFailed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final kind = resolveEditListingOwnerVinReportUiKind(
      listingPublicVinStatus: listingVinStatus,
      reportFetchFailed: ownerVinReportLookupFailed,
      report: ownerVinReportStatus,
    );
    final primary = editListingOwnerVinReportPrimaryLine(l10n, kind);
    final basic = resolveOwnerVinBasicDecodeFields(
      report: ownerVinReportStatus,
      sourceResults: ownerVinSourceResults,
      sourceResultsLookupFailed: ownerVinSourceResultsLookupFailed,
    );

    return DecoratedBox(
      key: const ValueKey('edit_listing_owner_vin_report_section'),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(
          alpha: 0.35,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.editListingVinReportSectionTitle,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              primary,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
            ),
            if (basic != null && basic.hasAny) ...[
              const SizedBox(height: 14),
              Text(
                l10n.editListingVinReportBasicInfoHeading,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              if (basic.make != null && basic.make!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedMakeLabel,
                  basic.make!.trim(),
                ),
              if (basic.model != null && basic.model!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedModelLabel,
                  basic.model!.trim(),
                ),
              if (basic.year != null)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedYearLabel,
                  '${basic.year}',
                ),
              if (basic.bodyType != null && basic.bodyType!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedBodyLabel,
                  basic.bodyType!.trim(),
                ),
              if (basic.fuelType != null && basic.fuelType!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.editListingVinReportDecodedFuelLabel,
                  basic.fuelType!.trim(),
                ),
              if (basic.engine != null && basic.engine!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.listingBuyerVinReportDecodedEngineLabel,
                  basic.engine!.trim(),
                ),
              if (basic.transmission != null &&
                  basic.transmission!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.listingBuyerVinReportDecodedTransmissionLabel,
                  basic.transmission!.trim(),
                ),
              if (basic.trim != null && basic.trim!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.listingBuyerVinReportNhtsaTrimLabel,
                  basic.trim!.trim(),
                ),
              if (basic.driveType != null && basic.driveType!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.listingBuyerVinReportNhtsaDriveTypeLabel,
                  basic.driveType!.trim(),
                ),
              if (basic.manufacturer != null &&
                  basic.manufacturer!.trim().isNotEmpty)
                _ownerVinDecodeSummaryFieldRow(
                  theme,
                  l10n.listingBuyerVinReportNhtsaManufacturerLabel,
                  basic.manufacturer!.trim(),
                ),
              const SizedBox(height: 10),
              Text(
                l10n.editListingVinReportSourceLine,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.35,
                ),
              ),
            ],
            const SizedBox(height: 10),
            Text(
              l10n.editListingVinReportLimitationNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              l10n.editListingVinReportPrivacyNote,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                height: 1.35,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _ownerVinDecodeSummaryFieldRow(
  ThemeData theme,
  String label,
  String value,
) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.85),
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.35),
          ),
        ),
      ],
    ),
  );
}
