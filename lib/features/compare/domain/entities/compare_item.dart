import 'package:equatable/equatable.dart';

import 'compare_listing_snapshot.dart';

/// One vehicle in the local compare set.
class CompareItem extends Equatable {
  const CompareItem({required this.snapshot});

  final CompareListingSnapshot snapshot;

  String get listingId => snapshot.listingId;

  @override
  List<Object?> get props => [snapshot];
}
