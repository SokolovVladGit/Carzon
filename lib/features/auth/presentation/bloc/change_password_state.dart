import 'package:equatable/equatable.dart';

enum ChangePasswordStatus { idle, submitting, success, failure }

enum ChangePasswordFailureKind {
  emptyCurrentPassword,
  emptyNewPassword,
  passwordTooShort,
  mismatch,
  currentPasswordInvalid,
  updateFailed,
}

class ChangePasswordState extends Equatable {
  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.failureKind,
  });

  final ChangePasswordStatus status;
  final ChangePasswordFailureKind? failureKind;

  const ChangePasswordState.idle() : this();
  const ChangePasswordState.submitting()
    : this(status: ChangePasswordStatus.submitting);
  const ChangePasswordState.success()
    : this(status: ChangePasswordStatus.success);
  const ChangePasswordState.failure(ChangePasswordFailureKind kind)
    : this(status: ChangePasswordStatus.failure, failureKind: kind);

  @override
  List<Object?> get props => [status, failureKind];
}
