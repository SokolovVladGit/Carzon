import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/listing.dart';

enum ListingDetailsStatus { initial, loading, success, failure }

class ListingDetailsState extends Equatable {
  const ListingDetailsState({
    this.status = ListingDetailsStatus.initial,
    this.listing,
    this.heroImageUrls = const [],
    this.loadFailure,
  });

  final ListingDetailsStatus status;
  final Listing? listing;

  /// Ordered carousel URLs resolved from `listing_images` (+ cover fallback).
  /// Empty ⇒ no photographic hero asset (placeholder only).
  final List<String> heroImageUrls;

  /// Populated together with [ListingDetailsStatus.failure]; never surfaced
  /// as raw [.message] in UI — map via [localizedUserFailureMessage].
  final Failure? loadFailure;

  const ListingDetailsState.initial() : this();

  const ListingDetailsState.loading()
    : this(status: ListingDetailsStatus.loading);

  ListingDetailsState.failure(Failure failure)
    : this(status: ListingDetailsStatus.failure, loadFailure: failure);

  ListingDetailsState.success(
    Listing listing, {
    List<String> heroImageUrls = const [],
  }) : this(
         status: ListingDetailsStatus.success,
         listing: listing,
         heroImageUrls: heroImageUrls,
       );

  @override
  List<Object?> get props => [status, listing, heroImageUrls, loadFailure];
}
