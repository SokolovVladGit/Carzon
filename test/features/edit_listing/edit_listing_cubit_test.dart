import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_cover_image.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/edit_listing/domain/repositories/edit_listing_repository.dart';
import 'package:carzon/features/edit_listing/domain/usecases/update_listing_cover_image.dart';
import 'package:carzon/features/edit_listing/domain/usecases/update_listing_details.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_by_id.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

class _MockEditListingRepository extends Mock
    implements EditListingRepository {}

class _MockImageRepository extends Mock implements ListingImageRepository {}

Listing _seed({
  String id = 'l1',
  ListingStatus status = ListingStatus.active,
  String? coverImageUrl,
}) =>
    Listing(
      id: id,
      title: 'VW Golf',
      make: 'Volkswagen',
      model: 'Golf',
      year: 2016,
      priceEur: 8900,
      mileageKm: 120000,
      type: ListingType.sale,
      city: 'Chișinău',
      marketRegion: MarketRegion.moldova,
      createdAt: DateTime.utc(2026, 4, 1),
      status: status,
      sellerId: 's1',
      contactPhone: '+373 690 00001',
      telegramUsername: null,
      whatsappEnabled: false,
      coverImageUrl: coverImageUrl,
    );

EditListingInput _input(Listing seed) => EditListingInput(
      listingId: seed.id,
      title: seed.title,
      make: seed.make,
      model: seed.model,
      year: seed.year,
      priceEur: seed.priceEur,
      mileageKm: seed.mileageKm,
      type: seed.type,
      city: seed.city,
      marketRegion: seed.marketRegion,
      contactPhone: seed.contactPhone ?? '+373 690 00001',
      telegramUsername: seed.telegramUsername,
      whatsappEnabled: seed.whatsappEnabled,
    );

CoverImageUpload _upload({String sellerId = 's1'}) => CoverImageUpload(
      sellerId: sellerId,
      bytes: Uint8List.fromList([1, 2, 3, 4]),
      contentType: 'image/jpeg',
    );

