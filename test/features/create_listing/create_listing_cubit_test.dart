import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/create_listing.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_cover_image.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_cubit.dart';
import 'package:carzon/features/create_listing/presentation/bloc/create_listing_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCreateRepo extends Mock implements CreateListingRepository {}

class _MockImageRepo extends Mock implements ListingImageRepository {}

NewListingInput _input({String? coverImageUrl}) => NewListingInput(
      sellerId: 's1',
      title: 't',
      make: 'M',
      model: 'm',
      year: 2020,
      priceEur: 10000,
      mileageKm: 50000,
      type: ListingType.sale,
      city: 'Tiraspol',
      marketRegion: MarketRegion.transnistria,
      coverImageUrl: coverImageUrl,
      contactPhone: '+373 690 00001',
    );

Listing _listing(String? coverImageUrl) => Listing(
      id: 'l1',
      title: 't',
      make: 'M',
      model: 'm',
      year: 2020,
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

CoverImageUpload _upload() => CoverImageUpload(
      sellerId: 's1',
      bytes: Uint8List.fromList([1, 2, 3]),
      contentType: 'image/jpeg',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(_input());
    registerFallbackValue(_upload());
  });

  group('CreateListingCubit.submit', () {
    late _MockCreateRepo createRepo;
    late _MockImageRepo imageRepo;
    late CreateListingCubit cubit;

    setUp(() {
      createRepo = _MockCreateRepo();
      imageRepo = _MockImageRepo();
      cubit = CreateListingCubit(
        createListing: CreateListing(createRepo),
        uploadListingCoverImage: UploadListingCoverImage(imageRepo),
      );
    });

    tearDown(() => cubit.close());

    blocTest<CreateListingCubit, CreateListingState>(
      'without cover image, inserts the listing as-is',
      setUp: () {
        when(() => createRepo.create(any())).thenAnswer(
          (_) async => Success(_listing(null)),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(_input()),
      expect: () => [
        const CreateListingState.submitting(),
        CreateListingState.success(_listing(null)),
      ],
      verify: (_) {
        verifyNever(() => imageRepo.uploadCover(any()));
        final captured = verify(() => createRepo.create(captureAny())).captured;
        expect((captured.single as NewListingInput).coverImageUrl, isNull);
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'with cover image, uploads first and passes public URL to insert',
      setUp: () {
        when(() => imageRepo.uploadCover(any())).thenAnswer(
          (_) async => const Success('https://cdn.example.com/cover.jpg'),
        );
        when(() => createRepo.create(any())).thenAnswer(
          (_) async => Success(_listing('https://cdn.example.com/cover.jpg')),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(_input(), coverImage: _upload()),
      expect: () => [
        const CreateListingState.submitting(),
        CreateListingState.success(_listing('https://cdn.example.com/cover.jpg')),
      ],
      verify: (_) {
        verify(() => imageRepo.uploadCover(any())).called(1);
        final captured = verify(() => createRepo.create(captureAny())).captured;
        expect(
          (captured.single as NewListingInput).coverImageUrl,
          'https://cdn.example.com/cover.jpg',
        );
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'if upload fails, listing insert is NOT called and a friendly '
      'cover-photo message is emitted',
      setUp: () {
        when(() => imageRepo.uploadCover(any())).thenAnswer(
          (_) async => const FailureResult(ServerFailure(
            'new row violates row-level security policy',
          )),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(_input(), coverImage: _upload()),
      expect: () => const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.upload),
      ],
      verify: (_) {
        verifyNever(() => createRepo.create(any()));
      },
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'if insert fails after a successful upload, emits the create '
      'failure kind so the widget can render a localized message',
      setUp: () {
        when(() => imageRepo.uploadCover(any())).thenAnswer(
          (_) async => const Success('https://cdn.example.com/cover.jpg'),
        );
        when(() => createRepo.create(any())).thenAnswer(
          (_) async => const FailureResult(ServerFailure('db down')),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(_input(), coverImage: _upload()),
      expect: () => const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.create),
      ],
    );

    blocTest<CreateListingCubit, CreateListingState>(
      'no-cover path insert failure also emits the create failure kind',
      setUp: () {
        when(() => createRepo.create(any())).thenAnswer(
          (_) async => const FailureResult(UnknownFailure('boom')),
        );
      },
      build: () => cubit,
      act: (c) => c.submit(_input()),
      expect: () => const [
        CreateListingState.submitting(),
        CreateListingState.failure(CreateListingFailureKind.create),
      ],
      verify: (_) {
        verifyNever(() => imageRepo.uploadCover(any()));
      },
    );
  });
}
