import 'dart:async';

import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/messaging/domain/entities/blocked_user.dart';
import 'package:carzon/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:carzon/features/messaging/presentation/bloc/blocked_users_cubit.dart';
import 'package:carzon/features/messaging/presentation/bloc/blocked_users_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockMessagingRepository extends Mock implements MessagingRepository {}

void main() {
  late _MockMessagingRepository repository;

  final user = BlockedUser(
    blockedUserId: 'u1',
    createdAt: DateTime.utc(2026, 1, 1),
    displayName: 'Blocked',
  );

  setUp(() {
    repository = _MockMessagingRepository();
  });

  test('load does not emit after the cubit is closed', () async {
    final pending = Completer<Result<List<BlockedUser>>>();
    when(() => repository.listBlockedUsers()).thenAnswer((_) => pending.future);

    final cubit = BlockedUsersCubit(repository: repository);
    final load = cubit.load();
    await cubit.close();

    pending.complete(Success([user]));
    await load;

    expect(cubit.isClosed, isTrue);
    expect(cubit.state.status, BlockedUsersStatus.loading);
    expect(cubit.state.users, isEmpty);
  });

  test('unblock does not emit after the cubit is closed', () async {
    when(
      () => repository.listBlockedUsers(),
    ).thenAnswer((_) async => Success([user]));
    final pending = Completer<Result<bool>>();
    when(() => repository.unblockUser('u1')).thenAnswer((_) => pending.future);

    final cubit = BlockedUsersCubit(repository: repository);
    await cubit.load();
    final unblocked = cubit.unblock('u1');
    await cubit.close();

    pending.complete(const Success(true));
    expect(await unblocked, isFalse);
    expect(cubit.isClosed, isTrue);
    expect(cubit.state.unblockingUserId, 'u1');
    expect(cubit.state.users, [user]);
  });
}
