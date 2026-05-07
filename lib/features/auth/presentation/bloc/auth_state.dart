import 'package:equatable/equatable.dart';

import '../../domain/entities/auth_user.dart';

enum AuthStatus {
  unknown,
  authenticated,
  unauthenticated,
  authenticating,
  error,

  /// Sign-up succeeded but the Supabase project requires the user to
  /// confirm their email before a session is issued. UI reads
  /// [AuthState.infoKind] to surface the localized message rather than
  /// treating it as a failure.
  needsEmailConfirmation,

  /// The user opened a password-reset link and Supabase established a
  /// transient recovery session. The reset-password screen gates on
  /// this status; no other screen should treat it as a normal signed-in
  /// session.
  passwordRecovery,
}

/// Categorizes auth informational messages so the UI can render them in
/// the app language. Kept deliberately narrow: the cubit does not own
/// Russian / English copy and never emits raw localized strings.
enum AuthInfoKind {
  /// Sign-up succeeded but email confirmation is required.
  signUpConfirmEmail,
}

/// Categorizes auth errors the UI surfaces as snackbars / inline text.
/// The cubit maps Supabase/repository failures to one of these kinds;
/// the widget layer then picks a localized message.
enum AuthErrorKind {
  /// Supabase rejected the credentials on sign-in.
  signInInvalidCredentials,

  /// Sign-in failed for any other reason (network, server, etc.).
  signInFailed,

  /// Sign-up failed (email already in use, rate limit, etc.).
  signUpFailed,

  /// Sign-out failed (usually transient network error).
  signOutFailed,
}

class AuthState extends Equatable {
  const AuthState({
    this.status = AuthStatus.unknown,
    this.user,
    this.errorKind,
    this.infoKind,
  });

  final AuthStatus status;
  final AuthUser? user;

  /// Set together with [AuthStatus.error]. Widgets resolve the final
  /// user-visible message via `AppLocalizations`.
  final AuthErrorKind? errorKind;

  /// Set for non-error informational statuses (currently only
  /// [AuthStatus.needsEmailConfirmation]). Widgets resolve the final
  /// user-visible message via `AppLocalizations`.
  final AuthInfoKind? infoKind;

  const AuthState.unknown() : this();
  const AuthState.authenticating() : this(status: AuthStatus.authenticating);
  const AuthState.authenticated(AuthUser user)
    : this(status: AuthStatus.authenticated, user: user);
  const AuthState.unauthenticated() : this(status: AuthStatus.unauthenticated);
  const AuthState.error(AuthErrorKind kind)
    : this(status: AuthStatus.error, errorKind: kind);
  const AuthState.needsEmailConfirmation([
    AuthInfoKind kind = AuthInfoKind.signUpConfirmEmail,
  ]) : this(status: AuthStatus.needsEmailConfirmation, infoKind: kind);
  const AuthState.passwordRecovery([AuthUser? user])
    : this(status: AuthStatus.passwordRecovery, user: user);

  @override
  List<Object?> get props => [status, user, errorKind, infoKind];
}
