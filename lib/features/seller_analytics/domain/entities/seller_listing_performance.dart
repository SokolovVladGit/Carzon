import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

/// Per-listing engagement row from `get_my_seller_analytics_listings`.
class SellerListingPerformance extends Equatable {
  const SellerListingPerformance({
    required this.listingId,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.make,
    required this.model,
    required this.year,
    required this.periodViews,
    required this.currentFavorites,
    required this.periodInquiries,
    this.soldAt,
  });

  final String listingId;
  final String title;
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? soldAt;
  final String make;
  final String model;
  final int year;
  final int periodViews;
  final int currentFavorites;
  final int periodInquiries;

  /// Identity used in the private seller list: make/model/year, else title.
  String get displayTitle {
    final brand = make.trim();
    final name = model.trim();
    if (brand.isNotEmpty && name.isNotEmpty) {
      return year > 0 ? '$brand $name, $year' : '$brand $name';
    }
    final fallback = title.trim();
    if (fallback.isNotEmpty) return fallback;
    if (brand.isNotEmpty) {
      return year > 0 ? '$brand, $year' : brand;
    }
    if (name.isNotEmpty) {
      return year > 0 ? '$name, $year' : name;
    }
    return title;
  }

  /// Calendar days on market for an active listing.
  int? activeListingAgeDays(DateTime now) {
    if (status != ListingStatus.active) return null;
    return _calendarDaysBetween(createdAt, now);
  }

  /// Calendar days from publish to sale. Null when [soldAt] is missing.
  int? soldDurationDays() {
    final sold = soldAt;
    if (sold == null) return null;
    return _calendarDaysBetween(createdAt, sold);
  }

  static int _calendarDaysBetween(DateTime from, DateTime to) {
    final start = DateTime(from.year, from.month, from.day);
    final end = DateTime(to.year, to.month, to.day);
    final days = end.difference(start).inDays;
    return days < 0 ? 0 : days;
  }

  @override
  List<Object?> get props => [
    listingId,
    title,
    status,
    createdAt,
    soldAt,
    make,
    model,
    year,
    periodViews,
    currentFavorites,
    periodInquiries,
  ];
}
