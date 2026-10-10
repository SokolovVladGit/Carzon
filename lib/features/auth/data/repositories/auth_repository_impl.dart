import '../../../../core/config/env.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/result.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/social/apple_native_auth.dart';
import '../../domain/social/google_native_auth.dart';
import '../../domain/social/social_auth_error_mapper.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._remote, {
    GoogleNativeAuth? googleNativeAuth,
    AppleNativeAuth? appleNativeAuth,
  }) : _googleNativeAuth = googleNativeAuth,
       _appleNativeAuth = appleNativeAuth,
       _logger = AppLogger('AuthRepository');

  final AuthRemoteDataSource _remote;
  final GoogleNativeAuth? _googleNativeAuth;
  final AppleNativeAuth? _appleNativeAuth;
  final AppLogger _logger;

  @override
  Stream<AuthUser?> get authStateChanges => _remote.authStateChanges();

  @override
  Future<Result<AuthUser?>> getCurrentUser() async {
    try {
      return Success(_remote.currentUser());
    } catch (e, st) {
      _logger.error('getCurrentUser failed', e, st);
      return const FailureResult(
        UnknownFailure('Failed to load current user.'),
      );
    }
  }

  @override
  Future<Result<AuthUser>> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signInWithPassword(
        email: email,
        password: password,
      );
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
  Future<Result<AuthUser>> signInWithGoogle() async {
    final adapter = _googleNativeAuth;
    if (adapter == null) {
      return const FailureResult(
        AuthFailure(SocialAuthMessages.googleNotConfigured),
      );
    }
    try {
      final tokens = await adapter.authenticate();
      if (tokens.idToken.isEmpty || tokens.accessToken.isEmpty) {
        return const FailureResult(
          AuthFailure(SocialAuthMessages.googleMissingToken),
        );
      }
      final user = await _remote.signInWithGoogleIdToken(
        idToken: tokens.idToken,
        accessToken: tokens.accessToken,
      );
      return Success(user);
    } on AuthCancelledException {
      return const FailureResult(AuthCancelledFailure());
    } on AuthException catch (e) {
      return FailureResult(_mapSocialFailure(e.message, isApple: false));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Google sign-in unknown error', e, st);
      return const FailureResult(AuthFailure(SocialAuthMessages.googleFailed));
    }
  }

  @override
  Future<Result<AuthUser>> signInWithApple() async {
    final adapter = _appleNativeAuth;
    if (adapter == null) {
      return const FailureResult(
        AuthFailure(SocialAuthMessages.appleNotConfigured),
      );
    }
    try {
      final native = await adapter.authenticate();
      if (native.idToken.isEmpty) {
        return const FailureResult(
          AuthFailure(SocialAuthMessages.appleMissingToken),
        );
      }
      var user = await _remote.signInWithAppleIdToken(
        idToken: native.idToken,
        nonce: native.rawNonce,
      );
      if (native.fullName != null) {
        final seeded = await _remote.seedAuthFullNameIfAbsent(
          givenName: native.givenName,
          familyName: native.familyName,
        );
        if (seeded != null) {
          user = seeded;
        }
      }
      return Success(user);
    } on AuthCancelledException {
      return const FailureResult(AuthCancelledFailure());
    } on AuthException catch (e) {
      return FailureResult(_mapSocialFailure(e.message, isApple: true));
    } on NetworkException catch (e) {
      return FailureResult(NetworkFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('Apple sign-in unknown error', e, st);
      return const FailureResult(AuthFailure(SocialAuthMessages.appleFailed));
    }
  }

  Failure _mapSocialFailure(String message, {required bool isApple}) {
    if (SocialAuthMessages.isIdentityCollision(message)) {
      return const AuthFailure(SocialAuthMessages.identityAlreadyExists);
    }
    switch (message) {
      case SocialAuthMessages.googleMissingToken:
      case SocialAuthMessages.appleMissingToken:
      case SocialAuthMessages.googleNotConfigured:
      case SocialAuthMessages.appleNotConfigured:
      case SocialAuthMessages.googleFailed:
      case SocialAuthMessages.appleFailed:
      case SocialAuthMessages.identityAlreadyExists:
        return AuthFailure(message);
      default:
        return AuthFailure(
          isApple
              ? SocialAuthMessages.appleFailed
              : SocialAuthMessages.googleFailed,
        );
    }
  }

  @override
  Future<Result<AuthUser?>> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final user = await _remote.signUpWithPassword(
        email: email,
        password: password,
        emailRedirectTo: Env.passwordResetRedirectUrl,
      );
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
  Future<Result<void>> resendSignupConfirmation(String email) async {
    try {
      await _remote.resendSignupConfirmation(
        email: email,
        emailRedirectTo: Env.passwordResetRedirectUrl,
      );
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('resendSignupConfirmation unknown error', e, st);
      return const FailureResult(UnknownFailure('Confirmation resend failed.'));
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

  @override
  Future<Result<void>> requestPasswordReset(String email) async {
    try {
      await _remote.requestPasswordReset(
        email: email,
        // Optional env-driven redirect keeps the .env pattern consistent
        // with how existing Supabase config is wired. Null is valid and
        // uses the project's default Site URL.
        redirectTo: Env.passwordResetRedirectUrl,
      );
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('requestPasswordReset unknown error', e, st);
      return const FailureResult(
        UnknownFailure('Password-reset request failed.'),
      );
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _remote.updatePassword(newPassword);
      return const Success(null);
    } on AuthException catch (e) {
      return FailureResult(AuthFailure(e.message));
    } on ServerException catch (e) {
      return FailureResult(ServerFailure(e.message));
    } catch (e, st) {
      _logger.error('updatePassword unknown error', e, st);
      return const FailureResult(UnknownFailure('Password update failed.'));
    }
  }

  @override
  Stream<void> get passwordRecoveryEvents => _remote.passwordRecoveryEvents();
}
