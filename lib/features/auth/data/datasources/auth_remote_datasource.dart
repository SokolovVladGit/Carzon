import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/auth_user_model.dart';

/// Only this class is allowed to talk to Supabase auth.
/// Repositories must depend on this datasource — never on Supabase directly.
abstract interface class AuthRemoteDataSource {
  Stream<AuthUserModel?> authStateChanges();
  AuthUserModel? currentUser();
  Future<AuthUserModel> signInWithPassword({
    required String email,
    required String password,
  });

  /// Returns the signed-up user when Supabase also established an active
  /// session (email confirmation disabled in the project), or `null` when
  /// the sign-up succeeded but no session was issued (email confirmation
  /// required). In both cases a non-failure return means the server
  /// accepted the request; a failure is always signalled by an exception.
  Future<AuthUserModel?> signUpWithPassword({
    required String email,
    required String password,
  });
  Future<void> signOut();

  /// Requests a password-reset email for [email]. Supabase intentionally
  /// does not distinguish between "account exists" and "account does not
  /// exist" to prevent account enumeration; callers must surface a
  /// neutral confirmation to the user regardless of the outcome.
  ///
  /// [redirectTo], when non-null, is forwarded to Supabase so the email
  /// link deep-links back into the app or a web fallback. When null,
  /// Supabase uses the project's configured Site URL.
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  });

  /// Updates the current session user's password. Must only be called
  /// when the caller has a valid session — typically the transient
  /// recovery session established when the user opens the reset-email
  /// link. Throws [AuthException] when no session is available or the
  /// update fails.
  Future<void> updatePassword(String newPassword);

  /// Emits once for every `AuthChangeEvent.passwordRecovery` event
  /// raised by Supabase. Consumers use it to route the user to the
  /// reset-password screen and to gate that screen so an arbitrary
  /// signed-in caller cannot reuse it to change passwords.
  Stream<void> passwordRecoveryEvents();
}

class SupabaseAuthRemoteDataSource implements AuthRemoteDataSource {
  SupabaseAuthRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  sb.GoTrueClient get _auth => _supabase.client.auth;

  @override
  Stream<AuthUserModel?> authStateChanges() {
    return _auth.onAuthStateChange.map((event) {
      final user = event.session?.user;
      return user == null ? null : AuthUserModel.fromSupabase(user.toJson());
    });
  }

  @override
  AuthUserModel? currentUser() {
    final user = _auth.currentUser;
    return user == null ? null : AuthUserModel.fromSupabase(user.toJson());
  }

  @override
  Future<AuthUserModel> signInWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = response.user;
      if (user == null) {
        throw AuthException('Sign-in returned no user.');
      }
      return AuthUserModel.fromSupabase(user.toJson());
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Unexpected sign-in error',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<AuthUserModel?> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      // Supabase behavior:
      //   * Email confirmation disabled → `session` and `user` both set.
      //     We return the user so the caller can treat the caller as
      //     authenticated; `onAuthStateChange` will also fire.
      //   * Email confirmation required → `session` is null. We return
      //     null to signal "check your email to confirm". The account has
      //     been created server-side; the user must click the link
      //     before a session is issued.
      //   * Genuine failures surface as `sb.AuthException` and are
      //     mapped below.
      if (response.session == null) {
        return null;
      }
      final user = response.user;
      if (user == null) {
        // Defensive: a session without a user should never happen, but we
        // treat it as "check email" rather than crashing the flow.
        return null;
      }
      return AuthUserModel.fromSupabase(user.toJson());
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Unexpected sign-up error',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Unexpected sign-out error',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> requestPasswordReset({
    required String email,
    String? redirectTo,
  }) async {
    try {
      await _auth.resetPasswordForEmail(email, redirectTo: redirectTo);
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Unexpected password-reset-request error',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      // Supabase refuses the call when there is no active session, so
      // an explicit pre-check isn't strictly necessary. We still map
      // the resulting error into AuthException so the repository can
      // return a friendly AuthFailure.
      await _auth.updateUser(sb.UserAttributes(password: newPassword));
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Unexpected password-update error',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Stream<void> passwordRecoveryEvents() {
    // `onAuthStateChange` is a broadcast stream, so multiple
    // subscribers (this filter + the user stream above) observe the
    // same events without interfering with each other.
    return _auth.onAuthStateChange
        .where((event) => event.event == sb.AuthChangeEvent.passwordRecovery)
        .map<void>((_) {});
  }
}
