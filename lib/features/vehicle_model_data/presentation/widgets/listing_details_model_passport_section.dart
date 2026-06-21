import 'package:flutter/material.dart';

import '../../../../app/di/injection.dart';
import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/presentation/widgets/official_data_editorial.dart';
import '../../../listings/presentation/widgets/official_data_pending_card.dart';
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

    final l10n = context.l10n;

    if (uiState == ModelPassportUiState.pendingOrNotReady) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 24),
          Text(
            l10n.listingModelPassportSectionTitle,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
              letterSpacing: -0.1,
            ),
          ),
          const SizedBox(height: 12),
          OfficialDataPendingCard(
            sectionKey: const ValueKey('listing_model_passport_pending'),
            includeLeadingSpacing: false,
            title: l10n.listingModelPassportPendingTitle,
            body: l10n.listingModelPassportPendingBody,
            sourceNote: l10n.listingModelPassportSourceEpa,
            sourceNoteStyle: OfficialDataPendingSourceNoteStyle.sourceBadge,
            leadingIcon: Icons.speed_rounded,
            statusIcon: Icons.sync_rounded,
          ),
        ],
      );
    }

    final row = selectModelPassportEpaRow(_rows)!;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final metrics = buildModelPassportMetricRows(l10n, row.normalizedSummary);
    final primaryTiles = buildModelPassportPrimaryMetricTiles(
      l10n,
      row.normalizedSummary,
    );
    final co2Tile = buildModelPassportCo2MetricTile(l10n, row.normalizedSummary);
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
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OfficialDataSourceHeader(
                    theme: theme,
                    sourceKey: const ValueKey('listing_model_passport_source_badge'),
                    sourceLabel: sourceLabel,
                    updatedDateKey: lastUpdated != null
                        ? const ValueKey('listing_model_passport_last_updated')
                        : null,
                    updatedDateLabel: lastUpdated != null
                        ? '${l10n.listingModelPassportLastUpdated} ${formatModelPassportDate(lastUpdated)}'
                        : null,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.listingModelPassportFuelEconomyTitle,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.08,
                      height: 1.2,
                      color: scheme.onSurfaceVariant.withValues(
                        alpha: isDark ? 0.82 : 0.78,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (primaryTiles.isNotEmpty)
                    _ModelPassportMetricTileGrid(
                      theme: theme,
                      tiles: primaryTiles,
                    ),
                  if (co2Tile != null) ...[
                    const SizedBox(height: 6),
                    _ModelPassportCo2Tile(theme: theme, metric: co2Tile),
                  ],
                  if (limitations.isNotEmpty) ...[
                    const SizedBox(height: 8),
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

class _ModelPassportMetricTileGrid extends StatelessWidget {
  const _ModelPassportMetricTileGrid({
    required this.theme,
    required this.tiles,
  });

  final ThemeData theme;
  final List<ModelPassportMetricDisplay> tiles;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 8.0;
        final tileWidth = (constraints.maxWidth - spacing) / 2;

        return Wrap(
          key: const ValueKey('listing_model_passport_metric_tiles'),
          spacing: spacing,
          runSpacing: spacing,
          children: tiles
              .map(
                (tile) => SizedBox(
                  width: tileWidth,
                  child: _ModelPassportStatTile(theme: theme, metric: tile),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _ModelPassportStatTile extends StatelessWidget {
  const _ModelPassportStatTile({required this.theme, required this.metric});

  final ThemeData theme;
  final ModelPassportMetricDisplay metric;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final isPrimary = metric.isPrimaryHighlight;
    final valueText = metric.unit == null
        ? metric.value
        : '${metric.value} ${metric.unit}';

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        gradient: isPrimary
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [
                        scheme.primary.withValues(alpha: 0.18),
                        scheme.surfaceContainerHigh.withValues(alpha: 0.42),
                      ]
                    : [
                        scheme.primaryContainer.withValues(alpha: 0.55),
                        scheme.surface.withValues(alpha: 0.95),
                      ],
              )
            : null,
        color: isPrimary
            ? null
            : (isDark
                  ? scheme.surfaceContainerHigh.withValues(alpha: 0.24)
                  : scheme.surfaceContainerHighest.withValues(alpha: 0.32)),
        boxShadow: isPrimary && !isDark
            ? [
                BoxShadow(
                  color: scheme.primary.withValues(alpha: 0.06),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ]
            : null,
      ),
      child: Padding(
        padding: EdgeInsets.fromLTRB(12, isPrimary ? 11 : 9, 12, isPrimary ? 11 : 9),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              metric.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelSmall?.copyWith(
                height: 1.2,
                fontWeight: isPrimary ? FontWeight.w600 : FontWeight.w500,
                color: scheme.onSurfaceVariant.withValues(
                  alpha: isDark ? 0.84 : (isPrimary ? 0.82 : 0.86),
                ),
              ),
            ),
            SizedBox(height: isPrimary ? 7 : 5),
            Text(
              valueText,
              style: (isPrimary
                      ? theme.textTheme.titleMedium
                      : theme.textTheme.titleSmall)
                  ?.copyWith(
                fontWeight: FontWeight.w700,
                letterSpacing: -0.25,
                height: 1.1,
                color: scheme.onSurface.withValues(alpha: isDark ? 0.96 : 1),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ModelPassportCo2Tile extends StatelessWidget {
  const _ModelPassportCo2Tile({required this.theme, required this.metric});

  final ThemeData theme;
  final ModelPassportMetricDisplay metric;

  @override
  Widget build(BuildContext context) {
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final valueText = '${metric.value} ${metric.unit}';

    return DecoratedBox(
      key: const ValueKey('listing_model_passport_co2_tile'),
      decoration: BoxDecoration(
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.2)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        child: Row(
          children: [
            Expanded(
              child: Text(
                metric.label,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: isDark ? 0.82 : 0.88,
                  ),
                ),
              ),
            ),
            Text(
              valueText,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withValues(alpha: isDark ? 0.92 : 0.9),
              ),
            ),
          ],
        ),
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
        borderRadius: BorderRadius.circular(10),
        color: isDark
            ? scheme.surfaceContainerHigh.withValues(alpha: 0.18)
            : scheme.surfaceContainerHighest.withValues(alpha: 0.14),
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
