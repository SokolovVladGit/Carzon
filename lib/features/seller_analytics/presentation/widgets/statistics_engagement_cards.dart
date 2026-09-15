import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import 'statistics_surface.dart';

class StatisticsInterestFunnelCard extends StatelessWidget {
  const StatisticsInterestFunnelCard({
    super.key,
    required this.impressions,
    required this.views,
    required this.inquiries,
  });

  static const Key rootKey = ValueKey<String>('statistics_interest_funnel');
  static const Key impressionsKey = ValueKey<String>(
    'statistics_funnel_impressions',
  );
  static const Key viewsKey = ValueKey<String>('statistics_funnel_views');
  static const Key inquiriesKey = ValueKey<String>(
    'statistics_funnel_inquiries',
  );

  final int impressions;
  final int views;
  final int inquiries;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final maxValue = [
      impressions,
      views,
      inquiries,
    ].reduce((a, b) => a > b ? a : b);

    return KeyedSubtree(
      key: rootKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatisticsSectionTitle(title: l10n.statisticsInterestFunnel),
          const SizedBox(height: 14),
          _FunnelMetricRow(
            rowKey: impressionsKey,
            label: l10n.statisticsFunnelImpressions,
            value: impressions,
            maxValue: maxValue,
          ),
          const SizedBox(height: 12),
          _FunnelMetricRow(
            rowKey: viewsKey,
            label: l10n.statisticsFunnelViews,
            value: views,
            maxValue: maxValue,
          ),
          const SizedBox(height: 12),
          _FunnelMetricRow(
            rowKey: inquiriesKey,
            label: l10n.statisticsFunnelInquiries,
            value: inquiries,
            maxValue: maxValue,
          ),
        ],
      ),
    );
  }
}

class StatisticsContactActionsCard extends StatelessWidget {
  const StatisticsContactActionsCard({
    super.key,
    required this.phoneActions,
    required this.whatsappActions,
    required this.telegramActions,
    required this.shares,
    required this.contactActions,
  });

  static const Key rootKey = ValueKey<String>('statistics_contact_actions');
  static const Key phoneKey = ValueKey<String>('statistics_contact_phone');
  static const Key whatsappKey = ValueKey<String>(
    'statistics_contact_whatsapp',
  );
  static const Key telegramKey = ValueKey<String>(
    'statistics_contact_telegram',
  );
  static const Key sharesKey = ValueKey<String>('statistics_contact_shares');
  static const Key totalKey = ValueKey<String>(
    'statistics_contact_actions_total',
  );

  final int phoneActions;
  final int whatsappActions;
  final int telegramActions;
  final int shares;
  final int contactActions;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return KeyedSubtree(
      key: rootKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          StatisticsSectionTitle(title: l10n.statisticsContactActions),
          const SizedBox(height: 14),
          _ContactMetricRow(
            rowKey: totalKey,
            label: l10n.statisticsContactActionsTotal,
            value: contactActions,
            emphasize: true,
          ),
          const SizedBox(height: 10),
          _ContactMetricRow(
            rowKey: phoneKey,
            label: l10n.statisticsMetricPhone,
            value: phoneActions,
          ),
          const SizedBox(height: 8),
          _ContactMetricRow(
            rowKey: whatsappKey,
            label: l10n.statisticsMetricWhatsapp,
            value: whatsappActions,
          ),
          const SizedBox(height: 8),
          _ContactMetricRow(
            rowKey: telegramKey,
            label: l10n.statisticsMetricTelegram,
            value: telegramActions,
          ),
          const SizedBox(height: 8),
          _ContactMetricRow(
            rowKey: sharesKey,
            label: l10n.statisticsMetricShares,
            value: shares,
          ),
        ],
      ),
    );
  }
}

class _FunnelMetricRow extends StatelessWidget {
  const _FunnelMetricRow({
    required this.rowKey,
    required this.label,
    required this.value,
    required this.maxValue,
  });

  final Key rowKey;
  final String label;
  final int value;
  final int maxValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final fraction = maxValue <= 0 ? 0.0 : (value / maxValue).clamp(0.0, 1.0);
    final accent = AppTheme.editorialAccentColor(scheme);
    return KeyedSubtree(
      key: rowKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: SizedBox(
              height: 6,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth * fraction;
                  return Stack(
                    children: [
                      ColoredBox(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: scheme.brightness == Brightness.dark
                              ? 0.45
                              : 0.7,
                        ),
                        child: const SizedBox.expand(),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ColoredBox(
                          color: accent.withValues(alpha: 0.62),
                          child: SizedBox(width: width, height: 6),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactMetricRow extends StatelessWidget {
  const _ContactMetricRow({
    required this.rowKey,
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  final Key rowKey;
  final String label;
  final int value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return KeyedSubtree(
      key: rowKey,
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: emphasize
                  ? theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    )
                  : theme.textTheme.bodyMedium?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
            ),
          ),
          Text(
            '$value',
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: emphasize ? FontWeight.w800 : FontWeight.w700,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
