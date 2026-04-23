import 'package:equatable/equatable.dart';

enum ListingType { sale, exchange, both }

enum ListingStatus { active, hidden, sold, archived }

class Listing extends Equatable {
  const Listing({
    required this.id,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.priceEur,
    required this.mileageKm,
    required this.type,
    required this.city,
    required this.createdAt,
    this.status = ListingStatus.active,
    this.coverImageUrl,
    this.sellerId,
  });

  final String id;
  final String title;
  final String make;
  final String model;
  final int year;
  final num priceEur;
  final int mileageKm;
  final ListingType type;
  final String city;
  final DateTime createdAt;
  final ListingStatus status;
  final String? coverImageUrl;
  final String? sellerId;

  @override
  List<Object?> get props => [
        id,
        title,
        make,
        model,
        year,
        priceEur,
        mileageKm,
        type,
        city,
        createdAt,
        status,
        coverImageUrl,
        sellerId,
      ];
}
