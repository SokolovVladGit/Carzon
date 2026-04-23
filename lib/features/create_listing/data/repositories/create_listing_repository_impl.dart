import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../listings/domain/entities/listing.dart';
import '../../domain/entities/new_listing_input.dart';
import '../../domain/repositories/create_listing_repository.dart';
import '../datasources/create_listing_remote_datasource.dart';

class CreateListingRepositoryImpl implements CreateListingRepository {
  CreateListingRepositoryImpl(this._remote)
      : _logger = AppLogger('CreateListingRepository');

  final CreateListingRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<Listing>> create(NewListingInput input) async {
    try {
      final listing = await _remote.insert(input);
      return Success(listing);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('create unknown error', e, st);
      return const FailureResult(UnknownFailure('Failed to create listing.'));
    }
  }
}
