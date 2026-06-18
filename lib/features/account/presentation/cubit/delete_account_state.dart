enum DeleteAccountStatus { initial, loading, success, failure }

enum DeleteAccountFailureKind { generic, network, sessionExpired }

class DeleteAccountState {
  const DeleteAccountState({
    this.status = DeleteAccountStatus.initial,
    this.failureKind,
  });

  final DeleteAccountStatus status;
  final DeleteAccountFailureKind? failureKind;

  DeleteAccountState copyWith({
    DeleteAccountStatus? status,
    DeleteAccountFailureKind? failureKind,
    bool clearFailure = false,
  }) {
    return DeleteAccountState(
      status: status ?? this.status,
      failureKind: clearFailure ? null : (failureKind ?? this.failureKind),
    );
  }
}
