import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/usecases/resend_signup_confirmation.dart';
import 'confirm_email_state.dart';

/// Resends the signup confirmation email for a known address.
///
/// The address comes from the signup form that just succeeded, so this
/// flow does not probe whether arbitrary emails exist.
class ConfirmEmailCubit extends Cubit<ConfirmEmailState> {
  ConfirmEmailCubit({
    required String email,
    required ResendSignupConfirmation resendSignupConfirmation,
  }) : email = email.trim(),
       _resendSignupConfirmation = resendSignupConfirmation,
       super(const ConfirmEmailState.idle());

  final String email;
  final ResendSignupConfirmation _resendSignupConfirmation;

  Future<void> resend() async {
    if (isClosed) return;
    if (state.status == ConfirmEmailStatus.submitting) return;
    if (email.isEmpty) {
      emit(const ConfirmEmailState.failure(ConfirmEmailFailureKind.failed));
      return;
    }

    emit(const ConfirmEmailState.submitting());
    final result = await _resendSignupConfirmation(email: email);
    if (isClosed) return;
    result.fold(
      (failure) => emit(ConfirmEmailState.failure(_failureKind(failure))),
      (_) => emit(const ConfirmEmailState.success()),
    );
  }

  static ConfirmEmailFailureKind _failureKind(Failure failure) {
    final raw = failure.message.toLowerCase();
    if (raw.contains('rate limit') ||
        raw.contains('too many') ||
        raw.contains('only request this after')) {
      return ConfirmEmailFailureKind.rateLimited;
    }
    return ConfirmEmailFailureKind.failed;
  }
}
