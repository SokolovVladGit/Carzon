import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations_x.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/domain/entities/listing_discovery_criteria.dart';
import '../../../listings/presentation/utils/listing_formatters.dart';

/// Read-only summary of a saved filter-alert criteria row.
///
/// Renders one label/value row per active dimension. Empty / default
/// dimensions are skipped so the "no constraints" baseline collapses
/// to nothing (the parent page renders an empty state in that case).
///
/// Sort is intentionally **not** rendered: filter-alert SQL matching does
/// not read [ListingDiscoveryCriteria.sort], so showing it would imply a
/// constraint that the server never applies.
class FilterAlertCriteriaSummary extends StatelessWidget {
  const FilterAlertCriteriaSummary({super.key, required this.criteria});

  final ListingDiscoveryCriteria criteria;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final rows = _buildRows(l10n);

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    final scheme = theme.colorScheme;
    return Container(
      key: const ValueKey<String>(
        'filter_alert_management_summary_card',
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.filterAlertManagementCriteriaSectionTitle,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 10),
          for (final row in rows) ...[
            _SummaryRow(label: row.$1, value: row.$2),
            if (row != rows.last) const SizedBox(height: 6),
          ],
        ],
      ),
    );
  }

  List<(String, String)> _buildRows(AppLocalizations l10n) {
    final rows = <(String, String)>[];

    final search = criteria.search?.trim();
    if (search != null && search.isNotEmpty) {
      rows.add((l10n.filterAlertSummarySearchLabel, search));
    }

    final make = criteria.make?.trim();
    if (make != null && make.isNotEmpty) {
      rows.add((l10n.filterMake, make));
    }

    final model = criteria.model?.trim();
    if (model != null && model.isNotEmpty) {
      rows.add((l10n.filterModel, model));
    }

    final yearRange = _formatYearRange(criteria.minYear, criteria.maxYear);
    if (yearRange != null) {
      rows.add((l10n.filterYearManufactureSection, yearRange));
    }

    final price = _formatPriceRange(l10n, criteria);
    if (price != null) {
      rows.add((l10n.filterPriceChipPrefix, price));
    }

    final mileage = criteria.maxMileage;
    if (mileage != null) {
      rows.add((
        l10n.filterAlertSummaryMileageLabel,
        l10n.filterSummaryMileageUpTo(_thousands(mileage.toString())),
      ));
    }

    final city = criteria.city?.trim();
    if (city != null && city.isNotEmpty) {
      rows.add((l10n.filterCity, city));
    }

    final region = criteria.marketRegion;
    if (region != null) {
      rows.add((l10n.listingFieldRegion, formatMarketRegion(l10n, region)));
    }

    final bodyType = criteria.bodyType;
    if (bodyType != null) {
      rows.add((l10n.listingFieldBodyType, formatListingBodyType(l10n, bodyType)));
    }

    final typeLabel = _formatListingTypeIn(l10n, criteria.typeIn);
    if (typeLabel != null) {
      rows.add((l10n.filterType, typeLabel));
    }

    final currency = criteria.priceCurrencyFilter;
    if (currency != ListingPriceCurrencyFilter.any) {
      rows.add((l10n.filterPriceCurrencyLabel, _currencyLabel(l10n, currency)));
    }

    return rows;
  }

  String? _formatYearRange(int? minYear, int? maxYear) {
    if (minYear == null && maxYear == null) return null;
    if (minYear != null && maxYear != null) {
      return '$minYear–$maxYear';
    }
    if (minYear != null) return '$minYear+';
    return '–$maxYear';
  }

  String? _formatPriceRange(
    AppLocalizations l10n,
    ListingDiscoveryCriteria c,
  ) {
    final hasMin = c.minPrice != null;
    final hasMax = c.maxPrice != null;
    if (!hasMin && !hasMax) return null;
    final symbol = switch (c.priceCurrencyFilter) {
      ListingPriceCurrencyFilter.eur => '€',
      ListingPriceCurrencyFilter.usd => '\$',
      ListingPriceCurrencyFilter.any => '',
    };
    final minStr = hasMin ? _formatPriceAmount(c.minPrice!) : null;
    final maxStr = hasMax ? _formatPriceAmount(c.maxPrice!) : null;
    if (hasMin && hasMax) {
      if (symbol.isEmpty) {
        return l10n.filterSummaryPriceRangePlain(minStr!, maxStr!);
      }
      return l10n.filterSummaryPriceRangeWithSymbol(symbol, minStr!, maxStr!);
    }
    if (hasMin) {
      return l10n.filterSummaryPriceFrom('$symbol$minStr');
    }
    return l10n.filterSummaryPriceUpTo('$symbol$maxStr');
  }

  String _formatPriceAmount(num value) {
    if (value == value.truncate()) {
      return _thousands(value.toInt().toString());
    }
    return value.toStringAsFixed(2);
  }

  String? _formatListingTypeIn(
    AppLocalizations l10n,
    List<ListingType>? typeIn,
  ) {
    if (typeIn == null || typeIn.isEmpty) return null;
    final set = typeIn.toSet();
    final saleSemantics = <ListingType>{ListingType.sale, ListingType.both};
    final exchangeSemantics = <ListingType>{
      ListingType.exchange,
      ListingType.both,
    };
    if (set.length == saleSemantics.length &&
        set.containsAll(saleSemantics)) {
      return l10n.typeSale;
    }
    if (set.length == exchangeSemantics.length &&
        set.containsAll(exchangeSemantics)) {
      return l10n.typeExchange;
    }
    return null;
  }

  String _currencyLabel(
    AppLocalizations l10n,
    ListingPriceCurrencyFilter filter,
  ) {
    switch (filter) {
      case ListingPriceCurrencyFilter.eur:
        return l10n.filterPriceCurrencyEur;
      case ListingPriceCurrencyFilter.usd:
        return l10n.filterPriceCurrencyUsd;
      case ListingPriceCurrencyFilter.any:
        return l10n.filterPriceCurrencyAny;
    }
  }

  static String _thousands(String digits) {
    final buf = StringBuffer();
    final n = digits.length;
    for (var i = 0; i < n; i++) {
      if (i > 0 && (n - i) % 3 == 0) buf.write(' ');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 116,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant.withValues(alpha: 0.85),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
