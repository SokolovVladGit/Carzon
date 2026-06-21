import 'package:flutter/foundation.dart';

import '../../../domain/entities/listing.dart';
import '../../../domain/entities/listing_currency.dart';
import '../../../domain/entities/listing_sort_option.dart';
import '../../bloc/listings_state.dart';

/// Initial values for [ListingsFilterForm]. Maps from feed [ListingsState]
/// or can be built for future saved-filter flows from stored criteria.
@immutable
class ListingsFilterFormSeed {
  const ListingsFilterFormSeed({
    required this.make,
    required this.model,
    required this.minYear,
    required this.maxYear,
    required this.minPrice,
    required this.maxPrice,
    required this.maxMileage,
    required this.city,
    required this.typeFilter,
    required this.region,
    required this.sort,
    required this.bodyType,
    required this.fuelType,
    required this.transmissionType,
    required this.drivetrain,
    required this.priceCurrencyFilter,
  });

  factory ListingsFilterFormSeed.fromListingsState(ListingsState state) {
    return ListingsFilterFormSeed(
      make: state.make,
      model: state.model,
      minYear: state.minYear,
      maxYear: state.maxYear,
      minPrice: state.minPrice,
      maxPrice: state.maxPrice,
      maxMileage: state.maxMileage,
      city: state.city,
      typeFilter: state.typeFilter,
      region: state.regionFilter,
      sort: state.sortOption,
      bodyType: state.bodyTypeFilter,
      fuelType: state.fuelTypeFilter,
      transmissionType: state.transmissionTypeFilter,
      drivetrain: state.drivetrainFilter,
      priceCurrencyFilter: state.priceCurrencyFilter,
    );
  }

  final String? make;
  final String? model;
  final int? minYear;
  final int? maxYear;
  final num? minPrice;
  final num? maxPrice;
  final int? maxMileage;
  final String? city;
  final ListingTypeFilter typeFilter;
  final MarketRegionFilter region;
  final ListingSortOption sort;
  final ListingBodyType? bodyType;
  final ListingFuelType? fuelType;
  final ListingTransmissionType? transmissionType;
  final ListingDrivetrain? drivetrain;
  final ListingPriceCurrencyFilter priceCurrencyFilter;
}
