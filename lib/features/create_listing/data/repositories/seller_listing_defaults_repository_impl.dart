import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/seller_listing_defaults.dart';
import '../../domain/repositories/seller_listing_defaults_repository.dart';
import '../datasources/seller_listing_defaults_remote_datasource.dart';

class SellerListingDefaultsRepositoryImpl
    implements SellerListingDefaultsRepository {
  SellerListingDefaultsRepositoryImpl(this._remote);

  final SellerListingDefaultsRemoteDataSource _remote;

  @override
  Future<Result<SellerListingDefaults>> getMyListingDefaults() async {
    try {
      final value = await _remote.getMyListingDefaults();
      return Success(value);
    } on ServerException {
      return const Success(SellerListingDefaults.empty());
    } catch (_) {
      return const Success(SellerListingDefaults.empty());
    }
  }

  @override
  Future<Result<SellerListingDefaults>> saveMyListingDefaults(
    SellerListingDefaults defaults,
  ) async {
    try {
      final value = await _remote.upsertMyListingDefaults(defaults);
      return Success(value);
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (_) {
      return const FailureResult(
        UnknownFailure('listing_defaults_save_failed'),
      );
    }
  }
}
