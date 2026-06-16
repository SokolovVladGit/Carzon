import '../../../../l10n/app_localizations.dart';
import 'recall_component_display_labels.dart';
import '../../domain/entities/buyer_listing_recall_campaign.dart';
import '../../domain/entities/buyer_listing_recall_source_result.dart';

/// One label/value row for recall campaign display.
class RecallCampaignFieldDisplay {
  const RecallCampaignFieldDisplay({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

const int kRecallMaxDisplayedCampaigns = 10;
const int kRecallInitialVisibleCampaigns = 3;

bool recallResultHasDisplayableCampaigns(BuyerListingRecallSourceResult result) {
  return result.campaigns.any(recallCampaignHasUiDisplayableContent);
}

bool recallCampaignHasUiDisplayableContent(BuyerListingRecallCampaign campaign) {
  return readRecallText(campaign.campaignNumber) != null ||
      readRecallText(campaign.manufacturer) != null ||
      readRecallText(campaign.component) != null ||
      readRecallText(campaign.summary) != null ||
      readRecallText(campaign.consequence) != null ||
      readRecallText(campaign.remedy) != null ||
      readRecallText(campaign.notes) != null ||
      formatRecallDateString(campaign.reportReceivedDate) != null ||
      campaign.parkIt == true ||
      campaign.parkOutside == true ||
      campaign.overTheAirUpdate == true;
}

List<BuyerListingRecallCampaign> recallCampaignsForDisplay(
  BuyerListingRecallSourceResult result,
) {
  return result.campaigns
      .where(recallCampaignHasUiDisplayableContent)
      .take(kRecallMaxDisplayedCampaigns)
      .toList();
}

String? readRecallText(String? raw) {
  if (raw == null) return null;
  final text = raw.trim();
  return text.isEmpty ? null : text;
}

String formatRecallDate(DateTime dt) {
  final local = dt.toLocal();
  final d = local.day.toString().padLeft(2, '0');
  final m = local.month.toString().padLeft(2, '0');
  final y = local.year.toString().padLeft(4, '0');
  return '$d.$m.$y';
}

String? formatRecallDateString(String? raw) {
  final text = readRecallText(raw);
  if (text == null) return null;
  final parsed = DateTime.tryParse(text);
  if (parsed != null) return formatRecallDate(parsed);
  return text;
}

String resolveRecallSourceLabel(AppLocalizations l10n, String? sourceLabel) {
  final trimmed = sourceLabel?.trim();
  if (trimmed != null && trimmed.isNotEmpty) return trimmed;
  return l10n.listingRecallSourceBadge;
}

DateTime? resolveRecallLastUpdated({
  DateTime? fetchedAt,
  DateTime? sourceUpdatedAt,
  DateTime? updatedAt,
}) => fetchedAt ?? sourceUpdatedAt ?? updatedAt;

String formatRecallCampaignCountLabel(AppLocalizations l10n, int count) {
  return '${l10n.listingRecallCampaignCount}: $count';
}

String formatRecallCampaignCountStat(AppLocalizations l10n, int count) {
  return l10n.listingRecallCampaignCountStat(count);
}

String? formatRecallCampaignNumber(String? raw) => readRecallText(raw);

const int kRecallCampaignPreviewMaxLength = 140;

List<RecallCampaignFieldDisplay> buildRecallCampaignFieldRows(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  return [
    ...buildRecallCampaignCollapsedMetaRows(l10n, campaign),
    ...buildRecallCampaignDetailRows(l10n, campaign),
  ];
}

List<RecallCampaignFieldDisplay> buildRecallCampaignCollapsedMetaRows(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  final rows = <RecallCampaignFieldDisplay>[];

  void add(String label, String? value) {
    final text = readRecallText(value);
    if (text == null) return;
    rows.add(RecallCampaignFieldDisplay(label: label, value: text));
  }

  add(
    l10n.listingRecallCampaignNumber,
    formatRecallCampaignNumber(campaign.campaignNumber),
  );
  add(
    l10n.listingRecallReportReceivedDate,
    formatRecallDateString(campaign.reportReceivedDate),
  );
  add(l10n.listingRecallManufacturer, campaign.manufacturer);

  return rows;
}

List<RecallCampaignFieldDisplay> buildRecallCampaignSafetyFlagRows(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  final rows = <RecallCampaignFieldDisplay>[];

  if (campaign.parkIt == true) {
    rows.add(
      RecallCampaignFieldDisplay(
        label: l10n.listingRecallParkIt,
        value: l10n.listingRecallFlagYes,
      ),
    );
  }
  if (campaign.parkOutside == true) {
    rows.add(
      RecallCampaignFieldDisplay(
        label: l10n.listingRecallParkOutside,
        value: l10n.listingRecallFlagYes,
      ),
    );
  }
  if (campaign.overTheAirUpdate == true) {
    rows.add(
      RecallCampaignFieldDisplay(
        label: l10n.listingRecallOverTheAirUpdate,
        value: l10n.listingRecallFlagYes,
      ),
    );
  }

  return rows;
}

List<RecallCampaignFieldDisplay> buildRecallCampaignDetailRows(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  final rows = <RecallCampaignFieldDisplay>[];

  void add(String label, String? value) {
    final text = readRecallText(value);
    if (text == null) return;
    rows.add(RecallCampaignFieldDisplay(label: label, value: text));
  }

  add(l10n.listingRecallSummary, campaign.summary);
  add(l10n.listingRecallConsequence, campaign.consequence);
  add(l10n.listingRecallRemedy, campaign.remedy);
  add(l10n.listingRecallNotes, campaign.notes);
  add(l10n.listingRecallManufacturer, campaign.manufacturer);
  add(
    l10n.listingRecallReportReceivedDate,
    formatRecallDateString(campaign.reportReceivedDate),
  );
  rows.addAll(buildRecallCampaignSafetyFlagRows(l10n, campaign));

  return rows;
}

String? recallCampaignPreviewText(BuyerListingRecallCampaign campaign) {
  // Collapsed rows no longer show source preview; kept for tests/compatibility.
  return null;
}

/// Compact metadata for collapsed recall campaign rows.
class RecallCampaignCollapsedMeta {
  const RecallCampaignCollapsedMeta({
    this.campaignNumber,
    this.reportDate,
    this.manufacturer,
  });

  final String? campaignNumber;
  final String? reportDate;
  final String? manufacturer;

  bool get isEmpty =>
      campaignNumber == null && reportDate == null && manufacturer == null;
}

RecallCampaignCollapsedMeta buildRecallCampaignCollapsedMeta(
  BuyerListingRecallCampaign campaign,
) {
  return RecallCampaignCollapsedMeta(
    campaignNumber: formatRecallCampaignNumber(campaign.campaignNumber),
    reportDate: formatRecallDateString(campaign.reportReceivedDate),
    manufacturer: readRecallText(campaign.manufacturer),
  );
}

String? buildRecallCampaignCollapsedMetaLine(
  RecallCampaignCollapsedMeta meta,
) {
  final parts = <String>[];
  if (meta.campaignNumber != null) parts.add(meta.campaignNumber!);
  if (meta.reportDate != null) parts.add(meta.reportDate!);
  if (meta.manufacturer != null) parts.add(meta.manufacturer!);
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}

/// Formats raw NHTSA component strings (fallback title case, no l10n).
String formatRecallComponentDisplay(String raw) {
  return formatRecallComponentDisplayFallback(raw);
}

String? recallCampaignDisplayTitle(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  final component = readRecallText(campaign.component);
  if (component != null) {
    return resolveRecallComponentDisplayLabel(l10n, component);
  }
  return recallCampaignHeadline(l10n, campaign);
}

String? recallCampaignHeadline(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  final component = readRecallText(campaign.component);
  if (component != null) {
    return resolveRecallComponentDisplayLabel(l10n, component);
  }
  return formatRecallCampaignNumber(campaign.campaignNumber);
}

List<String> buildRecallCampaignSafetyFlagChipLabels(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  final chips = <String>[];
  if (campaign.parkIt == true) chips.add(l10n.listingRecallChipParkIt);
  if (campaign.parkOutside == true) {
    chips.add(l10n.listingRecallChipParkOutside);
  }
  if (campaign.overTheAirUpdate == true) {
    chips.add(l10n.listingRecallChipOverTheAirUpdate);
  }
  return chips;
}

List<String> summarizeRecallComponentCategories(
  AppLocalizations l10n,
  List<BuyerListingRecallCampaign> campaigns, {
  int max = 4,
}) {
  final seen = <String>{};
  final categories = <String>[];

  for (final campaign in campaigns) {
    final component = readRecallText(campaign.component);
    if (component == null) continue;

    final display = resolveRecallComponentCategoryLabel(l10n, component);
    if (display.isEmpty) continue;

    final key = display.toLowerCase();
    if (seen.contains(key)) continue;
    seen.add(key);
    categories.add(display);
    if (categories.length >= max) break;
  }

  return categories;
}

List<RecallCampaignDetailSection> buildRecallCampaignExpandedSections(
  AppLocalizations l10n,
  BuyerListingRecallCampaign campaign,
) {
  final sections = <RecallCampaignDetailSection>[];

  void add(String title, String? value) {
    final text = readRecallText(value);
    if (text == null) return;
    sections.add(RecallCampaignDetailSection(title: title, body: text));
  }

  add(l10n.listingRecallSummary, campaign.summary);
  add(l10n.listingRecallConsequence, campaign.consequence);
  add(l10n.listingRecallRemedy, campaign.remedy);
  add(l10n.listingRecallNotes, campaign.notes);
  add(l10n.listingRecallSourceComponent, campaign.component);

  return sections;
}

/// One titled block inside an expanded recall campaign row.
class RecallCampaignDetailSection {
  const RecallCampaignDetailSection({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}
