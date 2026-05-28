import 'package:equatable/equatable.dart';

enum ForgotPasswordStatus { idle, submitting, success, failure }

/// Classifies failure causes so the widget picks a localized message.
enum ForgotPasswordFailureKind {
  /// The user submitted an empty email.
  emptyEmail,

  /// Supabase / network rejected the request for any other reason.
  requestFailed,
}

class ForgotPasswordState extends Equatable {
  const ForgotPasswordState({
    this.status = ForgotPasswordStatus.idle,
    this.failureKind,
  });

  final ForgotPasswordStatus status;

  /// Set together with [ForgotPasswordStatus.failure]. Widget resolves
  /// the localized snackbar text via `AppLocalizations`.
  final ForgotPasswordFailureKind? failureKind;

  const ForgotPasswordState.idle() : this();
  const ForgotPasswordState.submitting()
    : this(status: ForgotPasswordStatus.submitting);
  const ForgotPasswordState.success()
    : this(status: ForgotPasswordStatus.success);
  const ForgotPasswordState.failure(ForgotPasswordFailureKind kind)
    : this(status: ForgotPasswordStatus.failure, failureKind: kind);

  @override
  List<Object?> get props => [status, failureKind];
}
