import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../datasources/favorites_remote_datasource.dart';

class FavoritesRepositoryImpl implements FavoritesRepository {
  FavoritesRepositoryImpl(this._remote)
      : _logger = AppLogger('FavoritesRepository');

  final FavoritesRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<Set<String>>> getFavoriteIds() async {
    try {
      return Success(await _remote.fetchIds());
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getFavoriteIds unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load favorites.'));
    }
  }

  @override
  Future<Result<List<Listing>>> getFavoriteListings() async {
    try {
      return Success(await _remote.fetchListings());
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getFavoriteListings unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load favorites.'));
    }
  }

  @override
  Future<Result<void>> add(String listingId) async {
    try {
      await _remote.add(listingId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('add favorite unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to add favorite.'));
    }
  }

  @override
  Future<Result<void>> remove(String listingId) async {
    try {
      await _remote.remove(listingId);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('remove favorite unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to remove favorite.'));
    }
  }
}
