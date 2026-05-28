import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/repositories/sellers_repository.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/presentation/bloc/self_seller_visual_cubit.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSellersRepository extends Mock implements SellersRepository {}

MySellerProfileModel _row({String? displayName, String? avatarUrl}) =>
    MySellerProfileModel(
      displayName: displayName,
      avatarUrl: avatarUrl,
      avatarPath: null,
      memberSince: DateTime.utc(2026, 1, 2),
      publicVisibility: true,
    );

void main() {
  late _MockSellersRepository repository;

  const authenticated = AuthState.authenticated(
    AuthUser(id: 'u1', email: 'u@example.com'),
  );

  setUp(() {
    repository = _MockSellersRepository();
  });

  blocTest<SelfSellerVisualCubit, SelfSellerVisualState>(
    'authenticated success loads trimmed avatar and display name',
    build: () {
      when(() => repository.getMySellerProfile()).thenAnswer(
        (_) async =>
            Success(_row(displayName: '  Shop ', avatarUrl: ' https://x/a ')),
      );
      return SelfSellerVisualCubit(GetMySellerProfile(repository));
    },
    act: (c) => c.prime(authenticated),
    expect: () => [
      isA<SelfSellerVisualState>().having((s) => s.loading, 'loading', isTrue),
      isA<SelfSellerVisualState>()
          .having((s) => s.loading, 'loading', isFalse)
          .having((s) => s.sellerDisplayName, 'dn', 'Shop')
          .having((s) => s.sellerAvatarUrl, 'url', 'https://x/a')
          .having((s) => s.loadFailed, 'loadFailed', isFalse),
    ],
  );

  blocTest<SelfSellerVisualCubit, SelfSellerVisualState>(
    'unauthenticated prime clears seller visuals and loadFailed',
    build: () {
      when(
        () => repository.getMySellerProfile(),
      ).thenAnswer((_) async => Success(_row(displayName: 'A')));
      return SelfSellerVisualCubit(GetMySellerProfile(repository));
    },
    seed: () => SelfSellerVisualState(
      sellerDisplayName: 'A',
      sellerAvatarUrl: 'https://old',
      loadFailed: true,
    ),
    act: (c) => c.prime(const AuthState.unauthenticated()),
    expect: () => [
      isA<SelfSellerVisualState>()
          .having((s) => s.sellerDisplayName, 'dn', isNull)
          .having((s) => s.sellerAvatarUrl, 'url', isNull)
          .having((s) => s.loadFailed, 'loadFailed', isFalse),
    ],
  );

  blocTest<SelfSellerVisualCubit, SelfSellerVisualState>(
    'authenticated FailureResult preserves prior avatar and display name',
    build: () {
      when(
        () => repository.getMySellerProfile(),
      ).thenAnswer((_) async => const FailureResult(NetworkFailure('oops')));
      return SelfSellerVisualCubit(GetMySellerProfile(repository));
    },
    seed: () => const SelfSellerVisualState(
      sellerDisplayName: 'Kept',
      sellerAvatarUrl: 'https://kept/img',
      loadFailed: false,
      loading: false,
    ),
    act: (c) => c.prime(authenticated),
    expect: () => [
      isA<SelfSellerVisualState>().having((s) => s.loading, 'loading', isTrue),
      isA<SelfSellerVisualState>()
          .having((s) => s.loading, 'loading', isFalse)
          .having((s) => s.sellerDisplayName, 'dn', 'Kept')
          .having((s) => s.sellerAvatarUrl, 'url', 'https://kept/img')
          .having((s) => s.loadFailed, 'loadFailed', isTrue),
    ],
  );

  blocTest<SelfSellerVisualCubit, SelfSellerVisualState>(
    'authenticated FailureResult from empty state does not crash',
    build: () {
      when(
        () => repository.getMySellerProfile(),
      ).thenAnswer((_) async => const FailureResult(NetworkFailure('oops')));
      return SelfSellerVisualCubit(GetMySellerProfile(repository));
    },
    act: (c) => c.prime(authenticated),
    expect: () => [
      isA<SelfSellerVisualState>().having((s) => s.loading, 'loading', isTrue),
      isA<SelfSellerVisualState>()
          .having((s) => s.loading, 'loading', isFalse)
          .having((s) => s.sellerDisplayName, 'dn', isNull)
          .having((s) => s.sellerAvatarUrl, 'url', isNull)
          .having((s) => s.loadFailed, 'loadFailed', isTrue),
    ],
  );
}
