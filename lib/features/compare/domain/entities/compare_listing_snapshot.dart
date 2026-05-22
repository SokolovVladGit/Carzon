import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';

/// Minimal listing fields persisted for compare tray and screen chrome.
///
/// Full [Listing] resolution happens on later compare-screen stages.
class CompareListingSnapshot extends Equatable {
  const CompareListingSnapshot({
    required this.listingId,
    required this.addedAt,
    this.coverImageUrl,
    this.make,
    this.model,
    this.year,
    this.priceEur,
    this.priceCurrency = ListingCurrency.eur,
    this.city,
    this.marketRegionRaw,
  });

  final String listingId;
  final DateTime addedAt;
  final String? coverImageUrl;
  final String? make;
  final String? model;
  final int? year;
  final num? priceEur;
  final ListingCurrency priceCurrency;
  final String? city;

  /// Wire value for [MarketRegion] (`moldova` | `transnistria`), nullable.
  final String? marketRegionRaw;

  /// Builds a snapshot from a feed/details [Listing] (e.g. future add actions).
  factory CompareListingSnapshot.fromListing(Listing listing) {
    return CompareListingSnapshot(
      listingId: listing.id,
      addedAt: DateTime.now().toUtc(),
      coverImageUrl: listing.coverImageUrl,
      make: listing.make,
      model: listing.model,
      year: listing.year,
      priceEur: listing.priceEur,
      priceCurrency: listing.priceCurrency,
      city: listing.city,
      marketRegionRaw: listing.marketRegion.name,
    );
  }

  @override
  List<Object?> get props => [
    listingId,
    addedAt,
    coverImageUrl,
    make,
    model,
    year,
    priceEur,
    priceCurrency,
    city,
    marketRegionRaw,
  ];
}
