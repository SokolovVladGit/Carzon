import '../../../../l10n/app_localizations.dart';

/// Registry access mode for future DB-driven source results (Phase C: display only).
enum VinManualSourceAccessMode {
  manualExternalCheck,
  sellerUploadedDocument,
  commercialApiFuture,
}

/// Static manual/external VIN report card (no live data; not a completed check).
class VinManualSourceCardDefinition {
  const VinManualSourceCardDefinition({
    required this.sourceId,
    required this.title,
    required this.body,
    required this.statusLabel,
    required this.limitationLine,
    required this.accessMode,
  });

  final String sourceId;
  final String title;
  final String body;
  final String statusLabel;
  final String limitationLine;
  final VinManualSourceAccessMode accessMode;
}

/// Phase C informational cards shown in the buyer VIN report (Flutter-only registry).
List<VinManualSourceCardDefinition> buildBuyerVinManualSourceCards(
  AppLocalizations l10n,
) {
  return [
    VinManualSourceCardDefinition(
      sourceId: 'md_rca_damage',
      title: l10n.listingBuyerVinReportManualMdRcaTitle,
      body: l10n.listingBuyerVinReportManualMdRcaBody,
      statusLabel: l10n.listingBuyerVinReportManualStatusExternalCheck,
      limitationLine: l10n.listingBuyerVinReportManualMdRcaLimitation,
      accessMode: VinManualSourceAccessMode.manualExternalCheck,
    ),
    VinManualSourceCardDefinition(
      sourceId: 'md_asp_vehicle_registry',
      title: l10n.listingBuyerVinReportManualMdAspTitle,
      body: l10n.listingBuyerVinReportManualMdAspBody,
      statusLabel: l10n.listingBuyerVinReportManualStatusSellerDocument,
      limitationLine: l10n.listingBuyerVinReportManualMdAspLimitation,
      accessMode: VinManualSourceAccessMode.sellerUploadedDocument,
    ),
    VinManualSourceCardDefinition(
      sourceId: 'pmr_customs_clearance',
      title: l10n.listingBuyerVinReportManualPmrCustomsTitle,
      body: l10n.listingBuyerVinReportManualPmrCustomsBody,
      statusLabel: l10n.listingBuyerVinReportManualStatusExternalCheck,
      limitationLine: l10n.listingBuyerVinReportManualPmrCustomsLimitation,
      accessMode: VinManualSourceAccessMode.manualExternalCheck,
    ),
    VinManualSourceCardDefinition(
      sourceId: 'commercial_vehicle_history',
      title: l10n.listingBuyerVinReportManualCommercialTitle,
      body: l10n.listingBuyerVinReportManualCommercialBody,
      statusLabel: l10n.listingBuyerVinReportManualStatusFuture,
      limitationLine: l10n.listingBuyerVinReportManualCommercialLimitation,
      accessMode: VinManualSourceAccessMode.commercialApiFuture,
    ),
  ];
}

/// Stable source IDs for tests and future server-side alignment.
const List<String> kBuyerVinManualSourceCardIds = [
  'md_rca_damage',
  'md_asp_vehicle_registry',
  'pmr_customs_clearance',
  'commercial_vehicle_history',
];
