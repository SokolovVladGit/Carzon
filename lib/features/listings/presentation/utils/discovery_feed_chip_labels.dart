import '../../../../l10n/app_localizations.dart';

import '../../domain/entities/listing_currency.dart';
import '../../domain/entities/listing_sort_option.dart';
import '../bloc/listings_state.dart';
import '../widgets/filters/listings_filter_labels.dart';

/// Human-readable bullet labels for discovery chips — shared by feed strip and
/// filter-alert summaries (no duplicated localized copy).
List<String> listingsDiscoveryChipLabels(
  ListingsState s,
  AppLocalizations l10n,
) {
  final out = <String>[];
  if (s.search != null && s.search!.trim().isNotEmpty) {
    out.add('${l10n.listingsSearchHint}: ${s.search!.trim()}');
  }
  if (s.make != null && s.make!.trim().isNotEmpty) {
    out.add('${l10n.filterMake}: ${s.make!.trim()}');
  }
  if (s.model != null && s.model!.trim().isNotEmpty) {
    out.add('${l10n.filterModel}: ${s.model!.trim()}');
  }
  if (s.minYear != null && s.maxYear != null) {
    out.add('${l10n.listingFieldYear}: ${s.minYear}–${s.maxYear}');
  } else if (s.minYear != null) {
    out.add('${l10n.filterMinYear}: ${s.minYear}');
  } else if (s.maxYear != null) {
    out.add('${l10n.filterMaxYear}: ${s.maxYear}');
  }
  if (s.minPrice != null || s.maxPrice != null) {
    final a = s.minPrice?.toString() ?? '…';
    final b = s.maxPrice?.toString() ?? '…';
    final range = '$a–$b';
    switch (s.priceCurrencyFilter) {
      case ListingPriceCurrencyFilter.any:
        out.add('${l10n.filterPriceChipPrefix}: $range');
      case ListingPriceCurrencyFilter.usd:
        out.add('\$ $range');
      case ListingPriceCurrencyFilter.eur:
        out.add('€ $range');
    }
  } else {
    switch (s.priceCurrencyFilter) {
      case ListingPriceCurrencyFilter.any:
        break;
      case ListingPriceCurrencyFilter.usd:
        out.add(l10n.filterPriceCurrencyActiveUsd);
      case ListingPriceCurrencyFilter.eur:
        out.add(l10n.filterPriceCurrencyActiveEur);
    }
  }
  if (s.maxMileage != null) {
    out.add('≤ ${s.maxMileage} ${l10n.commonKilometersShort}');
  }
  if (s.city != null && s.city!.trim().isNotEmpty) {
    out.add('${l10n.filterCity}: ${s.city!.trim()}');
  }
  if (s.regionFilter == MarketRegionFilter.moldova) {
    out.add(l10n.regionMoldova);
  } else if (s.regionFilter == MarketRegionFilter.both) {
    out.add(l10n.regionBoth);
  }
  if (s.bodyTypeFilter != null) {
    out.add(listingFilterBodyTypeLabel(l10n, s.bodyTypeFilter!));
  }
  if (s.typeFilter == ListingTypeFilter.sale) {
    out.add(l10n.typeSale);
  } else if (s.typeFilter == ListingTypeFilter.exchange) {
    out.add(l10n.typeExchange);
  }
  if (s.sortOption != ListingSortOption.newestFirst) {
    out.add(listingFilterSortOptionLabel(l10n, s.sortOption));
  }
  return out;
}

/// Count of active discovery dimensions shown as chips in the feed —
/// cardinality must stay aligned with [listingsDiscoveryChipLabels].
int listingsDiscoveryActiveFilterGroupCount(ListingsState s) {
  var n = 0;
  if (s.search != null && s.search!.trim().isNotEmpty) {
    n++;
  }
  if (s.make != null && s.make!.trim().isNotEmpty) {
    n++;
  }
  if (s.model != null && s.model!.trim().isNotEmpty) {
    n++;
  }
  if (s.minYear != null || s.maxYear != null) {
    n++;
  }
  if (s.minPrice != null || s.maxPrice != null) {
    n++;
  } else {
    switch (s.priceCurrencyFilter) {
      case ListingPriceCurrencyFilter.any:
        break;
      case ListingPriceCurrencyFilter.usd:
      case ListingPriceCurrencyFilter.eur:
        n++;
    }
  }
  if (s.maxMileage != null) {
    n++;
  }
  if (s.city != null && s.city!.trim().isNotEmpty) {
    n++;
  }
  if (s.regionFilter == MarketRegionFilter.moldova ||
      s.regionFilter == MarketRegionFilter.both) {
    n++;
  }
  if (s.bodyTypeFilter != null) {
    n++;
  }
  if (s.typeFilter == ListingTypeFilter.sale ||
      s.typeFilter == ListingTypeFilter.exchange) {
    n++;
  }
  if (s.sortOption != ListingSortOption.newestFirst) {
    n++;
  }
  return n;
}
