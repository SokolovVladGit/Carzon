import 'package:equatable/equatable.dart';

import '../../domain/entities/listing.dart';

enum ListingDetailsStatus { initial, loading, success, failure }

class ListingDetailsState extends Equatable {
  const ListingDetailsState({
    this.status = ListingDetailsStatus.initial,
    this.listing,
    this.errorMessage,
  });

  final ListingDetailsStatus status;
  final Listing? listing;
  final String? errorMessage;

  const ListingDetailsState.initial() : this();
  const ListingDetailsState.loading() : this(status: ListingDetailsStatus.loading);
  const ListingDetailsState.success(Listing listing)
      : this(status: ListingDetailsStatus.success, listing: listing);
  const ListingDetailsState.failure(String message)
      : this(status: ListingDetailsStatus.failure, errorMessage: message);

  @override
  List<Object?> get props => [status, listing, errorMessage];
}
