import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/get_current_user.dart';
import '../../domain/usecases/sign_in_with_password.dart';
import '../../domain/usecases/sign_out.dart';
import 'auth_state.dart';

/// Simple session-state owner — Cubit is sufficient (no complex events).
class AuthCubit extends Cubit<AuthState> {
  AuthCubit({
    required AuthRepository repository,
    required GetCurrentUser getCurrentUser,
    required SignInWithPassword signInWithPassword,
    required SignOut signOut,
  })  : _repository = repository,
        _getCurrentUser = getCurrentUser,
        _signInWithPassword = signInWithPassword,
        _signOut = signOut,
        super(const AuthState.unknown());

  final AuthRepository _repository;
  final GetCurrentUser _getCurrentUser;
  final SignInWithPassword _signInWithPassword;
  final SignOut _signOut;

  StreamSubscription<AuthUser?>? _authSub;

  Future<void> bootstrap() async {
    final result = await _getCurrentUser();
    result.fold(
      (failure) => emit(const AuthState.unauthenticated()),
      (user) => emit(user == null
          ? const AuthState.unauthenticated()
          : AuthState.authenticated(user)),
    );

    _authSub?.cancel();
    _authSub = _repository.authStateChanges.listen((user) {
      if (user == null) {
        emit(const AuthState.unauthenticated());
      } else {
        emit(AuthState.authenticated(user));
      }
    });
  }

  Future<void> signIn({required String email, required String password}) async {
    emit(const AuthState.authenticating());
    final result = await _signInWithPassword(email: email, password: password);
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (user) => emit(AuthState.authenticated(user)),
    );
  }

  Future<void> signOut() async {
    final result = await _signOut();
    result.fold(
      (failure) => emit(AuthState.error(failure.message)),
      (_) => emit(const AuthState.unauthenticated()),
    );
  }

  @override
  Future<void> close() async {
    await _authSub?.cancel();
    return super.close();
  }
}
