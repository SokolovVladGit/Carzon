import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';

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

    return _StatisticsSectionCard(
      cardKey: rootKey,
      title: l10n.statisticsInterestFunnel,
      child: Column(
        children: [
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
    return _StatisticsSectionCard(
      cardKey: rootKey,
      title: l10n.statisticsContactActions,
      child: Column(
        children: [
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

class _StatisticsSectionCard extends StatelessWidget {
  const _StatisticsSectionCard({
    required this.cardKey,
    required this.title,
    required this.child,
  });

  final Key cardKey;
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return DecoratedBox(
      key: cardKey,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        boxShadow: AppTheme.softCardShadow(scheme),
      ),
      child: Material(
        color: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(26),
          side: BorderSide(color: AppTheme.softCardBorderColor(scheme)),
        ),
        clipBehavior: Clip.antiAlias,
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppTheme.softCardGroupedGradient(scheme),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.08,
                  ),
                ),
                const SizedBox(height: 14),
                child,
              ],
            ),
          ),
        ),
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
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$value',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 8,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth * fraction;
                  return Stack(
                    children: [
                      ColoredBox(
                        color: scheme.surfaceContainerHighest.withValues(
                          alpha: 0.7,
                        ),
                        child: const SizedBox.expand(),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ColoredBox(
                          color: scheme.primary.withValues(alpha: 0.72),
                          child: SizedBox(width: width, height: 8),
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
            ),
          ),
        ],
      ),
    );
  }
}
