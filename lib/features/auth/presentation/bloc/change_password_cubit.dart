import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/sign_in_with_password.dart';
import '../../domain/usecases/update_password.dart';
import 'change_password_state.dart';
import 'reset_password_cubit.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  ChangePasswordCubit({
    required SignInWithPassword signInWithPassword,
    required UpdatePassword updatePassword,
  }) : _signInWithPassword = signInWithPassword,
       _updatePassword = updatePassword,
       super(const ChangePasswordState.idle());

  final SignInWithPassword _signInWithPassword;
  final UpdatePassword _updatePassword;

  Future<void> submit({
    required String email,
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.status == ChangePasswordStatus.submitting) {
      return;
    }
    if (currentPassword.isEmpty) {
      emit(
        const ChangePasswordState.failure(
          ChangePasswordFailureKind.emptyCurrentPassword,
        ),
      );
      return;
    }
    if (newPassword.isEmpty) {
      emit(
        const ChangePasswordState.failure(
          ChangePasswordFailureKind.emptyNewPassword,
        ),
      );
      return;
    }
    if (newPassword.length < kMinPasswordLength) {
      emit(
        const ChangePasswordState.failure(
          ChangePasswordFailureKind.passwordTooShort,
        ),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      emit(
        const ChangePasswordState.failure(ChangePasswordFailureKind.mismatch),
      );
      return;
    }

    emit(const ChangePasswordState.submitting());

    final verified = await _signInWithPassword(
      email: email,
      password: currentPassword,
    );
    final signInFailure = verified.fold<Object?>(
      (failure) => failure,
      (_) => null,
    );
    if (signInFailure != null) {
      emit(
        const ChangePasswordState.failure(
          ChangePasswordFailureKind.currentPasswordInvalid,
        ),
      );
      return;
    }

    final updated = await _updatePassword(newPassword: newPassword);
    updated.fold(
      (_) => emit(
        const ChangePasswordState.failure(
          ChangePasswordFailureKind.updateFailed,
        ),
      ),
      (_) => emit(const ChangePasswordState.success()),
    );
  }

  void reset() {
    if (state.status == ChangePasswordStatus.idle) return;
    emit(const ChangePasswordState.idle());
  }
}
