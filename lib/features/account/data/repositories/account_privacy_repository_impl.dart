import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/repositories/account_privacy_repository.dart';
import '../datasources/account_privacy_remote_datasource.dart';

class AccountPrivacyRepositoryImpl implements AccountPrivacyRepository {
  AccountPrivacyRepositoryImpl(this._remote)
    : _logger = AppLogger('AccountPrivacyRepository');

  final AccountPrivacyRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Future<Result<void>> deleteOwnAccount() async {
    try {
      await _remote.deleteOwnAccount();
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('deleteOwnAccount unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Failed to delete account.'),
      );
    }
  }
}
