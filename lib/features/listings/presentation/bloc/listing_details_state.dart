import 'package:equatable/equatable.dart';

import '../../domain/entities/listing.dart';

enum ListingDetailsStatus { initial, loading, success, failure }

class ListingDetailsState extends Equatable {
  const ListingDetailsState({
    this.status = ListingDetailsStatus.initial,
    this.listing,
    this.heroImageUrls = const [],
    this.errorMessage,
  });

  final ListingDetailsStatus status;
  final Listing? listing;

  /// Ordered carousel URLs resolved from `listing_images` (+ cover fallback).
  /// Empty ⇒ no photographic hero asset (placeholder only).
  final List<String> heroImageUrls;

  final String? errorMessage;

  const ListingDetailsState.initial() : this();

  const ListingDetailsState.loading()
    : this(status: ListingDetailsStatus.loading);

  // ignore: prefer_const_constructors_in_immutables — [failure] wraps non-const [message].
  ListingDetailsState.failure(String message)
    : this(status: ListingDetailsStatus.failure, errorMessage: message);

  // ignore: prefer_const_constructors_in_immutables — [listing] payload is never const.
  ListingDetailsState.success(
    Listing listing, {
    List<String> heroImageUrls = const [],
  }) : this(
         status: ListingDetailsStatus.success,
         listing: listing,
         heroImageUrls: heroImageUrls,
       );

  @override
  List<Object?> get props => [status, listing, heroImageUrls, errorMessage];
}
