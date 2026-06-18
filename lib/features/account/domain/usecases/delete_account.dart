import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../../auth/domain/repositories/auth_repository.dart';
import '../../../notifications/services/push_notification_registration_service.dart';
import '../repositories/account_privacy_repository.dart';

/// Permanently deletes the authenticated user's account.
///
/// Deactivates push tokens while the session is valid, invokes backend
/// deletion, then clears the local auth session.
class DeleteAccount {
  DeleteAccount(
    this._accountPrivacyRepository,
    this._authRepository,
    this._pushRegistration, {
    AppLogger? logger,
  }) : _logger = logger ?? AppLogger('DeleteAccount');

  final AccountPrivacyRepository _accountPrivacyRepository;
  final AuthRepository _authRepository;
  final PushNotificationRegistrationService _pushRegistration;
  final AppLogger _logger;

  Future<Result<void>> call() async {
    try {
      await _pushRegistration.beforeSignOut();
    } catch (e, st) {
      _logger.error('push cleanup before account deletion failed (continuing)', e, st);
    }

    final deleteResult = await _accountPrivacyRepository.deleteOwnAccount();
    if (deleteResult case FailureResult(:final failure)) {
      return FailureResult(failure);
    }

    final signOutResult = await _authRepository.signOut();
    if (signOutResult case FailureResult(:final failure)) {
      _logger.error(
        'signOut after account deletion failed (continuing)',
        failure,
        StackTrace.current,
      );
    }

    return const Success(null);
  }
}
