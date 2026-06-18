import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/account/domain/usecases/delete_account.dart';
import 'package:carzon/features/account/presentation/cubit/delete_account_cubit.dart';
import 'package:carzon/features/account/presentation/cubit/delete_account_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDeleteAccount extends Mock implements DeleteAccount {}

void main() {
  late _MockDeleteAccount deleteAccount;

  setUp(() {
    deleteAccount = _MockDeleteAccount();
  });

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'emits loading then success when delete succeeds',
    build: () => DeleteAccountCubit(deleteAccount: deleteAccount),
    act: (cubit) async {
      when(() => deleteAccount()).thenAnswer((_) async => const Success(null));
      await cubit.submit();
    },
    expect: () => [
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.loading,
      ),
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.success,
      ),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'emits failure on server error',
    build: () => DeleteAccountCubit(deleteAccount: deleteAccount),
    act: (cubit) async {
      when(() => deleteAccount()).thenAnswer(
        (_) async => const FailureResult(ServerFailure('boom')),
      );
      await cubit.submit();
    },
    expect: () => [
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.loading,
      ),
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.failure,
      ).having(
        (s) => s.failureKind,
        'failureKind',
        DeleteAccountFailureKind.generic,
      ),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'maps network failure kind',
    build: () => DeleteAccountCubit(deleteAccount: deleteAccount),
    act: (cubit) async {
      when(() => deleteAccount()).thenAnswer(
        (_) async => const FailureResult(NetworkFailure('offline')),
      );
      await cubit.submit();
    },
    expect: () => [
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.loading,
      ),
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.failure,
      ).having(
        (s) => s.failureKind,
        'failureKind',
        DeleteAccountFailureKind.network,
      ),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'ignores duplicate submit while loading',
    build: () => DeleteAccountCubit(deleteAccount: deleteAccount),
    act: (cubit) async {
      when(() => deleteAccount()).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return const Success(null);
      });
      final first = cubit.submit();
      final second = cubit.submit();
      await first;
      await second;
    },
    expect: () => [
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.loading,
      ),
      isA<DeleteAccountState>().having(
        (s) => s.status,
        'status',
        DeleteAccountStatus.success,
      ),
    ],
    verify: (_) {
      verify(() => deleteAccount()).called(1);
    },
  );
}
