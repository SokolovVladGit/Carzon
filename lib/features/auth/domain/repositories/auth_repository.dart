import '../../../../core/utils/result.dart';
import '../entities/auth_user.dart';

/// Domain contract. Implementations live in `data/repositories/`.
///
/// Presentation depends ONLY on this interface.
abstract interface class AuthRepository {
  Stream<AuthUser?> get authStateChanges;

  Future<Result<AuthUser?>> getCurrentUser();

  Future<Result<AuthUser>> signInWithPassword({
    required String email,
    required String password,
  });

  /// Signs up a new email/password account.
  ///
  /// Returns:
  ///   * `Success(user)` when the account was created and Supabase
  ///     immediately established an active session (email confirmation
  ///     is disabled in the project).
  ///   * `Success(null)` when the account was created but the project
  ///     requires email confirmation, so no session is available yet.
  ///     Callers should prompt the user to check their email.
  ///   * `FailureResult(...)` only on genuine errors (invalid email,
  ///     password policy, duplicate account rejected, network, etc.).
  Future<Result<AuthUser?>> signUpWithPassword({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();

  /// Asks Supabase to email password-reset instructions to [email].
  /// Always returns [Success] for any server-accepted request — the
  /// caller must not reveal whether an account exists for that email.
  Future<Result<void>> requestPasswordReset(String email);

  /// Updates the current (recovery) session user's password.
  Future<Result<void>> updatePassword(String newPassword);

  /// Fires when Supabase observes a password-recovery event, i.e. the
  /// user opened the reset-email link and Supabase established a
  /// recovery session. Presentation uses this to route into the
  /// reset-password screen and to gate that screen.
  Stream<void> get passwordRecoveryEvents;
}
