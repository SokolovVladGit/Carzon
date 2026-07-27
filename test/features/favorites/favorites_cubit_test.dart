import 'dart:async';

import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/favorites/domain/repositories/favorites_repository.dart';
import 'package:carzon/features/favorites/domain/usecases/add_favorite.dart';
import 'package:carzon/features/favorites/domain/usecases/get_favorite_ids.dart';
import 'package:carzon/features/favorites/domain/usecases/get_favorite_listings.dart';
import 'package:carzon/features/favorites/domain/usecases/remove_favorite.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_cubit.dart';
import 'package:carzon/features/favorites/presentation/bloc/favorites_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

class _ControlledFavoritesRepository implements FavoritesRepository {
  final ids = <Completer<Result<Set<String>>>>[];
  final adds = <Completer<Result<void>>>[];

  @override
  Future<Result<void>> add(String listingId) {
    final completer = Completer<Result<void>>();
    adds.add(completer);
    return completer.future;
  }

  @override
  Future<Result<Set<String>>> getFavoriteIds() {
    final completer = Completer<Result<Set<String>>>();
    ids.add(completer);
    return completer.future;
  }

  @override
  Future<Result<List<Listing>>> getFavoriteListings() async =>
      const Success([]);

  @override
  Future<Result<void>> remove(String listingId) async => const Success(null);
}

FavoritesCubit _buildCubit(_ControlledFavoritesRepository repository) {
  return FavoritesCubit(
    getFavoriteIds: GetFavoriteIds(repository),
    getFavoriteListings: GetFavoriteListings(repository),
    addFavorite: AddFavorite(repository),
    removeFavorite: RemoveFavorite(repository),
  );
}

const _userA = AuthUser(id: 'user-a', email: 'a@example.com');
const _userB = AuthUser(id: 'user-b', email: 'b@example.com');

void main() {
  test('A load cannot repopulate favorites after sign-out', () async {
    final repository = _ControlledFavoritesRepository();
    final cubit = _buildCubit(repository);

    final loadA = cubit.syncWithAuth(_userA);
    expect(cubit.state.status, FavoritesStatus.loading);

    await cubit.syncWithAuth(null);
    expect(cubit.state, const FavoritesState(status: FavoritesStatus.ready));

    repository.ids.single.complete(const Success({'a-listing'}));
    await loadA;

    expect(cubit.state, const FavoritesState(status: FavoritesStatus.ready));
    await cubit.close();
  });

  test('A load cannot overwrite B favorites', () async {
    final repository = _ControlledFavoritesRepository();
    final cubit = _buildCubit(repository);

    final loadA = cubit.syncWithAuth(_userA);
    final loadB = cubit.syncWithAuth(_userB);
    repository.ids[1].complete(const Success({'b-listing'}));
    await loadB;
    expect(cubit.state.ids, {'b-listing'});

    repository.ids[0].complete(const Success({'a-listing'}));
    await loadA;

    expect(cubit.state.ids, {'b-listing'});
    await cubit.close();
  });

  test('newer same-user load remains authoritative', () async {
    final repository = _ControlledFavoritesRepository();
    final cubit = _buildCubit(repository);

    final older = cubit.syncWithAuth(_userA);
    final newer = cubit.syncWithAuth(_userA);
    repository.ids[1].complete(const Success({'newer'}));
    await newer;
    repository.ids[0].complete(const Success({'older'}));
    await older;

    expect(cubit.state.ids, {'newer'});
    await cubit.close();
  });

  test('stale load failure cannot replace signed-out state', () async {
    final repository = _ControlledFavoritesRepository();
    final cubit = _buildCubit(repository);

    final loadA = cubit.syncWithAuth(_userA);
    await cubit.syncWithAuth(null);
    repository.ids.single.complete(
      const FailureResult(NetworkFailure('offline')),
    );
    await loadA;

    expect(cubit.state.status, FavoritesStatus.ready);
    expect(cubit.state.lastError, isNull);
    await cubit.close();
  });

  test('stale favorite mutation and rollback cannot reach B', () async {
    final repository = _ControlledFavoritesRepository();
    final cubit = _buildCubit(repository);

    final initialA = cubit.syncWithAuth(_userA);
    repository.ids.single.complete(const Success({}));
    await initialA;

    final mutationA = cubit.toggle('a-listing');
    expect(cubit.state.pending, {'a-listing'});

    final loadB = cubit.syncWithAuth(_userB);
    repository.ids[1].complete(const Success({'b-listing'}));
    await loadB;

    repository.adds.single.complete(
      const FailureResult(NetworkFailure('mutation failed')),
    );
    await mutationA;

    expect(cubit.state.ids, {'b-listing'});
    expect(cubit.state.pending, isEmpty);
    expect(cubit.state.lastError, isNull);
    await cubit.close();
  });
}
