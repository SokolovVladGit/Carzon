import 'dart:typed_data';

import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/features/sellers/data/datasources/seller_avatar_remote_datasource.dart';
import 'package:carzon/features/sellers/data/datasources/sellers_remote_datasource.dart';
import 'package:carzon/features/sellers/data/models/my_seller_profile_model.dart';
import 'package:carzon/features/sellers/data/models/seller_public_profile_model.dart';
import 'package:carzon/features/sellers/data/repositories/sellers_repository_impl.dart';
import 'package:carzon/features/sellers/domain/entities/seller_type.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements SellersRemoteDataSource {}

class _MockAvatar extends Mock implements SellerAvatarRemoteDataSource {}

MySellerProfileModel _myRow({
  String? displayName,
  String? avatarUrl,
  String? avatarPath,
}) => MySellerProfileModel(
  displayName: displayName,
  avatarUrl: avatarUrl,
  avatarPath: avatarPath,
  memberSince: DateTime.utc(2026, 6, 1),
  publicVisibility: true,
);

void main() {
  late _MockRemote remote;
  late _MockAvatar avatarStorage;
  late SellersRepositoryImpl repo;

  setUp(() {
    registerFallbackValue(Uint8List(0));
    remote = _MockRemote();
    avatarStorage = _MockAvatar();
    repo = SellersRepositoryImpl(remote, avatarStorage);
  });

  test('Success(null) when remote returns null', () async {
    when(() => remote.fetchPublicProfile(any())).thenAnswer((_) async => null);

    final out = await repo.getSellerPublicProfile('sid');

    expect(out.fold((_) => 'f', (v) => v), isNull);
    verify(() => remote.fetchPublicProfile('sid')).called(1);
  });

  test('Success(profile) when remote returns model', () async {
    final model = SellerPublicProfileModel.fromJson({
      'user_id': 'u1',
      'display_name': 'Name',
      'avatar_url': null,
      'member_since': '2026-02-01T00:00:00Z',
      'seller_type': 'private',
      'active_listings_count': 1,
      'rating_average': null,
      'rating_count': 0,
      'review_count': 0,
      'verified_phone': false,
      'verified_email': false,
      'verified_dealer': false,
    });
    when(() => remote.fetchPublicProfile(any())).thenAnswer((_) async => model);

    final out = await repo.getSellerPublicProfile('sid');

    final v = out.fold<Object?>((_) => throw StateError('failure'), (p) => p);
    expect(v, isA<SellerPublicProfileModel>());
    expect((v as SellerPublicProfileModel).displayName, 'Name');
    expect(v.sellerType, SellerType.private);
  });

  test('FailureResult(ServerFailure) on ServerException', () async {
    when(
      () => remote.fetchPublicProfile(any()),
    ).thenThrow(ServerException('rpc failed'));

    final out = await repo.getSellerPublicProfile('sid');

    out.fold(
      (f) => expect(f, isA<ServerFailure>()),
      (_) => fail('expected failure'),
    );
  });

  test('getMySellerProfile Success', () async {
    final row = _myRow(displayName: 'Shop');
    when(() => remote.fetchMySellerProfile()).thenAnswer((_) async => row);

    final out = await repo.getMySellerProfile();

    final v = out.fold<Object?>((_) => throw StateError('failure'), (p) => p);
    expect((v as MySellerProfileModel).displayName, 'Shop');
    verify(() => remote.fetchMySellerProfile()).called(1);
  });

  test(
    'updateMySellerDisplayName forwards trimmed semantics via datasource',
    () async {
      final row = _myRow(displayName: null);
      when(
        () => remote.updateMySellerDisplayName(null),
      ).thenAnswer((_) async => row);

      final out = await repo.updateMySellerDisplayName(null);
      expect(out.fold((_) => fail('failure'), (r) => r.displayName), isNull);
      verify(() => remote.updateMySellerDisplayName(null)).called(1);
    },
  );

  test('uploadSellerAvatar success deletes previous storage path', () async {
    final staged = const SellerAvatarUploadPayload(
      storagePath: 'avatars/u1/new.jpg',
      publicUrl:
          'https://proj.supabase.co/storage/v1/object/public/seller-avatars/avatars/u1/new.jpg',
    );
    when(
      () => avatarStorage.uploadAvatar(
        bytes: any(named: 'bytes'),
        contentType: any(named: 'contentType'),
      ),
    ).thenAnswer((_) async => staged);
    when(
      () => remote.updateMySellerAvatar(
        avatarPath: staged.storagePath,
        avatarUrl: staged.publicUrl,
      ),
    ).thenAnswer(
      (_) async => _myRow(
        displayName: 'X',
        avatarUrl: staged.publicUrl,
        avatarPath: staged.storagePath,
      ),
    );
    when(
      () => avatarStorage.deleteByStoragePathBestEffort(any()),
    ).thenAnswer((_) async {});

    final out = await repo.uploadSellerAvatar(
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
      previousAvatarStoragePath: 'avatars/u1/old.jpg',
    );

    expect(
      out.fold((_) => fail('fail'), (r) => r.avatarPath),
      staged.storagePath,
    );
    verify(
      () => avatarStorage.deleteByStoragePathBestEffort('avatars/u1/old.jpg'),
    ).called(1);
  });

  test(
    'uploadSellerAvatar RPC failure deletes staged object best-effort',
    () async {
      final staged = const SellerAvatarUploadPayload(
        storagePath: 'avatars/u1/staged.jpg',
        publicUrl: 'https://example.com/public.jpg',
      );
      when(
        () => avatarStorage.uploadAvatar(
          bytes: any(named: 'bytes'),
          contentType: any(named: 'contentType'),
        ),
      ).thenAnswer((_) async => staged);
      when(
        () => remote.updateMySellerAvatar(
          avatarPath: any(named: 'avatarPath'),
          avatarUrl: any(named: 'avatarUrl'),
        ),
      ).thenThrow(ServerException('rpc'));
      when(
        () => avatarStorage.deleteByStoragePathBestEffort(any()),
      ).thenAnswer((_) async {});

      final out = await repo.uploadSellerAvatar(
        bytes: Uint8List.fromList([9]),
        contentType: 'image/jpeg',
      );

      out.fold(
        (f) => expect(f, isA<ServerFailure>()),
        (_) => fail('expected failure'),
      );
      verify(
        () => avatarStorage.deleteByStoragePathBestEffort(staged.storagePath),
      ).called(1);
    },
  );

  test('uploadSellerAvatar unsupported format maps failure', () async {
    when(
      () => avatarStorage.uploadAvatar(
        bytes: any(named: 'bytes'),
        contentType: any(named: 'contentType'),
      ),
    ).thenThrow(ServerException('seller_avatar_unsupported_format'));

    final out = await repo.uploadSellerAvatar(
      bytes: Uint8List.fromList([1]),
      contentType: 'image/gif',
    );

    out.fold(
      (f) => expect(f, isA<SellerAvatarUnsupportedFormat>()),
      (_) => fail('expected failure'),
    );
    verifyNever(
      () => remote.updateMySellerAvatar(
        avatarPath: any(named: 'avatarPath'),
        avatarUrl: any(named: 'avatarUrl'),
      ),
    );
  });

  test('clearSellerAvatar deletes previous path after RPC', () async {
    when(
      () => remote.clearMySellerAvatar(),
    ).thenAnswer((_) async => _myRow(displayName: 'N'));
    when(
      () => avatarStorage.deleteByStoragePathBestEffort(any()),
    ).thenAnswer((_) async {});

    final out = await repo.clearSellerAvatar(
      previousAvatarStoragePath: 'avatars/u1/x.jpg',
    );

    expect(out.fold((_) => fail('f'), (r) => r.avatarUrl), isNull);
    verify(() => remote.clearMySellerAvatar()).called(1);
    verify(
      () => avatarStorage.deleteByStoragePathBestEffort('avatars/u1/x.jpg'),
    ).called(1);
  });
}
