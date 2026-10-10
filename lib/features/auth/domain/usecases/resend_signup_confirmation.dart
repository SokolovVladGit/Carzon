import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Resends the signup confirmation email for [email].
class ResendSignupConfirmation {
  ResendSignupConfirmation(this._repository);

  final AuthRepository _repository;

  Future<Result<void>> call({required String email}) {
    return _repository.resendSignupConfirmation(email);
  }
}
