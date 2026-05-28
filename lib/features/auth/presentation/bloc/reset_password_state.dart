import 'package:equatable/equatable.dart';

enum ResetPasswordStatus { idle, submitting, success, failure }

/// Classifies failure causes so the widget picks a localized message.
enum ResetPasswordFailureKind {
  /// New password field was empty.
  emptyPassword,

  /// New password shorter than the minimum length.
  passwordTooShort,

  /// New and confirm fields differ.
  mismatch,

  /// Supabase rejected the update request.
  updateFailed,
}

class ResetPasswordState extends Equatable {
  const ResetPasswordState({
    this.status = ResetPasswordStatus.idle,
    this.failureKind,
  });

  final ResetPasswordStatus status;

  /// Set together with [ResetPasswordStatus.failure]. Widget resolves
  /// the localized snackbar text via `AppLocalizations`.
  final ResetPasswordFailureKind? failureKind;

  const ResetPasswordState.idle() : this();
  const ResetPasswordState.submitting()
    : this(status: ResetPasswordStatus.submitting);
  const ResetPasswordState.success()
    : this(status: ResetPasswordStatus.success);
  const ResetPasswordState.failure(ResetPasswordFailureKind kind)
    : this(status: ResetPasswordStatus.failure, failureKind: kind);

  @override
  List<Object?> get props => [status, failureKind];
}