void main() {
  setUpAll(() {
    registerFallbackValue(
      EditListingInput(
        listingId: 'x',
        title: 'x',
        make: 'x',
        model: 'x',
        year: 2020,
        priceEur: 1,
        mileageKm: 1,
        type: ListingType.sale,
        city: 'x',
        marketRegion: MarketRegion.moldova,
        contactPhone: '+373 000 00000',
      ),
    );
    registerFallbackValue(_upload());
  });

  late _MockListingsRepository listingsRepo;
  late _MockEditListingRepository editRepo;
  late _MockImageRepository imageRepo;
  late EditListingCubit cubit;

  EditListingCubit build() => EditListingCubit(
        getListingById: GetListingById(listingsRepo),
        updateListingDetails: UpdateListingDetails(editRepo),
        updateListingCoverImage: UpdateListingCoverImage(editRepo),
        uploadListingCoverImage: UploadListingCoverImage(imageRepo),
        listingImageRepository: imageRepo,
      );

  setUp(() {
    listingsRepo = _MockListingsRepository();
    editRepo = _MockEditListingRepository();
    imageRepo = _MockImageRepository();
    // Image repo default stubs — each test can override when it
    // needs different behavior. `deleteByPublicUrl` is best-effort
    // and must never flip a successful save into a failure.
    when(() => imageRepo.deleteByPublicUrl(
          publicUrl: any(named: 'publicUrl'),
          sellerId: any(named: 'sellerId'),
        )).thenAnswer((_) async => const Success(null));
    cubit = build();
  });

  tearDown(() => cubit.close());

  group('load', () {
    blocTest<EditListingCubit, EditListingState>(
      'emits loading then ready with the fetched listing on success',
      setUp: () {
        when(() => listingsRepo.getById('l1'))
            .thenAnswer((_) async => Success(_seed()));
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () => [
        const EditListingState.loading(),
        EditListingState.ready(_seed()),
      ],
    );

    blocTest<EditListingCubit, EditListingState>(
      'emits loading then loadFailure with a friendly message on failure',
      setUp: () {
        when(() => listingsRepo.getById('l1')).thenAnswer(
          (_) async => const FailureResult(ServerFailure('boom')),
        );
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () => [
        const EditListingState.loading(),
        const EditListingState.loadFailure(),
      ],
    );
  });

  group('save (details only)', () {
    test('is a no-op when called before a listing has been loaded', () async {
      await cubit.save(_input(_seed()));
      expect(cubit.state, const EditListingState.initial());
      verifyNever(() => editRepo.updateDetails(any()));
    });

    blocTest<EditListingCubit, EditListingState>(
      'emits submitting then success with the refreshed listing on success',
      setUp: () {
        final updated = _seed().copyWithForTest(priceEur: 7777);
        when(() => editRepo.updateDetails(any()))
            .thenAnswer((_) async => Success(updated));
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed()),
      act: (c) => c.save(_input(_seed())),
      expect: () => [
        EditListingState.submitting(_seed()),
        EditListingState.success(_seed().copyWithForTest(priceEur: 7777)),
      ],
      verify: (_) {
        verify(() => editRepo.updateDetails(any())).called(1);
        verifyNever(() => editRepo.updateCoverImage(
              listingId: any(named: 'listingId'),
              coverImageUrl: any(named: 'coverImageUrl'),
            ));
        verifyNever(() => imageRepo.uploadCover(any()));
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'maps owner/permission failures to the "not allowed" friendly message',
      setUp: () {
        when(() => editRepo.updateDetails(any())).thenAnswer(
          (_) async => const FailureResult(
            ServerFailure('listing not found or not owned by caller'),
          ),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed()),
      act: (c) => c.save(_input(_seed())),
      expect: () => [
        EditListingState.submitting(_seed()),
        EditListingState.saveFailure(
          _seed(),
          EditListingFailureKind.notAllowed,
        ),
      ],
    );

    blocTest<EditListingCubit, EditListingState>(
      'maps validation failures to the "check the listing details" message',
      setUp: () {
        when(() => editRepo.updateDetails(any())).thenAnswer(
          (_) async => const FailureResult(
            ServerFailure('invalid contact_phone'),
          ),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed()),
      act: (c) => c.save(_input(_seed())),
      expect: () => [
        EditListingState.submitting(_seed()),
        EditListingState.saveFailure(
          _seed(),
          EditListingFailureKind.invalidDetails,
        ),
      ],
    );

    blocTest<EditListingCubit, EditListingState>(
      'maps unknown failures to the fallback message',
      setUp: () {
        when(() => editRepo.updateDetails(any())).thenAnswer(
          (_) async => const FailureResult(UnknownFailure('weird')),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed()),
      act: (c) => c.save(_input(_seed())),
      expect: () => [
        EditListingState.submitting(_seed()),
        EditListingState.saveFailure(
          _seed(),
          EditListingFailureKind.detailsFailed,
        ),
      ],
    );
  });

  group('cover staging', () {
    Future<void> loadReady({String? coverUrl}) async {
      when(() => listingsRepo.getById('l1')).thenAnswer(
        (_) async => Success(_seed(coverImageUrl: coverUrl)),
      );
      await cubit.load('l1');
    }

    test('stageCoverReplacement sets replacement and clears removal',
        () async {
      await loadReady();
      cubit.stageCoverRemoval();
      expect(cubit.state.pendingCoverRemoval, isTrue);
      cubit.stageCoverReplacement(_upload());
      expect(cubit.state.pendingCoverReplacement, _upload());
      expect(cubit.state.pendingCoverRemoval, isFalse);
    });

    test('stageCoverRemoval sets removal flag and clears any replacement',
        () async {
      await loadReady();
      cubit.stageCoverReplacement(_upload());
      cubit.stageCoverRemoval();
      expect(cubit.state.pendingCoverReplacement, isNull);
      expect(cubit.state.pendingCoverRemoval, isTrue);
    });

    test('clearCoverChange resets both flags', () async {
      await loadReady();
      cubit.stageCoverReplacement(_upload());
      cubit.clearCoverChange();
      expect(cubit.state.pendingCoverReplacement, isNull);
      expect(cubit.state.pendingCoverRemoval, isFalse);
      cubit.stageCoverRemoval();
      cubit.clearCoverChange();
      expect(cubit.state.pendingCoverReplacement, isNull);
      expect(cubit.state.pendingCoverRemoval, isFalse);
    });

    test('staging methods are no-ops before a listing is loaded', () async {
      cubit.stageCoverReplacement(_upload());
      cubit.stageCoverRemoval();
      cubit.clearCoverChange();
      expect(cubit.state, const EditListingState.initial());
    });
  });

  group('save with cover replacement', () {
    const newUrl = 'https://cdn.example.com/new.jpg';
    const oldUrl = 'https://cdn.example.com/old.jpg';

    blocTest<EditListingCubit, EditListingState>(
      'uploads new image, calls cover RPC with the public URL, and '
      'deletes the old cover object best-effort',
      setUp: () {
        when(() => editRepo.updateDetails(any()))
            .thenAnswer((_) async => Success(_seed(coverImageUrl: oldUrl)));
        when(() => imageRepo.uploadCover(any()))
            .thenAnswer((_) async => const Success(newUrl));
        when(() => editRepo.updateCoverImage(
              listingId: 'l1',
              coverImageUrl: newUrl,
            )).thenAnswer(
          (_) async => Success(_seed(coverImageUrl: newUrl)),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed(coverImageUrl: oldUrl))
          .copyWith(pendingCoverReplacement: _upload()),
      act: (c) => c.save(_input(_seed(coverImageUrl: oldUrl))),
      verify: (_) {
        verifyInOrder([
          () => editRepo.updateDetails(any()),
          () => imageRepo.uploadCover(any()),
          () => editRepo.updateCoverImage(
                listingId: 'l1',
                coverImageUrl: newUrl,
              ),
          () => imageRepo.deleteByPublicUrl(
                publicUrl: oldUrl,
                sellerId: 's1',
              ),
        ]);
        expect(cubit.state.status, EditListingStatus.success);
        expect(cubit.state.listing?.coverImageUrl, newUrl);
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'skips upload and cover RPC when details update fails',
      setUp: () {
        when(() => editRepo.updateDetails(any())).thenAnswer(
          (_) async => const FailureResult(UnknownFailure('boom')),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed(coverImageUrl: oldUrl))
          .copyWith(pendingCoverReplacement: _upload()),
      act: (c) => c.save(_input(_seed(coverImageUrl: oldUrl))),
      verify: (_) {
        verify(() => editRepo.updateDetails(any())).called(1);
        verifyNever(() => imageRepo.uploadCover(any()));
        verifyNever(() => editRepo.updateCoverImage(
              listingId: any(named: 'listingId'),
              coverImageUrl: any(named: 'coverImageUrl'),
            ));
        verifyNever(() => imageRepo.deleteByPublicUrl(
              publicUrl: any(named: 'publicUrl'),
              sellerId: any(named: 'sellerId'),
            ));
        expect(cubit.state.status, EditListingStatus.failure);
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'surfaces a cover-upload friendly message when upload fails '
      '(details already committed, no cover RPC, no cleanup)',
      setUp: () {
        when(() => editRepo.updateDetails(any()))
            .thenAnswer((_) async => Success(_seed(coverImageUrl: oldUrl)));
        when(() => imageRepo.uploadCover(any())).thenAnswer(
          (_) async => const FailureResult(ServerFailure('storage 4xx')),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed(coverImageUrl: oldUrl))
          .copyWith(pendingCoverReplacement: _upload()),
      act: (c) => c.save(_input(_seed(coverImageUrl: oldUrl))),
      verify: (_) {
        verify(() => imageRepo.uploadCover(any())).called(1);
        verifyNever(() => editRepo.updateCoverImage(
              listingId: any(named: 'listingId'),
              coverImageUrl: any(named: 'coverImageUrl'),
            ));
        verifyNever(() => imageRepo.deleteByPublicUrl(
              publicUrl: any(named: 'publicUrl'),
              sellerId: any(named: 'sellerId'),
            ));
        expect(cubit.state.status, EditListingStatus.failure);
        expect(
          cubit.state.failureKind,
          EditListingFailureKind.uploadFailed,
        );
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'when cover RPC fails after a successful upload, best-effort '
      'deletes the freshly-uploaded orphan and keeps the old URL',
      setUp: () {
        when(() => editRepo.updateDetails(any()))
            .thenAnswer((_) async => Success(_seed(coverImageUrl: oldUrl)));
        when(() => imageRepo.uploadCover(any()))
            .thenAnswer((_) async => const Success(newUrl));
        when(() => editRepo.updateCoverImage(
              listingId: 'l1',
              coverImageUrl: newUrl,
            )).thenAnswer(
          (_) async => const FailureResult(ServerFailure('db down')),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed(coverImageUrl: oldUrl))
          .copyWith(pendingCoverReplacement: _upload()),
      act: (c) => c.save(_input(_seed(coverImageUrl: oldUrl))),
      verify: (_) {
        verifyInOrder([
          () => imageRepo.uploadCover(any()),
          () => editRepo.updateCoverImage(
                listingId: 'l1',
                coverImageUrl: newUrl,
              ),
          () => imageRepo.deleteByPublicUrl(
                publicUrl: newUrl,
                sellerId: 's1',
              ),
        ]);
        // The old URL must NOT be deleted — the DB still points at it.
        verifyNever(() => imageRepo.deleteByPublicUrl(
              publicUrl: oldUrl,
              sellerId: any(named: 'sellerId'),
            ));
        expect(cubit.state.status, EditListingStatus.failure);
        expect(
          cubit.state.failureKind,
          EditListingFailureKind.coverUpdateFailed,
        );
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'when there was no previous cover URL, no cleanup is attempted',
      setUp: () {
        when(() => editRepo.updateDetails(any()))
            .thenAnswer((_) async => Success(_seed()));
        when(() => imageRepo.uploadCover(any()))
            .thenAnswer((_) async => const Success(newUrl));
        when(() => editRepo.updateCoverImage(
              listingId: 'l1',
              coverImageUrl: newUrl,
            )).thenAnswer(
          (_) async => Success(_seed(coverImageUrl: newUrl)),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed())
          .copyWith(pendingCoverReplacement: _upload()),
      act: (c) => c.save(_input(_seed())),
      verify: (_) {
        verifyNever(() => imageRepo.deleteByPublicUrl(
              publicUrl: any(named: 'publicUrl'),
              sellerId: any(named: 'sellerId'),
            ));
        expect(cubit.state.status, EditListingStatus.success);
      },
    );
  });

  group('save with cover removal', () {
    const oldUrl = 'https://cdn.example.com/old.jpg';

    blocTest<EditListingCubit, EditListingState>(
      'calls cover RPC with null and best-effort deletes the old object',
      setUp: () {
        when(() => editRepo.updateDetails(any()))
            .thenAnswer((_) async => Success(_seed(coverImageUrl: oldUrl)));
        when(() => editRepo.updateCoverImage(
              listingId: 'l1',
              coverImageUrl: null,
            )).thenAnswer((_) async => Success(_seed()));
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed(coverImageUrl: oldUrl))
          .copyWith(pendingCoverRemoval: true),
      act: (c) => c.save(_input(_seed(coverImageUrl: oldUrl))),
      verify: (_) {
        verifyInOrder([
          () => editRepo.updateDetails(any()),
          () => editRepo.updateCoverImage(
                listingId: 'l1',
                coverImageUrl: null,
              ),
          () => imageRepo.deleteByPublicUrl(
                publicUrl: oldUrl,
                sellerId: 's1',
              ),
        ]);
        // A removal flow never uploads.
        verifyNever(() => imageRepo.uploadCover(any()));
        expect(cubit.state.status, EditListingStatus.success);
        expect(cubit.state.listing?.coverImageUrl, isNull);
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'surfaces a friendly cover message when the cover RPC fails '
      'and does NOT delete the old object',
      setUp: () {
        when(() => editRepo.updateDetails(any()))
            .thenAnswer((_) async => Success(_seed(coverImageUrl: oldUrl)));
        when(() => editRepo.updateCoverImage(
              listingId: 'l1',
              coverImageUrl: null,
            )).thenAnswer(
          (_) async => const FailureResult(ServerFailure('db down')),
        );
      },
      build: () => cubit,
      seed: () => EditListingState.ready(_seed(coverImageUrl: oldUrl))
          .copyWith(pendingCoverRemoval: true),
      act: (c) => c.save(_input(_seed(coverImageUrl: oldUrl))),
      verify: (_) {
        verifyNever(() => imageRepo.deleteByPublicUrl(
              publicUrl: any(named: 'publicUrl'),
              sellerId: any(named: 'sellerId'),
            ));
        expect(cubit.state.status, EditListingStatus.failure);
        expect(
          cubit.state.failureKind,
          EditListingFailureKind.coverUpdateFailed,
        );
      },
    );
  });
}

extension _ListingTestCopy on Listing {
  Listing copyWithForTest({num? priceEur}) => Listing(
        id: id,
        title: title,
        make: make,
        model: model,
        year: year,
        priceEur: priceEur ?? this.priceEur,
        mileageKm: mileageKm,
        type: type,
        city: city,
        marketRegion: marketRegion,
        createdAt: createdAt,
        status: status,
        coverImageUrl: coverImageUrl,
        sellerId: sellerId,
        contactPhone: contactPhone,
        telegramUsername: telegramUsername,
        whatsappEnabled: whatsappEnabled,
      );
}
