import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../../domain/usecases/delete_account.dart';
import 'delete_account_state.dart';

class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  DeleteAccountCubit({required DeleteAccount deleteAccount})
    : _deleteAccount = deleteAccount,
      super(const DeleteAccountState());

  final DeleteAccount _deleteAccount;

  Future<void> submit() async {
    if (isClosed) return;
    if (state.status == DeleteAccountStatus.loading) {
      return;
    }
    emit(
      state.copyWith(status: DeleteAccountStatus.loading, clearFailure: true),
    );

    final result = await _deleteAccount();
    if (isClosed) return;
    switch (result) {
      case Success():
        emit(state.copyWith(status: DeleteAccountStatus.success));
      case FailureResult(:final failure):
        emit(
          state.copyWith(
            status: DeleteAccountStatus.failure,
            failureKind: _mapFailure(failure),
          ),
        );
    }
  }

  static DeleteAccountFailureKind _mapFailure(Failure failure) {
    if (failure is NetworkFailure) {
      return DeleteAccountFailureKind.network;
    }
    final raw = failure.message.toLowerCase();
    if (raw.contains('session') ||
        raw.contains('jwt') ||
        raw.contains('not authenticated') ||
        raw.contains('invalid session')) {
      return DeleteAccountFailureKind.sessionExpired;
    }
    return DeleteAccountFailureKind.generic;
  }
}
