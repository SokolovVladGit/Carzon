import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../listings/presentation/widgets/official_data_editorial.dart';
import '../../domain/entities/fuel_price_snapshot.dart';
import '../utils/fuel_price_formatters.dart';

/// Editorial fuel price board with integrated source metadata and scope note.
class FuelPricesBoard extends StatelessWidget {
  const FuelPricesBoard({
    super.key,
    required this.snapshot,
  });

  final FuelPriceSnapshot snapshot;

  static const Key sourceBadgeKey = ValueKey<String>('fuel_prices_source_badge');
  static const Key dateLabelKey = ValueKey<String>('fuel_prices_date_label');
  static const Key scopeNoteKey = ValueKey<String>('fuel_prices_scope_note');
  static const Key staleNoticeKey = ValueKey<String>('fuel_prices_stale_notice');

  static const double _radius = 22;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final unitLabel = fuelPriceUnitLabel(l10n, snapshot.currency);
    final scopeNote = fuelPriceScopeNote(l10n, snapshot.territory);
    final dateLabel = fuelPriceDateLabel(
      l10n: l10n,
      effectiveDate: snapshot.effectiveDate,
      fetchedAt: snapshot.fetchedAt,
    );

    final sideBorder = BorderSide(
      color: scheme.outlineVariant.withValues(alpha: isDark ? 0.18 : 0.16),
    );

    return Transform.translate(
      offset: const Offset(0, -0.5),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(_radius),
            bottomRight: Radius.circular(_radius),
          ),
          border: Border(
            left: sideBorder,
            right: sideBorder,
            bottom: sideBorder,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshot.sourceLabel.isNotEmpty)
                OfficialDataSourceHeader(
                  theme: theme,
                  sourceLabel: snapshot.sourceLabel,
                  sourceKey: sourceBadgeKey,
                  updatedDateLabel: dateLabel,
                  updatedDateKey: dateLabel != null ? dateLabelKey : null,
                ),
              if (snapshot.sourceLabel.isNotEmpty) const SizedBox(height: 18),
              for (var i = 0; i < snapshot.items.length; i++) ...[
                if (i > 0)
                  Divider(
                    height: 18,
                    thickness: 0.5,
                    color: scheme.outlineVariant.withValues(
                      alpha: isDark ? 0.14 : 0.2,
                    ),
                  ),
                _FuelPriceBoardRow(
                  label: fuelPriceFuelLabel(l10n, snapshot.items[i].fuelCode),
                  price: snapshot.items[i].price,
                  unitLabel: unitLabel,
                ),
              ],
              if (scopeNote.isNotEmpty) ...[
                const SizedBox(height: 16),
                OfficialDataPendingFootnote(
                  theme: theme,
                  text: scopeNote,
                  textKey: scopeNoteKey,
                ),
              ],
              if (snapshot.isStale) ...[
                const SizedBox(height: 10),
                OfficialDataPendingFootnote(
                  theme: theme,
                  text: l10n.fuelPricesStaleNotice,
                  textKey: staleNoticeKey,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _FuelPriceBoardRow extends StatelessWidget {
  const _FuelPriceBoardRow({
    required this.label,
    required this.price,
    required this.unitLabel,
  });

  final String label;
  final double price;
  final String unitLabel;

  static const double _priceColumnWidth = 108;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final amount = formatFuelPriceAmount(price);
    final parts = amount.split('.');
    final whole = parts.first;
    final fraction = parts.length > 1 ? parts.last : null;
    final accent = AppTheme.editorialAccentColor(scheme);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: -0.15,
              height: 1.25,
              color: scheme.onSurface.withValues(alpha: isDark ? 0.96 : 1),
            ),
          ),
        ),
        const SizedBox(width: 10),
        SizedBox(
          width: _priceColumnWidth,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    whole,
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: accent,
                    ),
                  ),
                  if (fraction != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Text(
                        '.$fraction',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                          height: 1,
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: accent,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                unitLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.02,
                  color: scheme.onSurfaceVariant.withValues(
                    alpha: isDark ? 0.76 : 0.82,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
