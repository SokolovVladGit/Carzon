import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';

import 'package:carzon/l10n/app_localizations.dart';

import '../../../domain/entities/listing_currency.dart';
import '../../../domain/entities/listing_sort_option.dart';
import '../../bloc/listings_state.dart';
import 'listings_filter_form_seed.dart';
import 'listings_filter_labels.dart';
import '../../utils/listing_formatters.dart';

/// Presentation output for the filter summary strip (browse filter sheet).
@immutable
class ListingsFilterSummaryView {
  const ListingsFilterSummaryView._({
    required this.useDefaultLayout,
    required this.activeLine,
  });

  /// Premium default title + hints when the draft matches vanilla discovery.
  factory ListingsFilterSummaryView.defaults() {
    return const ListingsFilterSummaryView._(
      useDefaultLayout: true,
      activeLine: null,
    );
  }

  /// Single concise line summarizing non-default draft criteria.
  factory ListingsFilterSummaryView.active(String line) {
    return ListingsFilterSummaryView._(
      useDefaultLayout: false,
      activeLine: line,
    );
  }

  final bool useDefaultLayout;
  final String? activeLine;
}

/// Whether [draft] is the “empty configurator” baseline (no meaningful constraints).
bool isListingsFilterDraftVanilla(ListingsFilterFormSeed draft) {
  final make = draft.make?.trim();
  final model = draft.model?.trim();
  final city = draft.city?.trim();
  return (make == null || make.isEmpty) &&
      (model == null || model.isEmpty) &&
      draft.minYear == null &&
      draft.maxYear == null &&
      draft.minPrice == null &&
      draft.maxPrice == null &&
      draft.maxMileage == null &&
      (city == null || city.isEmpty) &&
      draft.region == MarketRegionFilter.both &&
      draft.typeFilter == ListingTypeFilter.any &&
      draft.bodyType == null &&
      draft.fuelType == null &&
      draft.transmissionType == null &&
      draft.drivetrain == null &&
      draft.priceCurrencyFilter == ListingPriceCurrencyFilter.any &&
      draft.sort == ListingSortOption.newestFirst;
}

String _formatAmount(AppLocalizations l10n, num n) {
  return NumberFormat.decimalPattern(l10n.localeName).format(n);
}

String? _makeModelPart(String? make, String? model) {
  final m = make?.trim();
  final o = model?.trim();
  if ((m == null || m.isEmpty) && (o == null || o.isEmpty)) return null;
  if (m != null && m.isNotEmpty && o != null && o.isNotEmpty) {
    return '$m $o';
  }
  if (m != null && m.isNotEmpty) return m;
  return o;
}

String? _pricePart(AppLocalizations l10n, ListingsFilterFormSeed d) {
  final hasMin = d.minPrice != null;
  final hasMax = d.maxPrice != null;
  if (!hasMin && !hasMax) return null;

  String sym(ListingPriceCurrencyFilter c) {
    switch (c) {
      case ListingPriceCurrencyFilter.any:
        return '';
      case ListingPriceCurrencyFilter.usd:
        return r'$';
      case ListingPriceCurrencyFilter.eur:
        return '€';
    }
  }

  final s = sym(d.priceCurrencyFilter);
  if (hasMin && hasMax) {
    final a = _formatAmount(l10n, d.minPrice!);
    final b = _formatAmount(l10n, d.maxPrice!);
    if (d.priceCurrencyFilter == ListingPriceCurrencyFilter.any) {
      return l10n.filterSummaryPriceRangePlain(a, b);
    }
    return l10n.filterSummaryPriceRangeWithSymbol(s, a, b);
  }
  if (hasMax) {
    final amt = '$s${_formatAmount(l10n, d.maxPrice!)}';
    return l10n.filterSummaryPriceUpTo(amt);
  }
  final amt = '$s${_formatAmount(l10n, d.minPrice!)}';
  return l10n.filterSummaryPriceFrom(amt);
}

/// Builds a reusable summary line for the filter draft preview.
ListingsFilterSummaryView buildListingsFilterSummaryView(
  AppLocalizations l10n,
  ListingsFilterFormSeed draft,
) {
  if (isListingsFilterDraftVanilla(draft)) {
    return ListingsFilterSummaryView.defaults();
  }

  final parts = <String>[];

  final mm = _makeModelPart(draft.make, draft.model);
  if (mm != null) parts.add(mm);

  final price = _pricePart(l10n, draft);
  if (price != null) parts.add(price);

  if (draft.minYear != null || draft.maxYear != null) {
    final y1 = draft.minYear?.toString() ?? '…';
    final y2 = draft.maxYear?.toString() ?? '…';
    parts.add('$y1–$y2');
  }

  if (draft.maxMileage != null) {
    parts.add(
      l10n.filterSummaryMileageUpTo(_formatAmount(l10n, draft.maxMileage!)),
    );
  }

  final city = draft.city?.trim();
  if (city != null && city.isNotEmpty) {
    parts.add(city);
  }

  switch (draft.region) {
    case MarketRegionFilter.moldova:
      parts.add(l10n.regionMoldova);
    case MarketRegionFilter.transnistria:
      parts.add(l10n.regionTransnistria);
    case MarketRegionFilter.both:
      break;
  }

  if (draft.bodyType != null) {
    parts.add(listingFilterBodyTypeLabel(l10n, draft.bodyType!));
  }

  if (draft.fuelType != null) {
    parts.add(formatListingFuelType(l10n, draft.fuelType!));
  }

  if (draft.transmissionType != null) {
    parts.add(formatListingTransmissionType(l10n, draft.transmissionType!));
  }

  if (draft.drivetrain != null) {
    parts.add(formatListingDrivetrain(l10n, draft.drivetrain!));
  }

  switch (draft.typeFilter) {
    case ListingTypeFilter.any:
      break;
    case ListingTypeFilter.sale:
      parts.add(l10n.typeSale);
    case ListingTypeFilter.exchange:
      parts.add(l10n.typeExchange);
  }

  if (draft.sort != ListingSortOption.newestFirst) {
    parts.add(listingFilterSortOptionLabel(l10n, draft.sort));
  }

  if (parts.isEmpty) {
    return ListingsFilterSummaryView.active(
      l10n.filterSummaryAllListingsInRegionPm,
    );
  }

  return ListingsFilterSummaryView.active(parts.join(' · '));
}
