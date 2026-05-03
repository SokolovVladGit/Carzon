import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/uploaded_listing_image.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/create_listing_v2.dart';
import 'package:carzon/features/create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_images_sequential.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateRepo extends Mock implements CreateListingRepository {}

class _MockImageRepo extends Mock implements ListingImageRepository {}

NewListingInput _input({
  ListingCurrency? priceCurrency,
  String make = 'M',
  int year = 2020,
}) => NewListingInput(
  sellerId: 's1',
  title: 't',
  make: make,
  model: 'm',
  year: year,
  priceEur: 10000,
  priceCurrency: priceCurrency ?? ListingCurrency.eur,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  contactPhone: '+373 690 00001',
);

Listing _listing({String? coverImageUrl}) => Listing(
  id: 'l1',
  title: 't',
  make: 'M',
  model: 'm',
  year: 2020,
  priceCurrency: ListingCurrency.eur,
  priceEur: 10000,
  mileageKm: 50000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
  status: ListingStatus.active,
  coverImageUrl: coverImageUrl,
  sellerId: 's1',
);

CoverImageUpload _upload([List<int>? data]) => CoverImageUpload(
  sellerId: 's1',
  bytes: Uint8List.fromList(data ?? [1, 2, 3]),
  contentType: 'image/jpeg',
);

