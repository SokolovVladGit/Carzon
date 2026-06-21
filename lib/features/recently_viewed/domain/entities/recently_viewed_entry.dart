import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';
import '../../../listings/domain/entities/listing_currency.dart';
import '../../../listings/presentation/utils/listing_details_header_titles.dart';

/// Lightweight listing snapshot stored in local recently-viewed history.
class RecentlyViewedEntry extends Equatable {
  const RecentlyViewedEntry({
    required this.listingId,
    required this.viewedAt,
    required this.title,
    required this.make,
    required this.model,
    required this.year,
    required this.priceEur,
    this.priceCurrency = ListingCurrency.eur,
    required this.city,
    required this.marketRegion,
    this.coverImageUrl,
  });

  final String listingId;
  final DateTime viewedAt;
  final String title;
  final String make;
  final String model;
  final int year;
  final num priceEur;
  final ListingCurrency priceCurrency;
  final String city;
  final MarketRegion marketRegion;
  final String? coverImageUrl;

  /// Builds an entry from a successfully loaded listing details payload.
  factory RecentlyViewedEntry.fromListing(
    Listing listing, {
    String? heroImageUrl,
    DateTime? viewedAt,
  }) {
    final rawTitle = listing.title.trim();
    final title = rawTitle.isNotEmpty
        ? rawTitle
        : listingDetailsVehicleIdentityLine(listing.make, listing.model);

    final hero = heroImageUrl?.trim();
    final cover = listing.coverImageUrl?.trim();
    final resolvedCover = (hero != null && hero.isNotEmpty)
        ? hero
        : (cover != null && cover.isNotEmpty ? cover : null);

    return RecentlyViewedEntry(
      listingId: listing.id,
      viewedAt: (viewedAt ?? DateTime.now()).toUtc(),
      title: title,
      make: listing.make,
      model: listing.model,
      year: listing.year,
      priceEur: listing.priceEur,
      priceCurrency: listing.priceCurrency,
      city: listing.city,
      marketRegion: listing.marketRegion,
      coverImageUrl: resolvedCover,
    );
  }

  @override
  List<Object?> get props => [
    listingId,
    viewedAt,
    title,
    make,
    model,
    year,
    priceEur,
    priceCurrency,
    city,
    marketRegion,
    coverImageUrl,
  ];
}
