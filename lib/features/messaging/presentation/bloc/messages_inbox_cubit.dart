import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../utils/messaging_failure_mapper.dart';
import 'messages_inbox_state.dart';

class MessagesInboxCubit extends Cubit<MessagesInboxState> {
  MessagesInboxCubit(this._repository) : super(const MessagesInboxState());

  final MessagingRepository _repository;
  bool _silentRefreshBusy = false;

  Future<void> refresh() async {
    emit(
      state.copyWith(
        status: MessagesInboxStatus.loading,
        clearFailureKind: true,
      ),
    );
    final result = await _repository.getConversations();
    switch (result) {
      case FailureResult(:final failure):
        if (!isClosed) {
          emit(
            state.copyWith(
              status: MessagesInboxStatus.failure,
              failureKind: messagingFailureKindFrom(failure),
            ),
          );
        }
      case Success(:final value):
        if (!isClosed) {
          emit(
            MessagesInboxState(
              status: MessagesInboxStatus.success,
              conversations: value,
            ),
          );
        }
    }
  }

  /// Background refresh (e.g. pull-to-refresh): same data as [refresh] without
  /// loading or failure UI when the list is already shown.
  Future<void> silentRefresh() async {
    if (state.status != MessagesInboxStatus.success) return;
    if (_silentRefreshBusy) return;

    _silentRefreshBusy = true;
    try {
      final result = await _repository.getConversations();
      switch (result) {
        case FailureResult():
          return;
        case Success(:final value):
          if (!isClosed && state.status == MessagesInboxStatus.success) {
            emit(
              MessagesInboxState(
                status: MessagesInboxStatus.success,
                conversations: value,
              ),
            );
          }
      }
    } finally {
      _silentRefreshBusy = false;
    }
  }
}
