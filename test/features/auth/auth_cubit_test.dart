import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/domain/repositories/auth_repository.dart';
import 'package:carzon/features/auth/domain/usecases/get_current_user.dart';
import 'package:carzon/features/auth/domain/usecases/sign_in_with_password.dart';
import 'package:carzon/features/auth/domain/usecases/sign_out.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements AuthRepository {}

void main() {
  group('AuthCubit', () {
    late _MockRepo repo;
    late AuthCubit cubit;
    const user = AuthUser(id: 'u1', email: 'a@b.c');

    setUp(() {
      repo = _MockRepo();
      when(() => repo.authStateChanges).thenAnswer((_) => const Stream.empty());
      cubit = AuthCubit(
        repository: repo,
        getCurrentUser: GetCurrentUser(repo),
        signInWithPassword: SignInWithPassword(repo),
        signOut: SignOut(repo),
      );
    });

    tearDown(() => cubit.close());

    blocTest<AuthCubit, AuthState>(
      'emits authenticated on successful sign in',
      build: () {
        when(() => repo.signInWithPassword(
              email: any(named: 'email'),
              password: any(named: 'password'),
            )).thenAnswer((_) async => const Success(user));
        return cubit;
      },
      act: (c) => c.signIn(email: 'a@b.c', password: 'secret1'),
      expect: () => const [
        AuthState.authenticating(),
        AuthState.authenticated(user),
      ],
    );
  });
}
