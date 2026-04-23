import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

enum FavoritesStatus { unknown, loading, ready, failure }

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.unknown,
    this.ids = const <String>{},
    this.pending = const <String>{},
    this.listings = const <Listing>[],
    this.errorMessage,
  });

  final FavoritesStatus status;
  final Set<String> ids;
  final Set<String> pending;
  final List<Listing> listings;
  final String? errorMessage;

  bool isFavorite(String id) => ids.contains(id);
  bool isPending(String id) => pending.contains(id);

  FavoritesState copyWith({
    FavoritesStatus? status,
    Set<String>? ids,
    Set<String>? pending,
    List<Listing>? listings,
    String? errorMessage,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      ids: ids ?? this.ids,
      pending: pending ?? this.pending,
      listings: listings ?? this.listings,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, ids, pending, listings, errorMessage];
}
