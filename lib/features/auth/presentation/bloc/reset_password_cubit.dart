import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/update_password.dart';
import 'reset_password_state.dart';

/// Minimum password length. Mirrors the existing sign-up validator so
/// both flows enforce the same baseline policy without duplicating a
/// literal across pages.
const int kMinPasswordLength = 6;

/// Owns the set-new-password part of the recovery flow.
///
/// Access to the page that uses this cubit is gated upstream by
/// `AuthCubit.state.status == AuthStatus.passwordRecovery`. The cubit
/// itself does NOT re-verify the recovery session; it only validates
/// the password pair and dispatches [UpdatePassword]. A
/// non-authenticated call falls through Supabase and surfaces as a
/// [ResetPasswordStatus.failure] carrying
/// [ResetPasswordFailureKind.updateFailed].
class ResetPasswordCubit extends Cubit<ResetPasswordState> {
  ResetPasswordCubit({required UpdatePassword updatePassword})
    : _updatePassword = updatePassword,
      super(const ResetPasswordState.idle());

  final UpdatePassword _updatePassword;

  Future<void> submit({
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (state.status == ResetPasswordStatus.submitting) {
      return;
    }
    if (newPassword.isEmpty) {
      emit(
        const ResetPasswordState.failure(
          ResetPasswordFailureKind.emptyPassword,
        ),
      );
      return;
    }
    if (newPassword.length < kMinPasswordLength) {
      emit(
        const ResetPasswordState.failure(
          ResetPasswordFailureKind.passwordTooShort,
        ),
      );
      return;
    }
    if (newPassword != confirmPassword) {
      emit(const ResetPasswordState.failure(ResetPasswordFailureKind.mismatch));
      return;
    }

    emit(const ResetPasswordState.submitting());
    final result = await _updatePassword(newPassword: newPassword);
    result.fold(
      (_) => emit(
        const ResetPasswordState.failure(ResetPasswordFailureKind.updateFailed),
      ),
      (_) => emit(const ResetPasswordState.success()),
    );
  }

  void reset() {
    if (state.status == ResetPasswordStatus.idle) return;
    emit(const ResetPasswordState.idle());
  }
}
