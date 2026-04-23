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

  Future<Result<AuthUser>> signUpWithPassword({
    required String email,
    required String password,
  });

  Future<Result<void>> signOut();
}
