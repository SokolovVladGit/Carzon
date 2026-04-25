import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/usecases/request_password_reset.dart';
import 'forgot_password_state.dart';

/// Owns the request-password-reset flow.
///
/// The cubit intentionally never reports a validation-style error for
/// "email not found"; Supabase does not expose that signal, and the
/// page renders a neutral success confirmation regardless of whether an
/// account exists. Only transport/server errors surface as
/// [ForgotPasswordStatus.failure] carrying a
/// [ForgotPasswordFailureKind]; the widget resolves the message via
/// `AppLocalizations`.
class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  ForgotPasswordCubit({required RequestPasswordReset requestPasswordReset})
      : _requestPasswordReset = requestPasswordReset,
        super(const ForgotPasswordState.idle());

  final RequestPasswordReset _requestPasswordReset;

  Future<void> submit(String email) async {
    final normalized = email.trim();
    if (normalized.isEmpty) {
      emit(const ForgotPasswordState.failure(
        ForgotPasswordFailureKind.emptyEmail,
      ));
      return;
    }

    emit(const ForgotPasswordState.submitting());
    final result = await _requestPasswordReset(email: normalized);
    result.fold(
      (_) => emit(const ForgotPasswordState.failure(
        ForgotPasswordFailureKind.requestFailed,
      )),
      (_) => emit(const ForgotPasswordState.success()),
    );
  }

  /// Returns the cubit to idle so the user can submit again without
  /// remounting the page (e.g. after dismissing a failure snackbar).
  void reset() {
    if (state.status == ForgotPasswordStatus.idle) return;
    emit(const ForgotPasswordState.idle());
  }
}
