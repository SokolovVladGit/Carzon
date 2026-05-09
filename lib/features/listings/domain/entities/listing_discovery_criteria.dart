import 'package:equatable/equatable.dart';

import '../repositories/listings_repository.dart';
import 'listing_currency.dart';
import 'listing.dart';
import 'listing_sort_option.dart';

/// User-facing discovery dimensions for the listings feed (no pagination).
///
/// Intentionally separate from [ListingsQuery] so the same field set can later
/// be serialized for local last-applied feed restore, filter alerts, deep-links —
/// without duplicating filter logic across features.
/// Notifications, persistence tables, and push are out of scope for now.
class ListingDiscoveryCriteria extends Equatable {
  const ListingDiscoveryCriteria({
    this.search,
    this.make,
    this.model,
    this.minYear,
    this.maxYear,
    this.minPrice,
    this.maxPrice,
    this.maxMileage,
    this.city,
    this.marketRegion,
    this.bodyType,
    this.typeIn,
    this.priceCurrencyFilter = ListingPriceCurrencyFilter.any,
    this.sort = ListingSortOption.newestFirst,
  });

  final String? search;
  final String? make;
  final String? model;
  final int? minYear;
  final int? maxYear;
  final num? minPrice;
  final num? maxPrice;
  final int? maxMileage;
  final String? city;
  final MarketRegion? marketRegion;
  final ListingBodyType? bodyType;
  final List<ListingType>? typeIn;

  /// When not [ListingPriceCurrencyFilter.any], restricts rows by
  /// `listings.price_currency` (`eur` | `usd`).
  final ListingPriceCurrencyFilter priceCurrencyFilter;
  final ListingSortOption sort;

  /// Whether any dimension differs from an "unfiltered" feed besides region
  /// (region is a first-class picker on the home shell).
  bool hasNonRegionConstraints({
    ListingSortOption defaultSort = ListingSortOption.newestFirst,
  }) {
    final tSearch = search?.trim();
    final tMake = make?.trim();
    final tModel = model?.trim();
    final tCity = city?.trim();
    return (tSearch != null && tSearch.isNotEmpty) ||
        (tMake != null && tMake.isNotEmpty) ||
        (tModel != null && tModel.isNotEmpty) ||
        minYear != null ||
        maxYear != null ||
        minPrice != null ||
        maxPrice != null ||
        maxMileage != null ||
        (tCity != null && tCity.isNotEmpty) ||
        bodyType != null ||
        (typeIn != null && typeIn!.isNotEmpty) ||
        sort != defaultSort ||
        priceCurrencyFilter != ListingPriceCurrencyFilter.any;
  }

  ListingsQuery toListingsQuery({
    required int page,
    required int pageSize,
    required ListingStatus? status,
  }) {
    return ListingsQuery(
      search: _nullIfBlank(search),
      make: _nullIfBlank(make),
      model: _nullIfBlank(model),
      minYear: minYear,
      maxYear: maxYear,
      minPrice: minPrice,
      maxPrice: maxPrice,
      maxMileage: maxMileage,
      city: _nullIfBlank(city),
      marketRegion: marketRegion,
      bodyType: bodyType,
      status: status,
      typeIn: typeIn,
      priceCurrency: priceCurrencyFilter.asListingCurrencyOrNull,
      sort: sort,
      page: page,
      pageSize: pageSize,
    );
  }

  static String? _nullIfBlank(String? raw) {
    if (raw == null) return null;
    final t = raw.trim();
    return t.isEmpty ? null : t;
  }

  @override
  List<Object?> get props => [
    search,
    make,
    model,
    minYear,
    maxYear,
    minPrice,
    maxPrice,
    maxMileage,
    city,
    marketRegion,
    bodyType,
    typeIn,
    priceCurrencyFilter,
    sort,
  ];
}
