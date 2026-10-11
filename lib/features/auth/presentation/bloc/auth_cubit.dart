import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/social/social_auth_error_mapper.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_with_apple.dart';
import '../../domain/usecases/sign_in_with_google.dart';
import '../../domain/usecases/sign_in_with_password.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/sign_up_with_password.dart';
import 'auth_state.dart';

/// Simple session-state owner — Cubit is sufficient (no complex events).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required GetCurrentUser getCurrentUser,
    required SignInWithPassword signInWithPassword,
    required SignUpWithPassword signUpWithPassword,
    required SignOut signOut,
    SignInWithGoogle? signInWithGoogle,
    SignInWithApple? signInWithApple,
  }) : _repository = repository,
       _getCurrentUser = getCurrentUser,
       _signInWithPassword = signInWithPassword,
       _signUpWithPassword = signUpWithPassword,
       _signOut = signOut,
       _signInWithGoogle = signInWithGoogle ?? SignInWithGoogle(repository),
       _signInWithApple = signInWithApple ?? SignInWithApple(repository),
       super(const AuthState.unknown());

  final AuthRepository _repository;
  final GetCurrentUser _getCurrentUser;
  final SignInWithPassword _signInWithPassword;
  final SignUpWithPassword _signUpWithPassword;
  final SignOut _signOut;
  final SignInWithGoogle _signInWithGoogle;
  final SignInWithApple _signInWithApple;

  StreamSubscription<AuthUser?>? _authSub;
  StreamSubscription<void>? _recoverySub;

  /// Latches to true when Supabase emits a password-recovery event and
  /// is cleared via [clearPasswordRecovery] on explicit exit, or via
  /// [completePasswordRecovery] after a successful password update only
  /// when sign-out actually ends the session. While latched, normal
  /// `authStateChanges` emissions preserve the `passwordRecovery`
  /// status so a late `signedIn`/`tokenRefreshed` event does not demote
  /// the state back to `authenticated` and defeat the reset-page guard.
  bool _inPasswordRecovery = false;

  /// Bumped when a newer auth attempt or a recovery event starts, so a
  /// late sign-in / sign-up / social completion cannot overwrite recovery.
  int _attemptGeneration = 0;

  /// Ignores auth-stream emissions while a recovery sign-out is in flight.
  bool _completingRecovery = false;

  Future<void> bootstrap() async {
    final result = await _getCurrentUser();
    result.fold(
      (failure) => emit(const AuthState.unauthenticated()),
      (user) => emit(
        user == null
            ? const AuthState.unauthenticated()
            : AuthState.authenticated(user),
      ),
    );

    _authSub?.cancel();
    _authSub = _repository.authStateChanges.listen((user) {
      if (_completingRecovery) return;
      if (_inPasswordRecovery) {
        emit(AuthState.passwordRecovery(user));
        return;
      }
      if (user == null) {
        emit(
          AuthState.unauthenticated(
            publicFeedRefreshNonce: state.publicFeedRefreshNonce,
          ),
        );
      } else {
        emit(AuthState.authenticated(user));
      }
    });

    _recoverySub?.cancel();
    _recoverySub = _repository.passwordRecoveryEvents.listen((_) {
      if (_completingRecovery || isClosed) return;
      _invalidateAttempts();
      _inPasswordRecovery = true;
      emit(AuthState.passwordRecovery(state.user));
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    if (state.status == AuthStatus.authenticating || _inPasswordRecovery) {
      return;
    }
    final attempt = _beginAttempt();
    emit(const AuthState.authenticating());
    final result = await _signInWithPassword(email: email, password: password);
    result.fold(
      (failure) =>
          _emitAttempt(attempt, AuthState.error(_signInErrorKind(failure))),
      (user) => _emitAttempt(attempt, AuthState.authenticated(user)),
    );
  }

  Future<void> signInWithGoogle() async {
    if (state.status == AuthStatus.authenticating || _inPasswordRecovery) {
      return;
    }
    final attempt = _beginAttempt();
    emit(const AuthState.authenticating());
    final result = await _signInWithGoogle();
    result.fold(
      (failure) =>
          _emitAttempt(attempt, _socialFailureState(failure, isApple: false)),
      (user) => _emitAttempt(attempt, AuthState.authenticated(user)),
    );
  }

  Future<void> signInWithApple() async {
    if (state.status == AuthStatus.authenticating || _inPasswordRecovery) {
      return;
    }
    final attempt = _beginAttempt();
    emit(const AuthState.authenticating());
    final result = await _signInWithApple();
    result.fold(
      (failure) =>
          _emitAttempt(attempt, _socialFailureState(failure, isApple: true)),
      (user) => _emitAttempt(attempt, AuthState.authenticated(user)),
    );
  }

  AuthState _socialFailureState(Failure failure, {required bool isApple}) {
    if (failure is AuthCancelledFailure) {
      return const AuthState.unauthenticated();
    }
    return AuthState.error(_socialErrorKind(failure, isApple: isApple));
  }

  /// Creates a new account and, depending on the Supabase project
  /// settings, either signs the user in immediately or asks them to
  /// confirm their email:
  ///
  ///   * `Success(user)` → [AuthState.authenticated] is emitted. The
  ///     `onAuthStateChange` subscription established by [bootstrap]
  ///     will also observe this transition and keep the two sources in
  ///     sync.
  ///   * `Success(null)` → [AuthState.needsEmailConfirmation]. The sign-up
  ///     page opens the confirmation screen. The session is established
  ///     later via the confirmation deep link, which emits a normal
  ///     signed-in event — not [AuthStatus.passwordRecovery].
  ///   * Failure → [AuthState.error] with a mapped [AuthErrorKind]
  ///     (network, duplicate email heuristic, generic, …).
  Future<void> signUp({required String email, required String password}) async {
    if (state.status == AuthStatus.authenticating || _inPasswordRecovery) {
      return;
    }
    final attempt = _beginAttempt();
    emit(const AuthState.authenticating());
    final result = await _signUpWithPassword(email: email, password: password);
    result.fold(
      (failure) =>
          _emitAttempt(attempt, AuthState.error(_signUpErrorKind(failure))),
      (user) {
        if (user == null) {
          _emitAttempt(attempt, const AuthState.needsEmailConfirmation());
        } else {
          _emitAttempt(attempt, AuthState.authenticated(user));
        }
      },
    );
  }

  Future<void> signOut() async {
    final result = await _signOut();
    result.fold(
      (_) => emit(const AuthState.error(AuthErrorKind.signOutFailed)),
      (_) {
        _inPasswordRecovery = false;
        emit(
          AuthState.unauthenticated(
            publicFeedRefreshNonce: state.publicFeedRefreshNonce,
          ),
        );
      },
    );
  }

  /// Syncs cubit state after [DeleteAccount] already ran push cleanup and
  /// cleared the Supabase session. Avoids a second [SignOut] / push hook pass.
  void markUnauthenticatedAfterAccountDeletion() {
    _inPasswordRecovery = false;
    emit(
      AuthState.unauthenticated(
        publicFeedRefreshNonce: state.publicFeedRefreshNonce + 1,
      ),
    );
  }

  /// Called when the user leaves reset without changing the password.
  ///
  /// Does not sign out. A recovery session that already belongs to a
  /// user stays authenticated after the latch drops.
  void clearPasswordRecovery() {
    if (!_inPasswordRecovery && state.status != AuthStatus.passwordRecovery) {
      return;
    }
    _invalidateAttempts();
    _inPasswordRecovery = false;
    final user = state.user;
    emit(
      user == null
          ? AuthState.unauthenticated(
              publicFeedRefreshNonce: state.publicFeedRefreshNonce,
            )
          : AuthState.authenticated(user),
    );
  }

  /// Ends the recovery session after a successful password update.
  ///
  /// Returns true only when sign-out succeeded and cubit state is
  /// unauthenticated. A failed sign-out keeps the recovery latch and
  /// does not report the user as signed out.
  Future<bool> completePasswordRecovery() async {
    if (!_inPasswordRecovery && state.status != AuthStatus.passwordRecovery) {
      return state.user == null && state.status == AuthStatus.unauthenticated;
    }
    _invalidateAttempts();
    _completingRecovery = true;
    final result = await _signOut();
    _completingRecovery = false;
    if (isClosed) return false;
    return result.fold(
      (_) {
        _inPasswordRecovery = true;
        emit(AuthState.passwordRecovery(state.user));
        return false;
      },
      (_) {
        _inPasswordRecovery = false;
        emit(
          AuthState.unauthenticated(
            publicFeedRefreshNonce: state.publicFeedRefreshNonce,
          ),
        );
        return true;
      },
    );
  }

  int _beginAttempt() => ++_attemptGeneration;

  void _invalidateAttempts() => _attemptGeneration++;

  void _emitAttempt(int attempt, AuthState next) {
    if (isClosed || attempt != _attemptGeneration || _inPasswordRecovery) {
      return;
    }
    emit(next);
  }

  /// Maps a sign-in [Failure] to an [AuthErrorKind] so the widget layer
  /// can show a specific localized message for the "invalid
  /// credentials" case and a generic fallback otherwise. Match is
  /// substring-based because [Failure] does not carry a structured
  /// error code.
  static AuthErrorKind _signInErrorKind(Failure failure) {
    if (failure is NetworkFailure) {
      return AuthErrorKind.networkConnectivity;
    }
    final raw = failure.message.toLowerCase();
    if (raw.contains('invalid login') ||
        raw.contains('invalid credentials') ||
        raw.contains('invalid email or password') ||
        raw.contains('email not confirmed')) {
      return AuthErrorKind.signInInvalidCredentials;
    }
    return AuthErrorKind.signInFailed;
  }

  static AuthErrorKind _signUpErrorKind(Failure failure) {
    if (failure is NetworkFailure) {
      return AuthErrorKind.networkConnectivity;
    }
    if (failure is AuthFailure) {
      final raw = failure.message.toLowerCase();
      if (raw.contains('already registered') ||
          raw.contains('already been registered') ||
          raw.contains('user already exists') ||
          raw.contains('duplicate key') ||
          raw.contains('already exists') ||
          raw.contains('email address is already')) {
        return AuthErrorKind.signUpEmailTaken;
      }
      if (raw.contains('password') &&
          (raw.contains('weak') ||
              raw.contains('strength') ||
              raw.contains('too short'))) {
        return AuthErrorKind.signUpWeakPassword;
      }
    }
    return AuthErrorKind.signUpFailed;
  }

  static AuthErrorKind _socialErrorKind(
    Failure failure, {
    required bool isApple,
  }) {
    if (failure is NetworkFailure) {
      return AuthErrorKind.networkConnectivity;
    }
    final raw = failure.message;
    if (raw == SocialAuthMessages.identityAlreadyExists ||
        SocialAuthMessages.isIdentityCollision(raw)) {
      return AuthErrorKind.identityAlreadyExists;
    }
    if (raw == SocialAuthMessages.googleNotConfigured ||
        raw == SocialAuthMessages.appleNotConfigured) {
      return AuthErrorKind.socialAuthNotConfigured;
    }
    return isApple
        ? AuthErrorKind.appleSignInFailed
        : AuthErrorKind.googleSignInFailed;
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _recoverySub?.cancel();
    return super.close();
  }
}
