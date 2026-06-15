import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
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

    final result = _result!;
    final campaigns = recallCampaignsForDisplay(result);
    if (campaigns.isEmpty) {
      return const SizedBox.shrink(
        key: ValueKey('listing_recall_empty_campaigns'),
      );
    }

    final l10n = context.l10n;
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

    final cardDecoration = isDark
        ? AppTheme.editorialDarkSectionCard(scheme, borderRadius: 14)!
        : BoxDecoration(
            color: scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: scheme.outlineVariant.withValues(alpha: 0.32),
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
              letterSpacing: -0.1,
              color: isDark
                  ? scheme.onSurface.withValues(alpha: 0.96)
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          DecoratedBox(
            decoration: cardDecoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _RecallSourceLine(
                    theme: theme,
                    sourceLabel: sourceLabel,
                    lastUpdated: lastUpdated,
                    lastUpdatedLabel: l10n.listingRecallLastUpdated,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.listingRecallCampaignsFound,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      height: 1.35,
                      color: scheme.onSurface.withValues(
                        alpha: isDark ? 0.92 : 0.88,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    key: const ValueKey('listing_recall_campaign_count'),
                    formatRecallCampaignCountLabel(l10n, count),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: isDark ? 0.82 : 1,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var i = 0; i < campaigns.length; i++)
                    _RecallCampaignCard(
                      theme: theme,
                      l10n: l10n,
                      campaign: campaigns[i],
                      index: i,
                      showTopDivider: i > 0,
                    ),
                  if (limitations.isNotEmpty) ...[
                    const SizedBox(height: 6),
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

class _RecallSourceLine extends StatelessWidget {
  const _RecallSourceLine({
    required this.theme,
    required this.sourceLabel,
    required this.lastUpdatedLabel,
    this.lastUpdated,
  });

  final ThemeData theme;
  final String sourceLabel;
  final String lastUpdatedLabel;
  final DateTime? lastUpdated;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          key: const ValueKey('listing_recall_source_badge'),
          sourceLabel,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.1,
            color: scheme.primary.withValues(alpha: isDark ? 0.95 : 0.92),
          ),
        ),
        if (lastUpdated != null) ...[
          const SizedBox(height: 4),
          Text(
            key: const ValueKey('listing_recall_last_updated'),
            '$lastUpdatedLabel ${formatRecallDate(lastUpdated!)}',
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.78 : 1,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecallCampaignCard extends StatefulWidget {
  const _RecallCampaignCard({
    required this.theme,
    required this.l10n,
    required this.campaign,
    required this.index,
    required this.showTopDivider,
  });

  final ThemeData theme;
  final AppLocalizations l10n;
  final BuyerListingRecallCampaign campaign;
  final int index;
  final bool showTopDivider;

  @override
  State<_RecallCampaignCard> createState() => _RecallCampaignCardState();
}

class _RecallCampaignCardState extends State<_RecallCampaignCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = widget.theme;
    final l10n = widget.l10n;
    final campaign = widget.campaign;
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final headline = recallCampaignHeadline(campaign);
    final collapsedMeta = buildRecallCampaignCollapsedMetaRows(l10n, campaign);
    final safetyFlags = buildRecallCampaignSafetyFlagRows(l10n, campaign);
    final preview = recallCampaignPreviewText(campaign);
    final detailRows = buildRecallCampaignDetailRows(l10n, campaign);
    final hasExpandableDetails = detailRows.isNotEmpty;

    return Column(
      key: ValueKey('listing_recall_campaign_${widget.index}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.showTopDivider)
          Divider(
            height: 17,
            thickness: 0.5,
            color: scheme.outlineVariant.withValues(alpha: isDark ? 0.22 : 0.28),
          ),
        if (headline != null)
          Text(
            headline,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              height: 1.25,
              color: scheme.onSurface.withValues(alpha: isDark ? 0.94 : 1),
            ),
          ),
        if (!_expanded) ...[
          for (final row in collapsedMeta) ...[
            const SizedBox(height: 4),
            _RecallCampaignFieldRow(theme: theme, field: row),
          ],
          if (preview != null) ...[
            const SizedBox(height: 4),
            Text(
              key: ValueKey('listing_recall_campaign_preview_${widget.index}'),
              preview,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodySmall?.copyWith(
                height: 1.35,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.88 : 0.92,
                ),
              ),
            ),
          ],
          for (final row in safetyFlags) ...[
            const SizedBox(height: 4),
            _RecallCampaignFieldRow(theme: theme, field: row),
          ],
        ] else ...[
          for (final row in detailRows) ...[
            const SizedBox(height: 4),
            _RecallCampaignFieldRow(theme: theme, field: row),
          ],
        ],
        if (hasExpandableDetails) ...[
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              key: ValueKey('listing_recall_campaign_toggle_${widget.index}'),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _expanded = !_expanded),
              child: Text(
                _expanded
                    ? l10n.listingRecallHideDetails
                    : l10n.listingRecallShowDetails,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _RecallCampaignFieldRow extends StatelessWidget {
  const _RecallCampaignFieldRow({required this.theme, required this.field});

  final ThemeData theme;
  final RecallCampaignFieldDisplay field;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 4,
          child: Text(
            field.label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(
                alpha: isDark ? 0.82 : 1,
              ),
            ),
          ),
        ),
        Expanded(
          flex: 6,
          child: Text(
            field.value,
            style: theme.textTheme.bodySmall?.copyWith(
              height: 1.35,
              color: scheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.9),
            ),
          ),
        ),
      ],
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: isDark ? 0.28 : 0.32),
        ),
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.35)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.22),
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
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
              height: 1.25,
              color: scheme.onSurface.withValues(alpha: isDark ? 0.9 : 0.88),
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
                                  alpha: isDark ? 0.88 : 1,
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
