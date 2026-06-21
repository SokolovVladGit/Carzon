import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/result.dart';
import '../../domain/repositories/messaging_repository.dart';
import 'blocked_users_state.dart';

class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  BlockedUsersCubit({required MessagingRepository repository})
    : _repository = repository,
      super(const BlockedUsersState());

  final MessagingRepository _repository;

  Future<void> load() async {
    emit(state.copyWith(status: BlockedUsersStatus.loading));
    final result = await _repository.listBlockedUsers();
    switch (result) {
      case FailureResult():
        emit(state.copyWith(status: BlockedUsersStatus.failure));
      case Success(:final value):
        emit(state.copyWith(status: BlockedUsersStatus.success, users: value));
    }
  }

  Future<bool> unblock(String blockedUserId) async {
    emit(state.copyWith(unblockingUserId: blockedUserId));
    final result = await _repository.unblockUser(blockedUserId);
    switch (result) {
      case FailureResult():
        emit(state.copyWith(clearUnblockingUserId: true));
        return false;
      case Success():
        final next = state.users
            .where((u) => u.blockedUserId != blockedUserId)
            .toList(growable: false);
        emit(state.copyWith(users: next, clearUnblockingUserId: true));
        return true;
    }
  }
}
