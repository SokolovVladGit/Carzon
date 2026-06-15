import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/buyer_listing_recall_source_result.dart';
import '../../domain/repositories/recall_data_repository.dart';
import '../datasources/recall_data_remote_data_source.dart';

class RecallDataRepositoryImpl implements RecallDataRepository {
  RecallDataRepositoryImpl(this._remote)
    : _logger = AppLogger('RecallDataRepository');

  final RecallDataRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<BuyerListingRecallSourceResult>> getListingRecallsForBuyer(
    String listingId,
  ) async {
    try {
      final result = await _remote.fetchListingRecallsForBuyer(listingId);
      return Success(result);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('getListingRecallsForBuyer unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load listing recall data.'),
      );
    }
  }
}
