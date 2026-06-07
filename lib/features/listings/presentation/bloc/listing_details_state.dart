import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/listing.dart';
import '../../domain/entities/listing_view_stats.dart';

enum ListingDetailsStatus { initial, loading, success, failure }

class ListingDetailsState extends Equatable {
  const ListingDetailsState({
    this.status = ListingDetailsStatus.initial,
    this.listing,
    this.heroImageUrls = const [],
    this.loadFailure,
    this.viewStats,
  });

  final ListingDetailsStatus status;
  final Listing? listing;

  /// Ordered carousel URLs resolved from `listing_images` (+ cover fallback).
  /// Empty ⇒ no photographic hero asset (placeholder only).
  final List<String> heroImageUrls;

  /// Populated together with [ListingDetailsStatus.failure]; never surfaced
  /// as raw [.message] in UI — map via [localizedUserFailureMessage].
  final Failure? loadFailure;

  /// Fresh totals from `record_listing_view` after a successful details load.
  final ListingViewStats? viewStats;

  const ListingDetailsState.initial() : this();

  const ListingDetailsState.loading()
    : this(status: ListingDetailsStatus.loading);

  const ListingDetailsState.failure(Failure failure)
    : this(status: ListingDetailsStatus.failure, loadFailure: failure);

  const ListingDetailsState.success(
    Listing listing, {
    List<String> heroImageUrls = const [],
    ListingViewStats? viewStats,
  }) : this(
         status: ListingDetailsStatus.success,
         listing: listing,
         heroImageUrls: heroImageUrls,
         viewStats: viewStats,
       );

  ListingDetailsState copyWith({
    ListingDetailsStatus? status,
    Listing? listing,
    List<String>? heroImageUrls,
    Failure? loadFailure,
    ListingViewStats? viewStats,
    bool clearViewStats = false,
  }) {
    return ListingDetailsState(
      status: status ?? this.status,
      listing: listing ?? this.listing,
      heroImageUrls: heroImageUrls ?? this.heroImageUrls,
      loadFailure: loadFailure ?? this.loadFailure,
      viewStats: clearViewStats ? null : (viewStats ?? this.viewStats),
    );
  }

  @override
  List<Object?> get props => [
    status,
    listing,
    heroImageUrls,
    loadFailure,
    viewStats,
  ];
}
