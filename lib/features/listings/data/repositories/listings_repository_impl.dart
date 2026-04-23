import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/listing.dart';
import '../../domain/repositories/listings_repository.dart';
import '../datasources/listings_remote_datasource.dart';

class ListingsRepositoryImpl implements ListingsRepository {
  ListingsRepositoryImpl(this._remote) : _logger = AppLogger('ListingsRepository');

  final ListingsRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<List<Listing>>> getListings(ListingsQuery query) async {
    try {
      final list = await _remote.fetch(query);
      return Success(list);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getListings unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load listings.'));
    }
  }

  @override
  Future<Result<Listing>> getById(String id) async {
    try {
      final item = await _remote.fetchById(id);
      return Success(item);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getById unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to load listing.'));
    }
  }
}
