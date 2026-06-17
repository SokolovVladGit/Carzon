import '../../../../l10n/app_localizations.dart';

import '../../domain/entities/listing_currency.dart';
import '../../domain/entities/listing_sort_option.dart';
import '../bloc/listings_state.dart';
import '../utils/listing_formatters.dart';
import '../widgets/filters/listings_filter_labels.dart';

/// Identifies which discovery dimension an active chip represents so the
/// feed can remove one filter without clearing the rest.
enum ListingsDiscoveryChipKind {
  search,
  make,
  model,
  year,
  priceRange,
  priceCurrency,
  maxMileage,
  city,
  region,
  bodyType,
  fuelType,
  transmissionType,
  listingType,
  sort,
}

/// Structured representation of a single active-discovery chip.
///
/// Used by the feed's active-filter strip so chips can render label
/// (`Марка`) and value (`Opel`) with separate typographic weight
/// instead of one flat `"Марка: Opel"` string. Chips whose meaning is
/// fully encoded in the value (e.g. "Sale", region name) carry only a
/// [value] and no [label].
class ListingsDiscoveryChip {
  const ListingsDiscoveryChip({
    required this.kind,
    required this.value,
    this.label,
  });

  final ListingsDiscoveryChipKind kind;
  final String? label;
  final String value;

  /// Flat "Label: Value" form, preserved for backwards-compatible
  /// callers and accessibility labels.
  String get flat => label == null ? value : '$label: $value';
}

/// Clears exactly one discovery dimension; other filters stay intact.
ListingsState listingsStateAfterDiscoveryChipRemoved(
  ListingsState state,
  ListingsDiscoveryChipKind kind,
) {
  return switch (kind) {
    ListingsDiscoveryChipKind.search => state.copyWith(clearSearch: true),
    ListingsDiscoveryChipKind.make => state.copyWith(clearMake: true),
    ListingsDiscoveryChipKind.model => state.copyWith(clearModel: true),
    ListingsDiscoveryChipKind.year => state.copyWith(
      clearMinYear: true,
      clearMaxYear: true,
    ),
    ListingsDiscoveryChipKind.priceRange => state.copyWith(
      clearMinPrice: true,
      clearMaxPrice: true,
    ),
    ListingsDiscoveryChipKind.priceCurrency => state.copyWith(
      clearPriceCurrencyFilter: true,
    ),
    ListingsDiscoveryChipKind.maxMileage => state.copyWith(
      clearMaxMileage: true,
    ),
    ListingsDiscoveryChipKind.city => state.copyWith(clearCity: true),
    ListingsDiscoveryChipKind.region => state.copyWith(
      regionFilter: MarketRegionFilter.both,
    ),
    ListingsDiscoveryChipKind.bodyType => state.copyWith(clearBodyType: true),
    ListingsDiscoveryChipKind.fuelType => state.copyWith(clearFuelType: true),
    ListingsDiscoveryChipKind.transmissionType => state.copyWith(
      clearTransmissionType: true,
    ),
    ListingsDiscoveryChipKind.listingType => state.copyWith(
      typeFilter: ListingTypeFilter.any,
    ),
    ListingsDiscoveryChipKind.sort => state.copyWith(clearSort: true),
  };
}

