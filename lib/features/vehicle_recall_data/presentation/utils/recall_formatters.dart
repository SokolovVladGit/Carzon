import '../../../../l10n/app_localizations.dart';
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
  final summary = readRecallText(campaign.summary);
  if (summary == null) return null;

  final headline = recallCampaignHeadline(campaign);
  if (headline != null && summary == headline) return null;

  if (summary.length <= kRecallCampaignPreviewMaxLength) return summary;

  final truncated = summary.substring(0, kRecallCampaignPreviewMaxLength).trimRight();
  return '$truncated…';
}

String? recallCampaignHeadline(BuyerListingRecallCampaign campaign) {
  return readRecallText(campaign.component) ??
      readRecallText(campaign.summary) ??
      formatRecallCampaignNumber(campaign.campaignNumber);
}
