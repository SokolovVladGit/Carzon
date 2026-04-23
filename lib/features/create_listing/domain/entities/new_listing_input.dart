import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

/// Pure-Dart value object describing the data required to create a new
/// listing. No knowledge of Supabase or any data layer.
class NewListingInput extends Equatable {
  const NewListingInput({
    required this.sellerId,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.priceEur,
    required this.mileageKm,
    required this.type,
    required this.city,
  });

  final String sellerId;
  final String title;
  final String make;
  final String model;
  final int year;
  final num priceEur;
  final int mileageKm;
  final ListingType type;
  final String city;

  @override
  List<Object?> get props => [
        sellerId,
        title,
        make,
        model,
        year,
        priceEur,
        mileageKm,
        type,
        city,
      ];
}
