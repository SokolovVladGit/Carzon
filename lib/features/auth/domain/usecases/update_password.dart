import '../../../../core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// Updates the current (recovery) session user's password.
///
/// Must only be invoked when the caller has a valid session suitable
/// for a password update — typically the transient recovery session
/// Supabase establishes when the user opens the reset-email link. The
/// presentation layer is responsible for gating access; this use case
/// simply delegates to the repository.
class UpdatePassword {
  UpdatePassword(this._repository);
  final AuthRepository _repository;

  Future<Result<void>> call({required String newPassword}) {
    return _repository.updatePassword(newPassword);
  }
}
