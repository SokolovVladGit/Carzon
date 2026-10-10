import 'package:equatable/equatable.dart';

enum ConfirmEmailStatus { idle, submitting, success, failure }

enum ConfirmEmailFailureKind { failed, rateLimited }

class ConfirmEmailState extends Equatable {
  const ConfirmEmailState({
    this.status = ConfirmEmailStatus.idle,
    this.failureKind,
  });

  final ConfirmEmailStatus status;
  final ConfirmEmailFailureKind? failureKind;

  const ConfirmEmailState.idle() : this();

  const ConfirmEmailState.submitting()
    : this(status: ConfirmEmailStatus.submitting);

  const ConfirmEmailState.success() : this(status: ConfirmEmailStatus.success);

  const ConfirmEmailState.failure(ConfirmEmailFailureKind kind)
    : this(status: ConfirmEmailStatus.failure, failureKind: kind);

  @override
  List<Object?> get props => [status, failureKind];
}
