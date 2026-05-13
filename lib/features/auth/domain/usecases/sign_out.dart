import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Signs the user out via [AuthRepository], running optional [preSignOutHooks]
/// first (e.g. push token deactivation while the session is still valid).
class SignOut {
  SignOut(
    this._repository, {
    List<Future<void> Function()> preSignOutHooks = const [],
    AppLogger? logger,
  }) : _preSignOutHooks = preSignOutHooks,
       _logger = logger ?? AppLogger('SignOut');

  final AuthRepository _repository;
  final List<Future<void> Function()> _preSignOutHooks;
  final AppLogger _logger;

  Future<Result<void>> call() async {
    for (final hook in _preSignOutHooks) {
      try {
        await hook();
      } catch (e, st) {
        _logger.error('preSignOut hook failed (continuing sign-out)', e, st);
      }
    }
    return _repository.signOut();
  }
}
