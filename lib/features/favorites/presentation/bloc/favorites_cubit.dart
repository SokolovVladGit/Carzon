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
  }) : _getFavoriteIds = getFavoriteIds,
       _getFavoriteListings = getFavoriteListings,
       _addFavorite = addFavorite,
       _removeFavorite = removeFavorite,
       super(const FavoritesState());

  final GetFavoriteIds _getFavoriteIds;
  final GetFavoriteListings _getFavoriteListings;
  final AddFavorite _addFavorite;
  final RemoveFavorite _removeFavorite;

  String? _currentUserId;
  bool _hasSynchronizedAuth = false;
  int _sessionGeneration = 0;
  int _loadGeneration = 0;
  int _errorSeq = 0;

  /// Called by the app root on every auth state change.
  /// - Signed in: load this user's favorite ids.
  /// - Signed out: clear local state.
  Future<void> syncWithAuth(AuthUser? user) async {
    if (isClosed) return;
    final userId = user?.id;
    final firstSynchronization = !_hasSynchronizedAuth;
    final userChanged = !firstSynchronization && userId != _currentUserId;
    final sessionChanged = firstSynchronization || userChanged;
    if (sessionChanged) {
      _hasSynchronizedAuth = true;
      _currentUserId = userId;
      _sessionGeneration += 1;
      _loadGeneration += 1;
      if (isClosed) return;
      if (userId == null || userChanged) {
        emit(const FavoritesState(status: FavoritesStatus.ready));
      }
    }

    if (userId == null) {
      return;
    }
    if (!sessionChanged && state.status == FavoritesStatus.ready) {
      return;
    }
    await _loadIds();
  }

  Future<void> _loadIds() async {
    final userId = _currentUserId;
    if (userId == null) return;
    final sessionGeneration = _sessionGeneration;
    final loadGeneration = ++_loadGeneration;
    emit(state.copyWith(status: FavoritesStatus.loading));
    final result = await _getFavoriteIds();
    if (!_isCurrentLoad(userId, sessionGeneration, loadGeneration)) return;
    result.fold(
      (_) => emit(
        state.copyWith(
          status: FavoritesStatus.failure,
          lastError: _nextError(FavoritesFailureKind.loadFailed),
        ),
      ),
      (ids) => emit(
        state.copyWith(
          status: FavoritesStatus.ready,
          ids: ids,
          clearLastError: true,
        ),
      ),
    );
  }

  Future<void> loadListings() async {
    if (isClosed) return;
    final userId = _currentUserId;
    if (userId == null) return;
    final sessionGeneration = _sessionGeneration;
    final loadGeneration = ++_loadGeneration;
    emit(state.copyWith(status: FavoritesStatus.loading));
    final result = await _getFavoriteListings();
    if (!_isCurrentLoad(userId, sessionGeneration, loadGeneration)) return;
    result.fold(
      (_) => emit(
        state.copyWith(
          status: FavoritesStatus.failure,
          lastError: _nextError(FavoritesFailureKind.loadFailed),
        ),
      ),
      (listings) {
        final ids = listings.map((l) => l.id).toSet();
        emit(
          state.copyWith(
            status: FavoritesStatus.ready,
            listings: listings,
            ids: ids,
            clearLastError: true,
          ),
        );
      },
    );
  }

  /// Toggle favorite for [listingId]. No-op if not authenticated.
  /// Emits a transient failure state with a [FavoritesErrorEvent] on
  /// backend error; the widget is responsible for surfacing it (e.g.
  /// snackbar) and mapping the kind to a localized message.
  Future<void> toggle(String listingId) async {
    if (isClosed) return;
    final userId = _currentUserId;
    if (userId == null) return;
    if (state.isPending(listingId)) return;
    final sessionGeneration = _sessionGeneration;

    final wasFavorite = state.isFavorite(listingId);
    emit(state.copyWith(pending: {...state.pending, listingId}));

    final result = wasFavorite
        ? await _removeFavorite(listingId)
        : await _addFavorite(listingId);

    if (!_isCurrentSession(userId, sessionGeneration)) return;
    final newPending = {...state.pending}..remove(listingId);

    result.fold(
      (_) => emit(
        state.copyWith(
          status: FavoritesStatus.ready,
          pending: newPending,
          lastError: _nextError(FavoritesFailureKind.toggleFailed),
        ),
      ),
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
        emit(
          state.copyWith(
            status: FavoritesStatus.ready,
            pending: newPending,
            ids: newIds,
            listings: newListings,
            clearLastError: true,
          ),
        );
      },
    );
  }

  FavoritesErrorEvent _nextError(FavoritesFailureKind kind) {
    _errorSeq += 1;
    return FavoritesErrorEvent(id: _errorSeq, kind: kind);
  }

  bool _isCurrentSession(String userId, int sessionGeneration) {
    return !isClosed &&
        _currentUserId == userId &&
        _sessionGeneration == sessionGeneration;
  }

  bool _isCurrentLoad(
    String userId,
    int sessionGeneration,
    int loadGeneration,
  ) {
    return _isCurrentSession(userId, sessionGeneration) &&
        _loadGeneration == loadGeneration;
  }
}
