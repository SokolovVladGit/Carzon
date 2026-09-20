import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/vehicle_resolve_result.dart';
import 'package:carzon/features/create_listing/domain/entities/uploaded_listing_image.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/repositories/vehicle_resolver_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/create_listing_v2.dart';
import 'package:carzon/features/create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import 'package:carzon/features/create_listing/domain/usecases/resolve_vehicle.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_images_sequential.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateRepo extends Mock implements CreateListingRepository {}

class _MockImageRepo extends Mock implements ListingImageRepository {}

class _NoopResolver implements VehicleResolverRepository {
  @override
  Future<Result<VehicleResolveResult>> resolveVehicle({required String vin}) {
    throw StateError('resolve-vehicle must not run in submit tests');
  }
}

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
    String? currentUserId;

    setUp(() {
      createRepo = _MockCreateRepo();
      imageRepo = _MockImageRepo();
      currentUserId = 's1';
      cubit = CreateListingCubit(
        currentUserId: () => currentUserId,
        createListingV2: CreateListingV2(createRepo),
        uploadListingImagesSequential: UploadListingImagesSequential(imageRepo),
        deleteUploadedListingImagesBestEffort:
            DeleteUploadedListingImagesBestEffort(imageRepo),
        resolveVehicle: ResolveVehicle(_NoopResolver()),
      );
      when(
        () => imageRepo.deleteUploadedBatchBestEffort(
          images: any(named: 'images'),
          sellerId: any(named: 'sellerId'),
        ),
      ).thenAnswer((_) async => const Success(null));
    });

    tearDown(() => cubit.close());

    test(
      'account change between images stops upload and create without cleanup',
      () async {
        final gate = Completer<Result<List<UploadedListingImage>>>();
        when(
          () => imageRepo.uploadSequential(any()),
        ).thenAnswer((_) => gate.future);
        final pending = cubit.submit(
          listingInput: _input(),
          orderedPhotos: [_upload(), _upload()],
        );
        currentUserId = 'user-b';
        gate.complete(
          const Success([UploadedListingImage(publicUrl: 'https://cdn/a.jpg')]),
        );
        await pending;
        verify(() => imageRepo.uploadSequential(any())).called(1);
        verifyNever(() => createRepo.createV2(any()));
        verifyNever(
          () => imageRepo.deleteUploadedBatchBestEffort(
            images: any(named: 'images'),
            sellerId: any(named: 'sellerId'),
          ),
        );
        expect(cubit.state.status, CreateListingStatus.idle);
      },
    );

    test('A to B to A invalidates pending create success', () async {
      final gate = Completer<Result<Listing>>();
      when(() => createRepo.createV2(any())).thenAnswer((_) => gate.future);
      final pending = cubit.submit(listingInput: _input(), orderedPhotos: []);
      currentUserId = 'user-b';
      cubit.syncWithAuth(currentUserId);
      currentUserId = 's1';
      cubit.syncWithAuth(currentUserId);
      gate.complete(Success(_listing()));
      await pending;
      expect(cubit.state.status, CreateListingStatus.idle);
      expect(cubit.state.created, isNull);
    });

    test('closed cubit ignores create completion', () async {
      final gate = Completer<Result<Listing>>();
      when(() => createRepo.createV2(any())).thenAnswer((_) => gate.future);
      final pending = cubit.submit(listingInput: _input(), orderedPhotos: []);
      await cubit.close();
      gate.complete(Success(_listing()));
      await pending;
      expect(cubit.state.status, isNot(CreateListingStatus.success));
    });

    test('ambiguous create failure preserves uploaded objects', () async {
      when(() => imageRepo.uploadSequential(any())).thenAnswer(
        (_) async => const Success([
          UploadedListingImage(publicUrl: 'https://cdn/a.jpg'),
        ]),
      );
      when(() => createRepo.createV2(any())).thenAnswer(
        (_) async => const FailureResult(ServerFailure('response lost')),
      );
      await cubit.submit(listingInput: _input(), orderedPhotos: [_upload()]);
      expect(cubit.state.status, CreateListingStatus.failure);
      verifyNever(
        () => imageRepo.deleteUploadedBatchBestEffort(
          images: any(named: 'images'),
          sellerId: any(named: 'sellerId'),
        ),
      );
    });

    test(
      'account change during rejection cleanup stops remaining deletes',
      () async {
        when(() => imageRepo.uploadSequential(any())).thenAnswer(
          (_) async => const Success([
            UploadedListingImage(publicUrl: 'https://cdn/a.jpg'),
          ]),
        );
        when(() => createRepo.createV2(any())).thenAnswer(
          (_) async => const FailureResult(
            ServerFailure('rejected', postgrestCode: '22023'),
          ),
        );
        when(
          () => imageRepo.deleteUploadedBatchBestEffort(
            images: any(named: 'images'),
            sellerId: any(named: 'sellerId'),
          ),
        ).thenAnswer((_) async {
          currentUserId = 'user-b';
          return const Success(null);
        });
        await cubit.submit(
          listingInput: _input(),
          orderedPhotos: [_upload(), _upload()],
        );
        verify(
          () => imageRepo.deleteUploadedBatchBestEffort(
            images: any(named: 'images'),
            sellerId: 's1',
          ),
        ).called(1);
        expect(cubit.state.status, CreateListingStatus.idle);
      },
    );

    test('known partial upload failure cleans earlier images', () async {
      var count = 0;
      when(() => imageRepo.uploadSequential(any())).thenAnswer(
        (_) async => ++count == 1
            ? const Success([
                UploadedListingImage(publicUrl: 'https://cdn/a.jpg'),
              ])
            : const FailureResult(ServerFailure('upload rejected')),
      );
      await cubit.submit(
        listingInput: _input(),
        orderedPhotos: [_upload(), _upload()],
      );
      verify(
        () => imageRepo.deleteUploadedBatchBestEffort(
          images: any(named: 'images'),
          sellerId: 's1',
        ),
      ).called(1);
      verifyNever(() => createRepo.createV2(any()));
      expect(cubit.state.failureKind, CreateListingFailureKind.upload);
    });

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
          (call) async => Success([
            UploadedListingImage(
              publicUrl:
                  (call.positionalArguments.single as List<CoverImageUpload>)
                          .single
                          .bytes
                          .first ==
                      10
                  ? 'https://cdn/a.jpg'
                  : 'https://cdn/b.jpg',
            ),
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
        final uploadArgs = verify(
          () => imageRepo.uploadSequential(captureAny()),
        ).captured.cast<List<CoverImageUpload>>();
        expect(uploadArgs.length, 2);
        expect(uploadArgs[0].single.bytes.first, 10);
        expect(uploadArgs[1].single.bytes.first, 20);

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
      'body type propagated into createV2 NewListingInput',
      setUp: () {
        when(
          () => createRepo.createV2(any()),
        ).thenAnswer((_) async => Success(_listing()));
      },
      build: () => cubit,
      act: (c) => c.submit(
        listingInput: _input().copyWith(bodyType: ListingBodyType.wagon),
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
        expect(io.bodyType, ListingBodyType.wagon);
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
      'definite create rejection cleans staged images in guarded steps',
      setUp: () {
        when(() => imageRepo.uploadSequential(any())).thenAnswer(
          (call) async => Success([
            UploadedListingImage(
              publicUrl:
                  (call.positionalArguments.single as List<CoverImageUpload>)
                          .single
                          .bytes
                          .first ==
                      1
                  ? 'https://cdn/a.jpg'
                  : 'https://cdn/b.jpg',
            ),
          ]),
        );

        when(() => createRepo.createV2(any())).thenAnswer(
          (_) async => const FailureResult(
            ServerFailure('rejected', postgrestCode: '22023'),
          ),
        );
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
                    imgs.length == 1 &&
                    [
                      'https://cdn/a.jpg',
                      'https://cdn/b.jpg',
                    ].contains(imgs[0].publicUrl),
              ),
            ),
            sellerId: 's1',
          ),
        ).called(2);
      },
    );

    test('second synchronous submit during upload awaits is ignored '
        '(single upload + single create)', () async {
      final gate = Completer<void>();
      final staged = [
        const UploadedListingImage(publicUrl: 'https://cdn/a.jpg'),
      ];
      when(() => imageRepo.uploadSequential(any())).thenAnswer((_) async {
        await gate.future;
        return Success(staged);
      });
      when(
        () => createRepo.createV2(any()),
      ).thenAnswer((_) async => Success(_listing()));

      final c = cubit;
      expect(c.state.status, CreateListingStatus.idle);

      final first = c.submit(
        listingInput: _input(),
        orderedPhotos: [_upload()],
      );
      await Future<void>.value();
      expect(c.state.status, CreateListingStatus.submitting);

      final secondFuture = c.submit(
        listingInput: _input(),
        orderedPhotos: [_upload()],
      );
      gate.complete();

      await first;
      await secondFuture;

      verify(() => imageRepo.uploadSequential(any())).called(1);
      verify(() => createRepo.createV2(any())).called(1);
    });

    blocTest<CreateListingCubit, CreateListingState>(
      'integer-range createV2 rejection after successful uploads '
      'rolls back images and is not an upload failure',
      setUp: () {
        when(() => imageRepo.uploadSequential(any())).thenAnswer(
          (_) async => const Success([
            UploadedListingImage(publicUrl: 'https://cdn/a.jpg'),
          ]),
        );
        when(() => createRepo.createV2(any())).thenAnswer(
          (_) async => const FailureResult(
            ServerFailure(
              'value "120006576546546546" is out of range for type integer',
              postgrestCode: '22003',
            ),
          ),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(listingInput: _input(), orderedPhotos: [_upload()]),
      expect: () => const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.genericCreate),
      ],
      verify: (_) {
        verify(() => imageRepo.uploadSequential(any())).called(1);
        verify(() => createRepo.createV2(any())).called(1);
        verify(
          () => imageRepo.deleteUploadedBatchBestEffort(
            images: any(named: 'images'),
            sellerId: 's1',
          ),
        ).called(1);
        expect(cubit.state.failureKind, isNot(CreateListingFailureKind.upload));
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
