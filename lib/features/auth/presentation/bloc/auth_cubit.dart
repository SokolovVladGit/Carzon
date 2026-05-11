import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
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
  }) : _repository = repository,
       _getCurrentUser = getCurrentUser,
       _signInWithPassword = signInWithPassword,
       _signUpWithPassword = signUpWithPassword,
       _signOut = signOut,
       super(const AuthState.unknown());

  final AuthRepository _repository;
  final GetCurrentUser _getCurrentUser;
  final SignInWithPassword _signInWithPassword;
  final SignUpWithPassword _signUpWithPassword;
  final SignOut _signOut;

  StreamSubscription<AuthUser?>? _authSub;
  StreamSubscription<void>? _recoverySub;

  /// Latches to true when Supabase emits a password-recovery event and
  /// is cleared via [clearPasswordRecovery] after the reset-password
  /// flow completes (success or explicit exit). While latched, normal
  /// `authStateChanges` emissions preserve the `passwordRecovery`
  /// status so a late `signedIn`/`tokenRefreshed` event does not demote
  /// the state back to `authenticated` and defeat the reset-page guard.
  bool _inPasswordRecovery = false;

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
      if (_inPasswordRecovery) {
        emit(AuthState.passwordRecovery(user));
        return;
      }
      if (user == null) {
        emit(const AuthState.unauthenticated());
      } else {
        emit(AuthState.authenticated(user));
      }
    });

    _recoverySub?.cancel();
    _recoverySub = _repository.passwordRecoveryEvents.listen((_) {
      _inPasswordRecovery = true;
      emit(AuthState.passwordRecovery(state.user));
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthState.authenticating());
    final result = await _signInWithPassword(email: email, password: password);
    result.fold(
      (failure) => emit(AuthState.error(_signInErrorKind(failure))),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  /// Creates a new account and, depending on the Supabase project
  /// settings, either signs the user in immediately or asks them to
  /// confirm their email:
  ///
  ///   * `Success(user)` → [AuthState.authenticated] is emitted. The
  ///     `onAuthStateChange` subscription established by [bootstrap]
  ///     will also observe this transition and keep the two sources in
  ///     sync.
  ///   * `Success(null)` → [AuthState.needsEmailConfirmation] is emitted
  ///     with [AuthInfoKind.signUpConfirmEmail]. The widget resolves
  ///     the user-visible message via `AppLocalizations`. The session
  ///     will be established later via the confirmation deep-link, at
  ///     which point the same `onAuthStateChange` stream emits
  ///     authenticated.
  ///   * Failure → [AuthState.error] with a mapped [AuthErrorKind]
  ///     (network, duplicate email heuristic, generic, …).
  Future<void> signUp({required String email, required String password}) async {
    emit(const AuthState.authenticating());
    final result = await _signUpWithPassword(email: email, password: password);
    result.fold((failure) => emit(AuthState.error(_signUpErrorKind(failure))), (
      user,
    ) {
      if (user == null) {
        emit(const AuthState.needsEmailConfirmation());
      } else {
        emit(AuthState.authenticated(user));
      }
    });
  }

  Future<void> signOut() async {
    final result = await _signOut();
    result.fold(
      (_) => emit(const AuthState.error(AuthErrorKind.signOutFailed)),
      (_) {
        _inPasswordRecovery = false;
        emit(const AuthState.unauthenticated());
      },
    );
  }

  /// Called by the reset-password flow after a successful password
  /// update (or an explicit exit) so subsequent auth-state events
  /// resume normal authenticated/unauthenticated routing instead of
  /// staying latched on `passwordRecovery`.
  void clearPasswordRecovery() {
    if (!_inPasswordRecovery && state.status != AuthStatus.passwordRecovery) {
      return;
    }
    _inPasswordRecovery = false;
    final user = state.user;
    emit(
      user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user),
    );
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

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    await _recoverySub?.cancel();
    return super.close();
  }
}
