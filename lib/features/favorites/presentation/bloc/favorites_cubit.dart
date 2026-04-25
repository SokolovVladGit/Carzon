import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../auth/domain/entities/auth_user.dart';
import '../../domain/usecases/add_favorite.dart';
import '../../domain/usecases/get_favorite_ids.dart';
import '../../domain/usecases/get_favorite_listings.dart';
import '../../domain/usecases/remove_favorite.dart';
import 'favorites_state.dart';

/// Owns the current user's favorite-id set for fast lookups across the
/// feed, details, and favorites page. App root keeps it in sync with
/// the auth session via [syncWithAuth].
class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit({
    required GetFavoriteIds getFavoriteIds,
    required GetFavoriteListings getFavoriteListings,
    required AddFavorite addFavorite,
    required RemoveFavorite removeFavorite,
  })  : _getFavoriteIds = getFavoriteIds,
        _getFavoriteListings = getFavoriteListings,
        _addFavorite = addFavorite,
        _removeFavorite = removeFavorite,
        super(const FavoritesState());

  final GetFavoriteIds _getFavoriteIds;
  final GetFavoriteListings _getFavoriteListings;
  final AddFavorite _addFavorite;
  final RemoveFavorite _removeFavorite;

  String? _currentUserId;
  int _errorSeq = 0;

  /// Called by the app root on every auth state change.
  /// - Signed in: load this user's favorite ids.
  /// - Signed out: clear local state.
  Future<void> syncWithAuth(AuthUser? user) async {
    if (user == null) {
      _currentUserId = null;
      emit(const FavoritesState(status: FavoritesStatus.ready));
      return;
    }
    if (user.id == _currentUserId && state.status == FavoritesStatus.ready) {
      return;
    }
    _currentUserId = user.id;
    await _loadIds();
  }

  Future<void> _loadIds() async {
    emit(state.copyWith(status: FavoritesStatus.loading));
    final result = await _getFavoriteIds();
    result.fold(
      (_) => emit(state.copyWith(
        status: FavoritesStatus.failure,
        lastError: _nextError(FavoritesFailureKind.loadFailed),
      )),
      (ids) => emit(state.copyWith(
        status: FavoritesStatus.ready,
        ids: ids,
        clearLastError: true,
      )),
    );
  }

  Future<void> loadListings() async {
    if (_currentUserId == null) return;
    emit(state.copyWith(status: FavoritesStatus.loading));
    final result = await _getFavoriteListings();
    result.fold(
      (_) => emit(state.copyWith(
        status: FavoritesStatus.failure,
        lastError: _nextError(FavoritesFailureKind.loadFailed),
      )),
      (listings) {
        final ids = listings.map((l) => l.id).toSet();
        emit(state.copyWith(
          status: FavoritesStatus.ready,
          listings: listings,
          ids: ids,
          clearLastError: true,
        ));
      },
    );
  }

  /// Toggle favorite for [listingId]. No-op if not authenticated.
  /// Emits a transient failure state with a [FavoritesErrorEvent] on
  /// backend error; the widget is responsible for surfacing it (e.g.
  /// snackbar) and mapping the kind to a localized message.
  Future<void> toggle(String listingId) async {
    if (_currentUserId == null) return;
    if (state.isPending(listingId)) return;

    final wasFavorite = state.isFavorite(listingId);
    emit(state.copyWith(pending: {...state.pending, listingId}));

    final result = wasFavorite
        ? await _removeFavorite(listingId)
        : await _addFavorite(listingId);

    final newPending = {...state.pending}..remove(listingId);

    result.fold(
      (_) => emit(state.copyWith(
        status: FavoritesStatus.ready,
        pending: newPending,
        lastError: _nextError(FavoritesFailureKind.toggleFailed),
      )),
      (_) {
        final newIds = {...state.ids};
        if (wasFavorite) {
          newIds.remove(listingId);
        } else {
          newIds.add(listingId);
        }
        // Keep the cached listings list in sync if it was loaded.
        final newListings = wasFavorite
            ? state.listings.where((l) => l.id != listingId).toList()
            : state.listings;
        emit(state.copyWith(
          status: FavoritesStatus.ready,
          pending: newPending,
          ids: newIds,
          listings: newListings,
          clearLastError: true,
        ));
      },
    );
  }

  FavoritesErrorEvent _nextError(FavoritesFailureKind kind) {
    _errorSeq += 1;
    return FavoritesErrorEvent(id: _errorSeq, kind: kind);
  }
}
