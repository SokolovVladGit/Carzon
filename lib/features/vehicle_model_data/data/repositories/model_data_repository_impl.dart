import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/buyer_listing_model_data_source_result.dart';
import '../../domain/repositories/model_data_repository.dart';
import '../datasources/model_data_remote_datasource.dart';

class ModelDataRepositoryImpl implements ModelDataRepository {
  ModelDataRepositoryImpl(this._remote)
    : _logger = AppLogger('ModelDataRepository');

  final ModelDataRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<List<BuyerListingModelDataSourceResult>>>
  getListingModelDataForBuyer(String listingId) async {
    try {
      final rows = await _remote.fetchListingModelDataForBuyer(listingId);
      return Success(rows);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getListingModelDataForBuyer unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load listing model data.'),
      );
    }
  }
}
