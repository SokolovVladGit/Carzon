import 'package:equatable/equatable.dart';

import '../../domain/entities/blocked_user.dart';

enum BlockedUsersStatus { initial, loading, success, failure }

class BlockedUsersState extends Equatable {
  const BlockedUsersState({
    this.status = BlockedUsersStatus.initial,
    this.users = const [],
    this.unblockingUserId,
  });

  final BlockedUsersStatus status;
  final List<BlockedUser> users;
  final String? unblockingUserId;

  BlockedUsersState copyWith({
    BlockedUsersStatus? status,
    List<BlockedUser>? users,
    String? unblockingUserId,
    bool clearUnblockingUserId = false,
  }) {
    return BlockedUsersState(
      status: status ?? this.status,
      users: users ?? this.users,
      unblockingUserId: clearUnblockingUserId
          ? null
          : (unblockingUserId ?? this.unblockingUserId),
    );
  }

  @override
  List<Object?> get props => [status, users, unblockingUserId];
}