/// Structured chips for the feed's active-filter strip and for shared
/// filter-alert summaries.
///
/// Each chip is either a label/value pair (`Марка · Opel`) or just a
/// value (`Sale`, `Кишинёв` region marker). Cardinality matches
/// [listingsDiscoveryActiveFilterGroupCount] exactly.
List<ListingsDiscoveryChip> listingsDiscoveryChips(
  ListingsState s,
  AppLocalizations l10n,
) {
  final out = <ListingsDiscoveryChip>[];
  if (s.search != null && s.search!.trim().isNotEmpty) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.search,
        label: l10n.listingsSearchHint,
        value: s.search!.trim(),
      ),
    );
  }
  if (s.make != null && s.make!.trim().isNotEmpty) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.make,
        label: l10n.filterMake,
        value: s.make!.trim(),
      ),
    );
  }
  if (s.model != null && s.model!.trim().isNotEmpty) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.model,
        label: l10n.filterModel,
        value: s.model!.trim(),
      ),
    );
  }
  if (s.minYear != null && s.maxYear != null) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.year,
        label: l10n.listingFieldYear,
        value: '${s.minYear}–${s.maxYear}',
      ),
    );
  } else if (s.minYear != null) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.year,
        label: l10n.filterMinYear,
        value: '${s.minYear}',
      ),
    );
  } else if (s.maxYear != null) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.year,
        label: l10n.filterMaxYear,
        value: '${s.maxYear}',
      ),
    );
  }
  if (s.minPrice != null || s.maxPrice != null) {
    final a = s.minPrice?.toString() ?? '…';
    final b = s.maxPrice?.toString() ?? '…';
    final range = '$a–$b';
    switch (s.priceCurrencyFilter) {
      case ListingPriceCurrencyFilter.any:
        out.add(
          ListingsDiscoveryChip(
            kind: ListingsDiscoveryChipKind.priceRange,
            label: l10n.filterPriceChipPrefix,
            value: range,
          ),
        );
      case ListingPriceCurrencyFilter.usd:
        out.add(
          ListingsDiscoveryChip(
            kind: ListingsDiscoveryChipKind.priceRange,
            value: '\$ $range',
          ),
        );
      case ListingPriceCurrencyFilter.eur:
        out.add(
          ListingsDiscoveryChip(
            kind: ListingsDiscoveryChipKind.priceRange,
            value: '€ $range',
          ),
        );
    }
  } else {
    switch (s.priceCurrencyFilter) {
      case ListingPriceCurrencyFilter.any:
        break;
      case ListingPriceCurrencyFilter.usd:
        out.add(
          ListingsDiscoveryChip(
            kind: ListingsDiscoveryChipKind.priceCurrency,
            value: l10n.filterPriceCurrencyActiveUsd,
          ),
        );
      case ListingPriceCurrencyFilter.eur:
        out.add(
          ListingsDiscoveryChip(
            kind: ListingsDiscoveryChipKind.priceCurrency,
            value: l10n.filterPriceCurrencyActiveEur,
          ),
        );
    }
  }
  if (s.maxMileage != null) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.maxMileage,
        value: '≤ ${s.maxMileage} ${l10n.commonKilometersShort}',
      ),
    );
  }
  if (s.city != null && s.city!.trim().isNotEmpty) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.city,
        label: l10n.filterCity,
        value: s.city!.trim(),
      ),
    );
  }
  if (s.regionFilter == MarketRegionFilter.moldova) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.region,
        value: l10n.regionMoldova,
      ),
    );
  } else if (s.regionFilter == MarketRegionFilter.transnistria) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.region,
        value: l10n.regionTransnistria,
      ),
    );
  }
  if (s.bodyTypeFilter != null) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.bodyType,
        value: listingFilterBodyTypeLabel(l10n, s.bodyTypeFilter!),
      ),
    );
  }
  if (s.fuelTypeFilter != null) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.fuelType,
        label: l10n.listingFuelType,
        value: formatListingFuelType(l10n, s.fuelTypeFilter!),
      ),
    );
  }
  if (s.transmissionTypeFilter != null) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.transmissionType,
        label: l10n.listingTransmission,
        value: formatListingTransmissionType(l10n, s.transmissionTypeFilter!),
      ),
    );
  }
  if (s.typeFilter == ListingTypeFilter.sale) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.listingType,
        value: l10n.typeSale,
      ),
    );
  } else if (s.typeFilter == ListingTypeFilter.exchange) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.listingType,
        value: l10n.typeExchange,
      ),
    );
  }
  if (s.sortOption != ListingSortOption.newestFirst) {
    out.add(
      ListingsDiscoveryChip(
        kind: ListingsDiscoveryChipKind.sort,
        value: listingFilterSortOptionLabel(l10n, s.sortOption),
      ),
    );
  }
  return out;
}

/// Human-readable bullet labels for discovery chips — shared by feed strip and
/// filter-alert summaries (no duplicated localized copy).
///
/// Thin wrapper around [listingsDiscoveryChips] preserved for callers
/// that just need flat `"Label: Value"` strings (filter-alert summary,
/// semantics labels, etc.).
List<String> listingsDiscoveryChipLabels(
  ListingsState s,
  AppLocalizations l10n,
) => listingsDiscoveryChips(s, l10n).map((c) => c.flat).toList(growable: false);

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
      s.regionFilter == MarketRegionFilter.transnistria) {
    n++;
  }
  if (s.bodyTypeFilter != null) {
    n++;
  }
  if (s.fuelTypeFilter != null) {
    n++;
  }
  if (s.transmissionTypeFilter != null) {
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
