import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/presentation/widgets/official_data_editorial.dart';
import '../../../listings/presentation/widgets/official_data_pending_card.dart';
import '../../domain/entities/buyer_listing_recall_campaign.dart';
import '../../domain/entities/buyer_listing_recall_source_result.dart';
import '../../domain/usecases/get_listing_recalls_for_buyer.dart';
import '../utils/recall_formatters.dart';
import '../utils/recall_limitation_labels.dart';
import '../utils/recall_ui_state.dart';

/// Buyer-facing model-level recall campaigns on listing details (NHTSA in v1).
class ListingDetailsRecallSection extends StatefulWidget {
  const ListingDetailsRecallSection({super.key, required this.listingId});

  final String listingId;

  @override
  State<ListingDetailsRecallSection> createState() =>
      _ListingDetailsRecallSectionState();
}

class _ListingDetailsRecallSectionState extends State<ListingDetailsRecallSection> {
  bool _loading = true;
  bool _fetchFailed = false;
  BuyerListingRecallSourceResult? _result;
  bool _showAllCampaigns = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final useCase = sl<GetListingRecallsForBuyer>();
    final out = await useCase(widget.listingId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (out) {
        case Success(:final value):
          _result = value;
          _fetchFailed = false;
        case FailureResult():
          _result = null;
          _fetchFailed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uiState = resolveRecallUiState(
      loading: _loading,
      fetchFailed: _fetchFailed,
      result: _result,
    );

    if (uiState == RecallUiState.hidden || uiState == RecallUiState.loading) {
      return const SizedBox.shrink(
        key: ValueKey('listing_recall_hidden'),
      );
    }

    final l10n = context.l10n;

    if (uiState == RecallUiState.pendingOrNotReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            l10n.listingRecallTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 12),
          OfficialDataPendingCard(
            sectionKey: const ValueKey('listing_recall_pending'),
            includeLeadingSpacing: false,
            title: l10n.listingRecallPendingTitle,
            body: l10n.listingRecallPendingBody,
            sourceNote: l10n.listingRecallPendingLimitationNote,
            leadingIcon: Icons.health_and_safety_outlined,
            statusIcon: Icons.fact_check_outlined,
          ),
        ],
      );
    }

    final result = _result!;
    final campaigns = recallCampaignsForDisplay(result);
    if (campaigns.isEmpty) {
      return const SizedBox.shrink(
        key: ValueKey('listing_recall_empty_campaigns'),
      );
    }

    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final sourceLabel = resolveRecallSourceLabel(l10n, result.sourceLabel);
    final lastUpdated = resolveRecallLastUpdated(
      fetchedAt: result.fetchedAt,
      sourceUpdatedAt: result.sourceUpdatedAt,
      updatedAt: result.updatedAt,
    );
    final count = result.campaignCount > 0
        ? result.campaignCount
        : campaigns.length;
    final limitations = localizedRecallLimitationBullets(
      l10n,
      result.limitationCodes,
    );
    final categoryChips = summarizeRecallComponentCategories(l10n, campaigns);
    final visibleCampaignCount = _showAllCampaigns
        ? campaigns.length
        : campaigns.length.clamp(0, kRecallInitialVisibleCampaigns);
    final hiddenCampaignCount = campaigns.length - kRecallInitialVisibleCampaigns;

    final cardDecoration = isDark
        ? AppTheme.editorialDarkSectionCard(scheme, borderRadius: 16)!
        : BoxDecoration(
            color: scheme.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.28),
            ),
          );

    return Semantics(
      container: true,
      label: l10n.listingRecallTitle,
      child: Column(
        key: const ValueKey('listing_recall_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            l10n.listingRecallTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.2,
              color: isDark
                  ? scheme.onSurface.withValues(alpha: 0.96)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: cardDecoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RecallSummaryBlock(
                    theme: theme,
                    l10n: l10n,
                    sourceLabel: sourceLabel,
                    lastUpdated: lastUpdated,
                    lastUpdatedLabel: l10n.listingRecallLastUpdated,
                    summaryCopy: l10n.listingRecallCampaignsFound,
                    campaignCount: count,
                    categoryChips: categoryChips,
                  ),
                  const SizedBox(height: 12),
                  for (var i = 0; i < visibleCampaignCount; i++) ...[
                    if (i > 0)
                      Divider(
                        height: 1,
                        thickness: 0.5,
                        color: scheme.outlineVariant.withValues(
                          alpha: isDark ? 0.16 : 0.2,
                        ),
                      ),
                    _RecallCampaignTile(
                      theme: theme,
                      l10n: l10n,
                      campaign: campaigns[i],
                      index: i,
                    ),
                  ],
                  if (!_showAllCampaigns && hiddenCampaignCount > 0) ...[
                    const SizedBox(height: 6),
                    OfficialDataShowMoreAction(
                      theme: theme,
                      actionKey: const ValueKey('listing_recall_show_all'),
                      label: l10n.listingRecallShowAllCampaigns(campaigns.length),
                      onPressed: () =>
                          setState(() => _showAllCampaigns = true),
                    ),
                  ],
                  if (limitations.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _RecallLimitationsCollapsible(
                      theme: theme,
                      title: l10n.listingRecallLimitationsTitle,
                      bullets: limitations,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RecallSummaryBlock extends StatelessWidget {
  const _RecallSummaryBlock({
    required this.theme,
    required this.l10n,
    required this.sourceLabel,
    required this.lastUpdatedLabel,
    required this.summaryCopy,
    required this.campaignCount,
    required this.categoryChips,
    this.lastUpdated,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final String sourceLabel;
  final String lastUpdatedLabel;
  final String summaryCopy;
  final int campaignCount;
  final List<String> categoryChips;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      key: const ValueKey('listing_recall_summary_block'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OfficialDataSourceHeader(
          theme: theme,
          sourceKey: const ValueKey('listing_recall_source_badge'),
          sourceLabel: sourceLabel,
          updatedDateKey: lastUpdated != null
              ? const ValueKey('listing_recall_last_updated')
              : null,
          updatedDateLabel: lastUpdated != null
              ? '$lastUpdatedLabel ${formatRecallDate(lastUpdated!)}'
              : null,
        ),
        const SizedBox(height: 10),
        Text(
          summaryCopy,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.35,
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.86 : 0.84,
            ),
          ),
        ),
        const SizedBox(height: 8),
        OfficialDataCountStat(
          theme: theme,
          statKey: const ValueKey('listing_recall_campaign_count'),
          label: formatRecallCampaignCountStat(l10n, campaignCount),
        ),
        if (categoryChips.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            key: const ValueKey('listing_recall_category_chips'),
            spacing: 6,
            runSpacing: 6,
            children: categoryChips
                .map(
                  (chip) => OfficialDataCategoryChip(theme: theme, label: chip),
                )
                .toList(),
          ),
        ],
      ],
    );
  }
}

class _RecallCampaignTile extends StatefulWidget {
  const _RecallCampaignTile({
    required this.theme,
    required this.l10n,
    required this.campaign,
    required this.index,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final BuyerListingRecallCampaign campaign;
  final int index;

  @override
  State<_RecallCampaignTile> createState() => _RecallCampaignTileState();
}

class _RecallCampaignTileState extends State<_RecallCampaignTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = widget.l10n;
    final campaign = widget.campaign;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final title = recallCampaignDisplayTitle(l10n, campaign);
    final collapsedMeta = buildRecallCampaignCollapsedMeta(campaign);
    final collapsedMetaLine = buildRecallCampaignCollapsedMetaLine(collapsedMeta);
    final flagChips = buildRecallCampaignSafetyFlagChipLabels(l10n, campaign);
    final detailSections = buildRecallCampaignExpandedSections(l10n, campaign);
    final hasExpandableDetails =
        detailSections.isNotEmpty ||
        readRecallText(campaign.summary) != null ||
        readRecallText(campaign.consequence) != null ||
        readRecallText(campaign.remedy) != null ||
        readRecallText(campaign.notes) != null ||
        flagChips.isNotEmpty;

    final tileDecoration = _expanded
        ? BoxDecoration(
            color: isDark
                ? scheme.surfaceContainerHigh.withValues(alpha: 0.16)
                : scheme.surfaceContainerHighest.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(10),
          )
        : null;

    return Column(
      key: ValueKey('listing_recall_campaign_${widget.index}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            key: ValueKey('listing_recall_campaign_toggle_${widget.index}'),
            borderRadius: BorderRadius.circular(10),
            onTap: hasExpandableDetails
                ? () => setState(() => _expanded = !_expanded)
                : null,
            child: DecoratedBox(
              decoration: tileDecoration ?? const BoxDecoration(),
              child: Padding(
                padding: EdgeInsets.fromLTRB(4, 8, 2, _expanded ? 4 : 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (title != null)
                                Text(
                                  title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    height: 1.22,
                                    color: scheme.onSurface.withValues(
                                      alpha: isDark ? 0.95 : 0.96,
                                    ),
                                  ),
                                ),
                              if (!_expanded && collapsedMetaLine != null) ...[
                                const SizedBox(height: 3),
                                Text(
                                  collapsedMetaLine,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    height: 1.25,
                                    color: scheme.onSurfaceVariant.withValues(
                                      alpha: isDark ? 0.78 : 0.82,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (hasExpandableDetails)
                          Padding(
                            padding: const EdgeInsets.only(left: 4, top: 1),
                            child: Icon(
                              _expanded
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.keyboard_arrow_down_rounded,
                              size: 22,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: isDark ? 0.72 : 0.76,
                              ),
                            ),
                          ),
                      ],
                    ),
                    if (!_expanded && flagChips.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      _RecallSafetyFlagChips(
                        theme: theme,
                        labels: flagChips,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 2, 4, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var i = 0; i < detailSections.length; i++) ...[
                  if (i == 0) const SizedBox(height: 4),
                  if (i > 0) const SizedBox(height: 8),
                  _RecallDetailSectionBlock(theme: theme, section: detailSections[i]),
                ],
                  if (readRecallText(campaign.manufacturer) != null ||
                      formatRecallDateString(campaign.reportReceivedDate) !=
                          null) ...[
                    const SizedBox(height: 8),
                    _RecallExpandedMetaBlock(
                      theme: theme,
                      l10n: l10n,
                      campaign: campaign,
                    ),
                  ],
                  if (flagChips.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _RecallSafetyFlagChips(theme: theme, labels: flagChips),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _RecallDetailSectionBlock extends StatelessWidget {
  const _RecallDetailSectionBlock({
    required this.theme,
    required this.section,
  });

  final ThemeData theme;
  final RecallCampaignDetailSection section;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          section.title,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 0.04,
            color: scheme.onSurfaceVariant.withValues(
              alpha: isDark ? 0.8 : 0.74,
            ),
          ),
        ),
        const SizedBox(height: 3),
        Text(
          section.body,
          style: theme.textTheme.bodySmall?.copyWith(
            height: 1.42,
            color: scheme.onSurface.withValues(alpha: isDark ? 0.9 : 0.86),
          ),
        ),
      ],
    );
  }
}

class _RecallExpandedMetaBlock extends StatelessWidget {
  const _RecallExpandedMetaBlock({
    required this.theme,
    required this.l10n,
    required this.campaign,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final BuyerListingRecallCampaign campaign;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final rows = buildRecallCampaignCollapsedMetaRows(l10n, campaign);
    if (rows.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: rows
          .map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodySmall?.copyWith(
                    height: 1.35,
                    color: scheme.onSurfaceVariant.withValues(
                      alpha: isDark ? 0.82 : 0.88,
                    ),
                  ),
                  children: [
                    TextSpan(
                      text: '${row.label}: ',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: scheme.onSurface.withValues(
                          alpha: isDark ? 0.86 : 0.82,
                        ),
                      ),
                    ),
                    TextSpan(text: row.value),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecallSafetyFlagChips extends StatelessWidget {
  const _RecallSafetyFlagChips({
    required this.theme,
    required this.labels,
  });

  final ThemeData theme;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: labels
          .map(
            (label) => DecoratedBox(
              decoration: BoxDecoration(
                color: scheme.errorContainer.withValues(
                  alpha: isDark ? 0.28 : 0.45,
                ),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                child: Text(
                  label,
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: scheme.onErrorContainer.withValues(
                      alpha: isDark ? 0.92 : 0.88,
                    ),
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _RecallLimitationsCollapsible extends StatelessWidget {
  const _RecallLimitationsCollapsible({
    required this.theme,
    required this.title,
    required this.bullets,
  });

  final ThemeData theme;
  final String title;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return DecoratedBox(
      key: const ValueKey('listing_recall_limitations'),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.16)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.12),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: scheme.onSurface.withValues(alpha: 0.04),
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.fromLTRB(14, 2, 8, 2),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
          iconColor: scheme.onSurfaceVariant,
          collapsedIconColor: scheme.onSurfaceVariant,
          title: Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.05,
              height: 1.25,
              color: scheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.88 : 0.86,
              ),
            ),
          ),
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: bullets
                  .map(
                    (b) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '• ',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                          Expanded(
                            child: Text(
                              b,
                              style: theme.textTheme.bodySmall?.copyWith(
                                height: 1.4,
                                color: scheme.onSurfaceVariant.withValues(
                                  alpha: isDark ? 0.88 : 0.92,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }
}
