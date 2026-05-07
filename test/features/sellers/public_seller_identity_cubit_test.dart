import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/domain/usecases/clear_seller_avatar.dart';
import 'package:carzon/features/sellers/domain/usecases/get_my_seller_profile.dart';
import 'package:carzon/features/sellers/domain/usecases/update_my_seller_display_name.dart';
import 'package:carzon/features/sellers/domain/usecases/upload_seller_avatar.dart';
import 'package:carzon/features/sellers/presentation/bloc/public_seller_identity_cubit.dart';
import 'package:carzon/features/sellers/presentation/bloc/public_seller_identity_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetMy extends Mock implements GetMySellerProfile {}

class _MockUpdate extends Mock implements UpdateMySellerDisplayName {}

class _MockUploadAvatar extends Mock implements UploadSellerAvatar {}

class _MockClearAvatar extends Mock implements ClearSellerAvatar {}

MySellerProfileModel _row({
  String? dn,
  String? avatarUrl,
  String? avatarPath,
}) => MySellerProfileModel(
  displayName: dn,
  avatarUrl: avatarUrl,
  avatarPath: avatarPath,
  memberSince: DateTime.utc(2026, 1, 1),
  publicVisibility: true,
);

void main() {
  late _MockGetMy getMy;
  late _MockUpdate update;
  late _MockUploadAvatar uploadAvatar;
  late _MockClearAvatar clearAvatar;

  setUp(() {
    registerFallbackValue(Uint8List(0));
    getMy = _MockGetMy();
    update = _MockUpdate();
    uploadAvatar = _MockUploadAvatar();
    clearAvatar = _MockClearAvatar();
  });

  PublicSellerIdentityCubit buildCubit() => PublicSellerIdentityCubit(
    getMySellerProfile: getMy,
    updateMySellerDisplayName: update,
    uploadSellerAvatar: uploadAvatar,
    clearSellerAvatar: clearAvatar,
  );

  blocTest<PublicSellerIdentityCubit, PublicSellerIdentityState>(
    'load emits profile on success',
    build: () {
      when(() => getMy()).thenAnswer((_) async => Success(_row(dn: 'A')));
      return buildCubit();
    },
    act: (c) => c.load(),
    expect: () => [
      isA<PublicSellerIdentityState>().having(
        (s) => s.initialLoading,
        'loading',
        isTrue,
      ),
      isA<PublicSellerIdentityState>()
          .having((s) => s.initialLoading, 'loading', isFalse)
          .having((s) => s.profile?.displayName, 'name', 'A'),
    ],
  );

  blocTest<PublicSellerIdentityCubit, PublicSellerIdentityState>(
    'load emits loadFailed on failure',
    build: () {
      when(
        () => getMy(),
      ).thenAnswer((_) async => const FailureResult(ServerFailure('x')));
      return buildCubit();
    },
    act: (c) => c.load(),
    expect: () => [
      isA<PublicSellerIdentityState>().having(
        (s) => s.initialLoading,
        'l',
        isTrue,
      ),
      isA<PublicSellerIdentityState>().having(
        (s) => s.loadFailed,
        'fail',
        isTrue,
      ),
    ],
  );

  blocTest<PublicSellerIdentityCubit, PublicSellerIdentityState>(
    'save clears via null payload when input whitespace-empty',
    build: () {
      when(() => getMy()).thenAnswer((_) async => Success(_row(dn: 'X')));
      when(() => update(null)).thenAnswer((_) async => Success(_row()));
      return buildCubit();
    },
    seed: () => PublicSellerIdentityState(profile: _row(dn: 'X')),
    act: (c) => c.save('   '),
    expect: () => [
      isA<PublicSellerIdentityState>().having(
        (s) => s.saving,
        'saving',
        isTrue,
      ),
      isA<PublicSellerIdentityState>()
          .having((s) => s.saving, 'saving', isFalse)
          .having((s) => s.profile?.displayName, 'cleared', isNull),
    ],
    verify: (_) {
      verify(() => update(null)).called(1);
    },
  );

  blocTest<PublicSellerIdentityCubit, PublicSellerIdentityState>(
    'uploadAvatarFromPicker success updates profile',
    build: () {
      final updated = _row(
        dn: 'N',
        avatarUrl: 'https://ex/u.jpg',
        avatarPath: 'avatars/u/a.jpg',
      );
      when(
        () => uploadAvatar(
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          previousAvatarStoragePath: any(named: 'previousAvatarStoragePath'),
        ),
      ).thenAnswer((_) async => Success(updated));
      return buildCubit();
    },
    seed: () => PublicSellerIdentityState(profile: _row(dn: 'N')),
    act: (c) => c.uploadAvatarFromPicker(
      bytes: Uint8List.fromList([1]),
      contentType: 'image/jpeg',
    ),
    expect: () => [
      isA<PublicSellerIdentityState>().having(
        (s) => s.avatarBusy,
        'busy',
        isTrue,
      ),
      isA<PublicSellerIdentityState>()
          .having((s) => s.avatarBusy, 'busy', isFalse)
          .having((s) => s.profile?.avatarUrl, 'url', 'https://ex/u.jpg'),
    ],
  );

  blocTest<PublicSellerIdentityCubit, PublicSellerIdentityState>(
    'uploadAvatarFromPicker unsupported emits snack kind',
    build: () {
      when(
        () => uploadAvatar(
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
          previousAvatarStoragePath: any(named: 'previousAvatarStoragePath'),
        ),
      ).thenAnswer(
        (_) async => const FailureResult(SellerAvatarUnsupportedFormat()),
      );
      return buildCubit();
    },
    seed: () => PublicSellerIdentityState(profile: _row(dn: 'N')),
    act: (c) => c.uploadAvatarFromPicker(
      bytes: Uint8List.fromList([2]),
      contentType: 'image/jpeg',
    ),
    expect: () => [
      isA<PublicSellerIdentityState>().having(
        (s) => s.avatarBusy,
        'busy',
        isTrue,
      ),
      isA<PublicSellerIdentityState>()
          .having((s) => s.avatarBusy, 'busy', isFalse)
          .having(
            (s) => s.avatarSnack,
            'snack',
            PublicSellerAvatarSnack.unsupportedFormat,
          ),
    ],
  );

  blocTest<PublicSellerIdentityCubit, PublicSellerIdentityState>(
    'removeAvatar success clears urls',
    build: () {
      final cleared = _row(dn: 'N');
      when(
        () => clearAvatar(
          previousAvatarStoragePath: any(named: 'previousAvatarStoragePath'),
        ),
      ).thenAnswer((_) async => Success(cleared));
      return buildCubit();
    },
    seed: () => PublicSellerIdentityState(
      profile: _row(
        dn: 'N',
        avatarUrl: 'https://ex/o.jpg',
        avatarPath: 'avatars/u/o.jpg',
      ),
    ),
    act: (c) => c.removeAvatar(),
    expect: () => [
      isA<PublicSellerIdentityState>().having(
        (s) => s.avatarBusy,
        'busy',
        isTrue,
      ),
      isA<PublicSellerIdentityState>()
          .having((s) => s.avatarBusy, 'busy', isFalse)
          .having((s) => s.profile?.avatarUrl, 'noUrl', isNull)
          .having(
            (s) => s.avatarSnack,
            'snack',
            PublicSellerAvatarSnack.removed,
          ),
    ],
  );
}
