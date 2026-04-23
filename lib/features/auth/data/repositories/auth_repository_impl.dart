import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote) : _logger = AppLogger('AuthRepository');

  final AuthRemoteDataSource _remote;
  final AppLogger _logger;

  @override
  Stream<AuthUser?> get authStateChanges => _remote.authStateChanges();

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    try {
      return Success(_remote.currentUser());
    } catch (e, st) {
      _logger.error('getCurrentUser failed', e, st);
      return const FailureResult(UnknownFailure('Failed to load current user.'));
    }
  }

  @override
  Future<Result<AuthUser>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signInWithPassword(email: email, password: password);
      return Success(user);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('signIn unknown error', e, st);
      return const FailureResult(UnknownFailure('Sign-in failed.'));
    }
  }

  @override
  Future<Result<AuthUser>> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signUpWithPassword(email: email, password: password);
      return Success(user);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('signUp unknown error', e, st);
      return const FailureResult(UnknownFailure('Sign-up failed.'));
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _remote.signOut();
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } catch (e, st) {
      _logger.error('signOut unknown error', e, st);
      return const FailureResult(UnknownFailure('Sign-out failed.'));
    }
  }
}
