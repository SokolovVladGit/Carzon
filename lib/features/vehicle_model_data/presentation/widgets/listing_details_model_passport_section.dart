import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/buyer_listing_model_data_source_result.dart';
import '../../domain/usecases/get_listing_model_data_for_buyer.dart';
import '../utils/model_passport_formatters.dart';
import '../utils/model_passport_limitation_labels.dart';
import '../utils/model_passport_ui_state.dart';

/// Buyer-facing official model data on listing details (EPA fuel economy in v1).
class ListingDetailsModelPassportSection extends StatefulWidget {
  const ListingDetailsModelPassportSection({super.key, required this.listingId});

  final String listingId;

  @override
  State<ListingDetailsModelPassportSection> createState() =>
      _ListingDetailsModelPassportSectionState();
}

class _ListingDetailsModelPassportSectionState
    extends State<ListingDetailsModelPassportSection> {
  bool _loading = true;
  bool _fetchFailed = false;
  List<BuyerListingModelDataSourceResult> _rows = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final useCase = sl<GetListingModelDataForBuyer>();
    final out = await useCase(widget.listingId);
    if (!mounted) return;
    setState(() {
      _loading = false;
      switch (out) {
        case Success(:final value):
          _rows = value;
          _fetchFailed = false;
        case FailureResult():
          _rows = const [];
          _fetchFailed = true;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final uiState = resolveModelPassportUiState(
      loading: _loading,
      fetchFailed: _fetchFailed,
      rows: _rows,
    );

    if (uiState == ModelPassportUiState.hidden ||
        uiState == ModelPassportUiState.loading) {
      return const SizedBox.shrink(
        key: ValueKey('listing_model_passport_hidden'),
      );
    }

    final row = selectModelPassportEpaRow(_rows)!;
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final metrics = buildModelPassportMetricRows(l10n, row.normalizedSummary);
    if (metrics.isEmpty) {
      return const SizedBox.shrink(
        key: ValueKey('listing_model_passport_empty_metrics'),
      );
    }

    final sourceLabel = resolveModelPassportSourceLabel(l10n, row.sourceLabel);
    final lastUpdated = resolveModelPassportLastUpdated(
      fetchedAt: row.fetchedAt,
      updatedAt: row.updatedAt,
    );
    final limitationCodes = List<String>.from(row.limitationCodes);
    if (uiState == ModelPassportUiState.partial &&
        !limitationCodes.contains('multiple_configurations_possible')) {
      limitationCodes.add('multiple_configurations_possible');
    }
    final limitations = localizedModelPassportLimitationBullets(
      l10n,
      limitationCodes,
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
      label: l10n.listingModelPassportSectionTitle,
      child: Column(
        key: const ValueKey('listing_model_passport_section'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.listingModelPassportSectionTitle,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
              color: isDark
                  ? scheme.onSurface.withValues(alpha: 0.96)
                  : null,
            ),
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: cardDecoration,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _ModelPassportSourceLine(
                    theme: theme,
                    sourceLabel: sourceLabel,
                    lastUpdated: lastUpdated,
                    lastUpdatedLabel: l10n.listingModelPassportLastUpdated,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.listingModelPassportFuelEconomyTitle,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      height: 1.25,
                      color: scheme.onSurface.withValues(
                        alpha: isDark ? 0.92 : 0.88,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ...metrics.map(
                    (m) => _ModelPassportMetricRow(
                      theme: theme,
                      metric: m,
                    ),
                  ),
                  if (limitations.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    _ModelPassportLimitationsCollapsible(
                      theme: theme,
                      title: l10n.listingModelPassportLimitationsTitle,
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

class _ModelPassportSourceLine extends StatelessWidget {
  const _ModelPassportSourceLine({
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
          key: const ValueKey('listing_model_passport_source_badge'),
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
            key: const ValueKey('listing_model_passport_last_updated'),
            '$lastUpdatedLabel ${formatModelPassportDate(lastUpdated!)}',
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

class _ModelPassportMetricRow extends StatelessWidget {
  const _ModelPassportMetricRow({required this.theme, required this.metric});

  final ThemeData theme;
  final ModelPassportMetricDisplay metric;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final valueText = metric.unit == null
        ? metric.value
        : '${metric.value} ${metric.unit}';

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 5,
            child: Text(
              metric.label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.82 : 1,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              valueText,
              textAlign: TextAlign.end,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: isDark ? 0.94 : 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ModelPassportLimitationsCollapsible extends StatelessWidget {
  const _ModelPassportLimitationsCollapsible({
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
      key: const ValueKey('listing_model_passport_limitations'),
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
