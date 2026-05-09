import '../../../domain/entities/listing.dart';
import '../../../domain/entities/listing_currency.dart';
import '../../../domain/entities/listing_sort_option.dart';
import '../../bloc/listings_state.dart';

/// Payload returned when the user applies discovery filters from the sheet.
///
/// [cleared]: full-feed reset semantics (browse), or empty-alert criteria mapped
/// in [listingDiscoveryCriteriaFromFilterApply].
class ListingsFilterApplyResult {
  const ListingsFilterApplyResult.apply({
    required this.make,
    required this.model,
    required this.minYear,
    required this.maxYear,
    required this.minPrice,
    required this.maxPrice,
    required this.maxMileage,
    required this.city,
    required this.typeFilter,
    required this.sort,
    required this.region,
    required this.bodyType,
    required this.priceCurrencyFilter,
  }) : cleared = false;

  const ListingsFilterApplyResult.clear()
    : cleared = true,
      make = null,
      model = null,
      minYear = null,
      maxYear = null,
      minPrice = null,
      maxPrice = null,
      maxMileage = null,
      city = null,
      typeFilter = ListingTypeFilter.any,
      sort = ListingSortOption.newestFirst,
      region = null,
      bodyType = null,
      priceCurrencyFilter = ListingPriceCurrencyFilter.any;

  final bool cleared;
  final String? make;
  final String? model;
  final int? minYear;
  final int? maxYear;
  final num? minPrice;
  final num? maxPrice;
  final int? maxMileage;
  final String? city;
  final ListingTypeFilter typeFilter;
  final ListingSortOption sort;
  final MarketRegionFilter? region;
  final ListingBodyType? bodyType;
  final ListingPriceCurrencyFilter priceCurrencyFilter;
}
