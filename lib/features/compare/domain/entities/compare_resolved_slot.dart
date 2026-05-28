import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';
import 'compare_item.dart';

/// Resolution phase for one compare column.
enum CompareSlotPhase { loading, ready, unavailable, inactive }

/// One vehicle column after listing fetch (or failure).
class CompareResolvedSlot extends Equatable {
  const CompareResolvedSlot({
    required this.item,
    required this.phase,
    this.listing,
    this.photoCount,
  });

  final CompareItem item;
  final CompareSlotPhase phase;
  final Listing? listing;
  final int? photoCount;

  String get listingId => item.listingId;

  CompareResolvedSlot copyWith({
    CompareSlotPhase? phase,
    Listing? listing,
    int? photoCount,
  }) {
    return CompareResolvedSlot(
      item: item,
      phase: phase ?? this.phase,
      listing: listing ?? this.listing,
      photoCount: photoCount ?? this.photoCount,
    );
  }

  @override
  List<Object?> get props => [item, phase, listing, photoCount];
}