void main() {
  setUpAll(() {
    registerFallbackValue(_input());
    registerFallbackValue(<CoverImageUpload>[]);
    registerFallbackValue(_upload());
    registerFallbackValue(const UploadedListingImage(publicUrl: 'x'));
  });

  group('stagingGalleryAttached', () {
    test(
      'null gallery clears gallery + cover staging only when base lacked them',
      () {
        final base = _input();
        expect(
          CreateListingCubit.stagingGalleryAttached(base, null).uploadedGallery,
          isNull,
        );
        final withUrls = UploadedListingImage(publicUrl: 'https://x/a.jpg');
        final merged = CreateListingCubit.stagingGalleryAttached(base, [
          withUrls,
        ]);
        expect(merged.uploadedGallery?.single.publicUrl, withUrls.publicUrl);
        expect(merged.coverImageUrl, isNull);
      },
    );
  });

  group('CreateListingCubit.submit (v2 + gallery)', () {
    late _MockCreateRepo createRepo;
    late _MockImageRepo imageRepo;
    late CreateListingCubit cubit;

    setUp(() {
      createRepo = _MockCreateRepo();
      imageRepo = _MockImageRepo();
      cubit = CreateListingCubit(
        createListingV2: CreateListingV2(createRepo),
        uploadListingImagesSequential: UploadListingImagesSequential(imageRepo),
        deleteUploadedListingImagesBestEffort:
            DeleteUploadedListingImagesBestEffort(imageRepo),
      );
      when(
        () => imageRepo.deleteUploadedBatchBestEffort(
          images: any(named: 'images'),
          sellerId: any(named: 'sellerId'),
        ),
      ).thenAnswer((_) async => const Success(null));
    });

    tearDown(() => cubit.close());

    blocTest<CreateListingCubit, CreateListingState>(
      'no photos → skips upload and passes null gallery/default EUR via createV2',
      setUp: () {
        when(
          () => createRepo.createV2(any()),
        ).thenAnswer((_) async => Success(_listing()));
      },
      build: () => cubit,
      act: (c) => c.submit(listingInput: _input(), orderedPhotos: []),
      expect: () => [
        const CreateListingState.submitting(),
        CreateListingState.success(_listing()),
      ],
      verify: (_) {
        verifyNever(() => imageRepo.uploadSequential(any()));
        final captured =
            verify(() => createRepo.createV2(captureAny())).captured.single
                as NewListingInput;
        expect(captured.uploadedGallery, isNull);
        expect(captured.priceCurrency, ListingCurrency.eur);
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'multiple photos → uploads sequentially then invokes createV2 with gallery '
      '(order preserved); cover URL param remains null — gallery drives cover',
      setUp: () {
        when(() => imageRepo.uploadSequential(any())).thenAnswer(
          (_) async => Success([
            const UploadedListingImage(publicUrl: 'https://cdn/a.jpg'),
            const UploadedListingImage(publicUrl: 'https://cdn/b.jpg'),
          ]),
        );
        when(() => createRepo.createV2(any())).thenAnswer(
          (_) async => Success(_listing(coverImageUrl: 'https://cdn/a.jpg')),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(
        listingInput: _input(),
        orderedPhotos: [
          _upload([10]),
          _upload([20, 21]),
        ],
      ),
      expect: () => [
        const CreateListingState.submitting(),
        CreateListingState.success(
          _listing(coverImageUrl: 'https://cdn/a.jpg'),
        ),
      ],
      verify: (_) {
        final uploadArg =
            verify(
                  () => imageRepo.uploadSequential(captureAny()),
                ).captured.single
                as List<CoverImageUpload>;
        expect(uploadArg.length, 2);
        expect(uploadArg.first.bytes.first, 10);
        expect(uploadArg[1].bytes.length, 2);
        expect(uploadArg[1].bytes.first, 20);

        final io =
            verify(() => createRepo.createV2(captureAny())).captured.single
                as NewListingInput;
        expect(io.uploadedGallery!.map((e) => e.publicUrl).toList(), [
          'https://cdn/a.jpg',
          'https://cdn/b.jpg',
        ]);
        expect(io.coverImageUrl, isNull);
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'USD + make/year propagated into createV2 NewListingInput',
      setUp: () {
        when(
          () => createRepo.createV2(any()),
        ).thenAnswer((_) async => Success(_listing()));
      },
      build: () => cubit,
      act: (c) => c.submit(
        listingInput: _input(
          priceCurrency: ListingCurrency.usd,
          make: 'Toyota',
          year: 2019,
        ),
        orderedPhotos: [],
      ),
      expect: () => [
        const CreateListingState.submitting(),
        CreateListingState.success(_listing()),
      ],
      verify: (_) {
        final io =
            verify(() => createRepo.createV2(captureAny())).captured.single
                as NewListingInput;
        expect(io.priceCurrency, ListingCurrency.usd);
        expect(io.make, 'Toyota');
        expect(io.year, 2019);
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'upload failure ⇒ createV2 not called',
      setUp: () {
        when(
          () => imageRepo.uploadSequential(any()),
        ).thenAnswer((_) async => FailureResult(ServerFailure('rls')));
      },
      build: () => cubit,
      act: (c) => c.submit(listingInput: _input(), orderedPhotos: [_upload()]),
      expect: () => const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.upload),
      ],
      verify: (_) {
        verifyNever(() => createRepo.createV2(any()));
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'after successful uploads createV2 fails ⇒ batch delete invoked; '
      'surface failure still generic mapped kind',
      setUp: () {
        final staged = [
          const UploadedListingImage(publicUrl: 'https://cdn/a.jpg'),
          const UploadedListingImage(publicUrl: 'https://cdn/b.jpg'),
        ];
        when(
          () => imageRepo.uploadSequential(any()),
        ).thenAnswer((_) async => Success(staged));

        when(
          () => createRepo.createV2(any()),
        ).thenAnswer((_) async => const FailureResult(ServerFailure('db')));
      },
      build: () => cubit,
      act: (c) => c.submit(
        listingInput: _input(),
        orderedPhotos: [
          _upload([1]),
          _upload([2, 3]),
        ],
      ),
      expect: () => const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.genericCreate),
      ],
      verify: (_) {
        verify(
          () => imageRepo.deleteUploadedBatchBestEffort(
            images: any<List<UploadedListingImage>>(
              named: 'images',
              that: predicate<List<UploadedListingImage>>(
                (imgs) =>
                    imgs.length == 2 &&
                    imgs[0].publicUrl == 'https://cdn/a.jpg' &&
                    imgs[1].publicUrl == 'https://cdn/b.jpg',
              ),
            ),
            sellerId: 's1',
          ),
        ).called(1);
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'no-cover createV2 failure never touches batch delete.',
      setUp: () {
        when(
          () => createRepo.createV2(any()),
        ).thenAnswer((_) async => const FailureResult(UnknownFailure('x')));
      },
      build: () => cubit,
      act: (c) => c.submit(listingInput: _input(), orderedPhotos: []),
      expect: () => const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.genericCreate),
      ],
      verify: (_) {
        verifyNever(() => imageRepo.uploadSequential(any()));
        verifyNever(
          () => imageRepo.deleteUploadedBatchBestEffort(
            images: any(named: 'images'),
            sellerId: any(named: 'sellerId'),
          ),
        );
      },
    );
  });
}
