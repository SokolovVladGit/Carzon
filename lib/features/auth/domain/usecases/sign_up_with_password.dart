import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

/// Sign up with email and password.
///
/// The returned [AuthUser] is null when the Supabase project requires
/// email confirmation and no session was issued. See
/// [AuthRepository.signUpWithPassword] for the full contract.
class SignUpWithPassword {
  SignUpWithPassword(this._repository);

  final AuthRepository _repository;

  Future<Result<AuthUser?>> call({
    required String email,
    required String password,
  }) {
    return _repository.signUpWithPassword(email: email, password: password);
  }
}
