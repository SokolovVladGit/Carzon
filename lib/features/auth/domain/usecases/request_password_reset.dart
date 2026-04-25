import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Asks the backend to send a password-reset email.
///
/// Always resolves as [Success] for any server-accepted request — the
/// caller must surface a neutral, non-enumerating confirmation to the
/// user. Genuine backend errors (network, 5xx, throttling) still
/// surface as [FailureResult].
class RequestPasswordReset {
  RequestPasswordReset(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    return _repository.requestPasswordReset(email);
  }
}
