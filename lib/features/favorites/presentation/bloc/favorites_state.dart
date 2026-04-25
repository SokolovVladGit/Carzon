import 'package:equatable/equatable.dart';

import '../../../listings/domain/entities/listing.dart';

enum FavoritesStatus { unknown, loading, ready, failure }

/// Classifies favorite-related failures so the UI can pick a localized
/// message without the cubit reaching into `AppLocalizations`.
enum FavoritesFailureKind {
  /// Loading the favorite id set or the listings list failed.
  loadFailed,

  /// Toggling favorite state (add/remove) failed.
  toggleFailed,
}

/// Monotonic-id wrapper so repeated identical failure kinds still
/// re-fire a `BlocListener` in the widget and trigger a fresh snackbar.
class FavoritesErrorEvent extends Equatable {
  const FavoritesErrorEvent({required this.id, required this.kind});

  final int id;
  final FavoritesFailureKind kind;

  @override
  List<Object?> get props => [id, kind];
}

class FavoritesState extends Equatable {
  const FavoritesState({
    this.status = FavoritesStatus.unknown,
    this.ids = const <String>{},
    this.pending = const <String>{},
    this.listings = const <Listing>[],
    this.lastError,
  });

  final FavoritesStatus status;
  final Set<String> ids;
  final Set<String> pending;
  final List<Listing> listings;

  /// One-shot error surfaced to the widget layer as a snackbar. The
  /// widget maps [FavoritesFailureKind] to a localized string via
  /// `AppLocalizations`. Null means no pending error.
  final FavoritesErrorEvent? lastError;

  bool isFavorite(String id) => ids.contains(id);
  bool isPending(String id) => pending.contains(id);

  FavoritesState copyWith({
    FavoritesStatus? status,
    Set<String>? ids,
    Set<String>? pending,
    List<Listing>? listings,
    FavoritesErrorEvent? lastError,
    bool clearLastError = false,
  }) {
    return FavoritesState(
      status: status ?? this.status,
      ids: ids ?? this.ids,
      pending: pending ?? this.pending,
      listings: listings ?? this.listings,
      lastError: clearLastError ? null : (lastError ?? this.lastError),
    );
  }

  @override
  List<Object?> get props => [status, ids, pending, listings, lastError];
}
