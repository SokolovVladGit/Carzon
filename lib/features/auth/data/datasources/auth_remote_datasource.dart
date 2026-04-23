import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../models/auth_user_model.dart';

/// Only this class is allowed to talk to Supabase auth.
/// Repositories must depend on this datasource — never on Supabase directly.
abstract interface class AuthRemoteDataSource {
  Stream<AuthUserModel?> authStateChanges();
  AuthUserModel? currentUser();
  Future<AuthUserModel> signInWithPassword({required String email, required String password});
  Future<AuthUserModel> signUpWithPassword({required String email, required String password});
  Future<void> signOut();
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
      final response = await _auth.signInWithPassword(email: email, password: password);
      final user = response.user;
      if (user == null) {
        throw AuthException('Sign-in returned no user.');
      }
      return AuthUserModel.fromSupabase(user.toJson());
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException('Unexpected sign-in error', cause: e, stackTrace: st);
    }
  }

  @override
  Future<AuthUserModel> signUpWithPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _auth.signUp(email: email, password: password);
      final user = response.user;
      if (user == null) {
        throw AuthException('Sign-up returned no user.');
      }
      return AuthUserModel.fromSupabase(user.toJson());
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException('Unexpected sign-up error', cause: e, stackTrace: st);
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on sb.AuthException catch (e, st) {
      throw AuthException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException('Unexpected sign-out error', cause: e, stackTrace: st);
    }
  }
}
