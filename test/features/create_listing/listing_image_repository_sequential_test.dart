import 'dart:typed_data';

import 'package:carzon/core/errors/exceptions.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/data/datasources/create_listing_image_remote_datasource.dart';
import 'package:carzon/features/create_listing/data/repositories/listing_image_repository_impl.dart';
import 'package:carzon/features/create_listing/domain/constants/listing_gallery_limits.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/uploaded_listing_image.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockDs extends Mock implements CreateListingImageRemoteDataSource {}

CoverImageUpload _upload() => CoverImageUpload(
  sellerId: 's',
  bytes: Uint8List.fromList([0]),
  contentType: 'image/jpeg',
);

void main() {
  setUpAll(() => registerFallbackValue(_upload()));

  group('ListingImageRepositoryImpl.uploadSequential', () {
    test('preserves order and extracts storage paths', () async {
      final ds = _MockDs();
      var n = 0;
      when(() => ds.uploadCover(any())).thenAnswer((_) async {
        n++;
        return 'https://proj.supabase.co/storage/v1/object/public/'
            'listing-images/listings/s/$n.jpg';
      });
      final repo = ListingImageRepositoryImpl(ds);
      final r = await repo.uploadSequential([_upload(), _upload()]);
      expect(r, isA<Success<List<UploadedListingImage>>>());
      final list = (r as Success<List<UploadedListingImage>>).value;
      expect(list.length, 2);
      expect(list[0].storagePath, 'listings/s/1.jpg');
      expect(list[1].storagePath, 'listings/s/2.jpg');
    });

    test('returns empty success for empty input', () async {
      final ds = _MockDs();
      final repo = ListingImageRepositoryImpl(ds);
      final r = await repo.uploadSequential([]);
      expect(r, isA<Success<List<UploadedListingImage>>>());
      expect((r as Success<List<UploadedListingImage>>).value, isEmpty);
      verifyNever(() => ds.uploadCover(any()));
    });

    test(
      'rejects more than kMaxListingPhotos without calling remote',
      () async {
        final ds = _MockDs();
        final repo = ListingImageRepositoryImpl(ds);
        final uploads = List.generate(kMaxListingPhotos + 1, (_) => _upload());
        final r = await repo.uploadSequential(uploads);
        expect(r, isA<FailureResult<List<UploadedListingImage>>>());
        verifyNever(() => ds.uploadCover(any()));
      },
    );

    test('stops on first upload failure', () async {
      final ds = _MockDs();
      when(() => ds.uploadCover(any())).thenThrow(ServerException('x'));
      final repo = ListingImageRepositoryImpl(ds);
      final r = await repo.uploadSequential([_upload(), _upload()]);
      expect(r, isA<FailureResult<List<UploadedListingImage>>>());
      verify(() => ds.uploadCover(any())).called(1);
    });
  });

  group('ListingImageRepositoryImpl.deleteUploadedBatchBestEffort', () {
    test('delegates to datasource per item', () async {
      final ds = _MockDs();
      when(
        () => ds.deleteByPublicUrl(
          publicUrl: any(named: 'publicUrl'),
          sellerId: any(named: 'sellerId'),
        ),
      ).thenAnswer((_) async {});
      final repo = ListingImageRepositoryImpl(ds);
      const images = [
        UploadedListingImage(publicUrl: 'https://a'),
        UploadedListingImage(publicUrl: 'https://b'),
      ];
      await repo.deleteUploadedBatchBestEffort(images: images, sellerId: 's');
      verify(
        () => ds.deleteByPublicUrl(publicUrl: 'https://a', sellerId: 's'),
      ).called(1);
      verify(
        () => ds.deleteByPublicUrl(publicUrl: 'https://b', sellerId: 's'),
      ).called(1);
    });
  });
}
