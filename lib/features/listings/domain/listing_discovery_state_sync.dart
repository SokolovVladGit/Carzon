import 'entities/listing.dart';
import 'entities/listing_discovery_criteria.dart';

import '../presentation/bloc/listings_state.dart';

/// Default feed semantics: Приднестровье + no extra discovery dimensions.
bool isDefaultListingsDiscoveryState(ListingsState s) =>
    !s.hasActiveDiscoveryConstraints;

/// Full [ListingsState] snapshot reconstructed from persisted criteria (pre-load).
ListingsState listingsStateFromDiscoveryCriteria(ListingDiscoveryCriteria c) {
  return ListingsState(
    search: _blankToNull(c.search),
    make: _blankToNull(c.make),
    model: _blankToNull(c.model),
    minYear: c.minYear,
    maxYear: c.maxYear,
    minPrice: c.minPrice,
    maxPrice: c.maxPrice,
    maxMileage: c.maxMileage,
    city: _blankToNull(c.city),
    typeFilter: listingTypeFilterFromTypeIn(c.typeIn),
    regionFilter: marketRegionFilterFromNullable(c.marketRegion),
    bodyTypeFilter: c.bodyType,
    sortOption: c.sort,
    priceCurrencyFilter: c.priceCurrencyFilter,
  );
}

ListingDiscoveryCriteria listingDiscoveryCriteriaFromListingsState(
  ListingsState s,
) {
  return ListingDiscoveryCriteria(
    search: s.search,
    make: s.make,
    model: s.model,
    minYear: s.minYear,
    maxYear: s.maxYear,
    minPrice: s.minPrice,
    maxPrice: s.maxPrice,
    maxMileage: s.maxMileage,
    city: s.city,
    marketRegion: s.regionFilter.asMarketRegion,
    bodyType: s.bodyTypeFilter,
    typeIn: s.typeFilter.asListingTypes,
    sort: s.sortOption,
    priceCurrencyFilter: s.priceCurrencyFilter,
  );
}

String? _blankToNull(String? raw) {
  if (raw == null) return null;
  final t = raw.trim();
  return t.isEmpty ? null : t;
}

ListingTypeFilter listingTypeFilterFromTypeIn(List<ListingType>? typeIn) {
  if (typeIn == null || typeIn.isEmpty) return ListingTypeFilter.any;

  final saved = typeIn.toSet();
  final saleSemantics = ListingTypeFilter.sale.asListingTypes!.toSet();
  final exchSemantics = ListingTypeFilter.exchange.asListingTypes!.toSet();

  if (saved.length == saleSemantics.length && saved.containsAll(saleSemantics)) {
    return ListingTypeFilter.sale;
  }
  if (saved.length == exchSemantics.length && saved.containsAll(exchSemantics)) {
    return ListingTypeFilter.exchange;
  }

  if (saved.containsAll(saleSemantics) && saved.every(saleSemantics.contains)) {
    return ListingTypeFilter.sale;
  }
  if (saved.containsAll(exchSemantics) &&
      saved.every(exchSemantics.contains)) {
    return ListingTypeFilter.exchange;
  }

  if (saved.length == 1 && saved.contains(ListingType.both)) {
    return ListingTypeFilter.any;
  }

  return ListingTypeFilter.any;
}

MarketRegionFilter marketRegionFilterFromNullable(MarketRegion? region) {
  switch (region) {
    case MarketRegion.transnistria:
      return MarketRegionFilter.transnistria;
    case MarketRegion.moldova:
      return MarketRegionFilter.moldova;
    case null:
      return MarketRegionFilter.both;
  }
}
