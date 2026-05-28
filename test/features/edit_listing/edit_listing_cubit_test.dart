import 'dart:async';
import 'dart:typed_data';

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/domain/entities/cover_image_upload.dart';
import 'package:carzon/features/create_listing/domain/repositories/create_listing_repository.dart';
import 'package:carzon/features/create_listing/domain/entities/uploaded_listing_image.dart';
import 'package:carzon/features/create_listing/domain/usecases/delete_uploaded_listing_images_best_effort.dart';
import 'package:carzon/features/create_listing/domain/usecases/upload_listing_images_sequential.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_lookup_result.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_report_status.dart';
import 'package:carzon/features/edit_listing/domain/entities/owner_listing_vin_source_result.dart';
import 'package:carzon/features/edit_listing/domain/usecases/get_owner_listing_vin_for_edit.dart';
import 'package:carzon/features/edit_listing/domain/usecases/get_owner_listing_vin_report_status_for_edit.dart';
import 'package:carzon/features/edit_listing/domain/usecases/get_owner_listing_vin_source_results_for_edit.dart';
import 'package:carzon/features/edit_listing/domain/repositories/edit_listing_repository.dart';
import 'package:carzon/features/edit_listing/domain/usecases/replace_listing_images.dart';
import 'package:carzon/features/edit_listing/domain/usecases/update_listing_details_v2.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_cubit.dart';
import 'package:carzon/features/edit_listing/presentation/bloc/edit_listing_state.dart';
import 'package:carzon/features/edit_listing/presentation/models/edit_listing_gallery_slot.dart';
import 'package:carzon/features/edit_listing/presentation/utils/edit_listing_gallery_initializer.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_image.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_by_id.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_images.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

class _MockEditListingRepository extends Mock
    implements EditListingRepository {}

class _MockImageRepository extends Mock implements ListingImageRepository {}

Listing _seed({
  String id = 'l1',
  String? coverImageUrl,
  String make = 'Volkswagen',
  int year = 2016,
  ListingCurrency currency = ListingCurrency.eur,
}) => Listing(
  id: id,
  title: 'VW Golf',
  make: make,
  model: 'Golf',
  year: year,
  priceEur: 8900,
  priceCurrency: currency,
  mileageKm: 120000,
  type: ListingType.sale,
  city: 'Chișinău',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 4, 1),
  status: ListingStatus.active,
  sellerId: 's1',
  contactPhone: '+373 690 00001',
  telegramUsername: null,
  whatsappEnabled: false,
  coverImageUrl: coverImageUrl,
  vinStatus: ListingVinStatus.notProvided,
);

ListingImage _img(
  String id,
  String url, {
  int position = 0,
  String? storagePath,
}) => ListingImage(
  id: id,
  listingId: 'l1',
  publicUrl: url,
  storagePath: storagePath,
  position: position,
  createdAt: DateTime.utc(2026, 5, 1),
);

EditListingInput _input(Listing seed, {ListingCurrency? currency}) =>
    EditListingInput(
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
      priceCurrency: currency ?? seed.priceCurrency,
    );

CoverImageUpload _upload({Uint8List? bytes}) => CoverImageUpload(
  sellerId: 's1',
  bytes: bytes ?? Uint8List.fromList([1, 2, 3, 4]),
  contentType: 'image/jpeg',
);

void main() {
  late _MockListingsRepository listingsRepo;
  late _MockEditListingRepository editRepo;
  late _MockImageRepository imageRepo;
  late UploadListingImagesSequential uploadSeq;
  late DeleteUploadedListingImagesBestEffort deleteBatch;
  late EditListingCubit cubit;

  EditListingCubit build() => EditListingCubit(
    getListingById: GetListingById(listingsRepo),
    getListingImages: GetListingImages(listingsRepo),
    getOwnerListingVinForEdit: GetOwnerListingVinForEdit(editRepo),
    getOwnerListingVinReportStatusForEdit:
        GetOwnerListingVinReportStatusForEdit(editRepo),
    getOwnerListingVinSourceResultsForEdit:
        GetOwnerListingVinSourceResultsForEdit(editRepo),
    updateListingDetailsV2: UpdateListingDetailsV2(editRepo),
    replaceListingImages: ReplaceListingImages(editRepo),
    uploadListingImagesSequential: uploadSeq,
    deleteUploadedListingImagesBestEffort: deleteBatch,
    listingImageRepository: imageRepo,
  );

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
        priceCurrency: ListingCurrency.eur,
      ),
    );
    registerFallbackValue(
      ListingImage(
        id: 'fb-i',
        listingId: 'fb-l',
        publicUrl: 'https://example.com/fb.jpg',
        position: 0,
        createdAt: DateTime.utc(2026, 1, 1),
      ),
    );
    registerFallbackValue(_upload());
    registerFallbackValue(
      EditListingGalleryRemoteSlot.legacyCover('https://x/fallback.jpg'),
    );
  });

  setUp(() {
    listingsRepo = _MockListingsRepository();
    editRepo = _MockEditListingRepository();
    imageRepo = _MockImageRepository();
    uploadSeq = UploadListingImagesSequential(imageRepo);
    deleteBatch = DeleteUploadedListingImagesBestEffort(imageRepo);

    when(
      () => listingsRepo.getListingImages(any()),
    ).thenAnswer((_) async => const Success(<ListingImage>[]));

    when(() => listingsRepo.fetchBuyerVinReportSources(any())).thenAnswer(
      (_) async => const Success(BuyerListingVinReportLookupResult()),
    );

    when(
      () => editRepo.fetchOwnerVin(any()),
    ).thenAnswer((_) async => const Success(OwnerListingVinLookupResult()));

    when(() => editRepo.fetchOwnerVinReportStatus(any())).thenAnswer(
      (_) async => const Success(OwnerListingVinReportLookupResult()),
    );

    when(() => editRepo.fetchOwnerVinSourceResults(any())).thenAnswer(
      (_) async => const Success(OwnerListingVinSourceResultsLookupResult()),
    );

    when(
      () => imageRepo.deleteByPublicUrl(
        publicUrl: any(named: 'publicUrl'),
        sellerId: any(named: 'sellerId'),
      ),
    ).thenAnswer((_) async => const Success(null));

    when(
      () => imageRepo.deleteUploadedBatchBestEffort(
        images: any(named: 'images'),
        sellerId: any(named: 'sellerId'),
      ),
    ).thenAnswer((_) async => const Success(null));

    when(() => imageRepo.uploadSequential(any())).thenAnswer((
      invocation,
    ) async {
      final list =
          invocation.positionalArguments.single as List<CoverImageUpload>;
      final out = <UploadedListingImage>[
        for (var i = 0; i < list.length; i++)
          UploadedListingImage(
            publicUrl: 'https://cdn/mock${i + 1}.jpg',
            storagePath: 'sp$i',
          ),
      ];
      return Success(out);
    });

    cubit = build();
  });

  tearDown(() => cubit.close());

  group('load', () {
    blocTest<EditListingCubit, EditListingState>(
      'emits loading then ready with the fetched listing on success',
      setUp: () {
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(_seed()));
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed();
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        );
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: const <ListingImage>[],
            galleryLoadSucceeded: true,
            initialGallerySlots: initial,
          ),
        ];
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'ready includes ordered listing rows in initialGallerySlots',
      setUp: () {
        final a = _img('i0', 'https://x/0.jpg', position: 0, storagePath: 'p0');
        final b = _img('i1', 'https://x/1.jpg', position: 1, storagePath: 'p1');
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(_seed()));
        when(
          () => listingsRepo.getListingImages('l1'),
        ).thenAnswer((_) async => Success(<ListingImage>[a, b]));
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed();
        final a = _img('i0', 'https://x/0.jpg', position: 0, storagePath: 'p0');
        final b = _img('i1', 'https://x/1.jpg', position: 1, storagePath: 'p1');
        final imgs = [a, b];
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: imgs,
          galleryLoadSucceeded: true,
        );
        expect(initial.length, 2);
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: imgs,
            galleryLoadSucceeded: true,
            initialGallerySlots: initial,
          ),
        ];
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'empty listing_images + cover uses legacy-cover initial slot',
      setUp: () {
        final listing = _seed(coverImageUrl: 'https://cdn/cover-only.jpg');
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(listing));
        when(
          () => listingsRepo.getListingImages('l1'),
        ).thenAnswer((_) async => const Success(<ListingImage>[]));
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed(coverImageUrl: 'https://cdn/cover-only.jpg');
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        );
        expect(initial.single, isA<EditListingGalleryRemoteSlot>());
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: const <ListingImage>[],
            galleryLoadSucceeded: true,
            initialGallerySlots: initial,
          ),
        ];
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'gallery fetch failure disables replace flag and clears editable slots',
      setUp: () {
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(_seed()));
        when(
          () => listingsRepo.getListingImages('l1'),
        ).thenAnswer((_) async => const FailureResult(ServerFailure('boom')));
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed();
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: const <ListingImage>[],
            galleryLoadSucceeded: false,
            initialGallerySlots: const <EditListingGallerySlot>[],
          ),
        ];
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'ready with ownerVinReportLookupFailed when VIN report RPC yields fetchFailed',
      setUp: () {
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(_seed()));
        when(() => editRepo.fetchOwnerVinReportStatus('l1')).thenAnswer(
          (_) async => const Success(
            OwnerListingVinReportLookupResult(fetchFailed: true),
          ),
        );
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed();
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        );
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: const <ListingImage>[],
            galleryLoadSucceeded: true,
            initialGallerySlots: initial,
            ownerVinReportLookupFailed: true,
          ),
        ];
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'ready with ownerVinReportLookupFailed when VIN report usecase returns failure',
      setUp: () {
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(_seed()));
        when(() => editRepo.fetchOwnerVinReportStatus('l1')).thenAnswer(
          (_) async => const FailureResult(ServerFailure('report rpc')),
        );
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed();
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        );
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: const <ListingImage>[],
            galleryLoadSucceeded: true,
            initialGallerySlots: initial,
            ownerVinReportLookupFailed: true,
          ),
        ];
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'ready with ownerVinSourceResultsLookupFailed when source-results repo fails',
      setUp: () {
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(_seed()));
        when(() => editRepo.fetchOwnerVinSourceResults('l1')).thenAnswer(
          (_) async => const FailureResult(ServerFailure('source results rpc')),
        );
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed();
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        );
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: const <ListingImage>[],
            galleryLoadSucceeded: true,
            initialGallerySlots: initial,
            ownerVinSourceResultsLookupFailed: true,
          ),
        ];
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'ready carries NHTSA source rows when repo succeeds',
      setUp: () {
        when(
          () => listingsRepo.getById('l1'),
        ).thenAnswer((_) async => Success(_seed()));
        when(() => editRepo.fetchOwnerVinSourceResults('l1')).thenAnswer(
          (_) async => Success(
            OwnerListingVinSourceResultsLookupResult(
              results: [
                OwnerListingVinSourceResult(
                  sourceId: 'nhtsa_vpic',
                  statusRaw: 'succeeded',
                  normalizedSummary: const {'make': 'Subaru'},
                ),
              ],
            ),
          ),
        );
      },
      build: () => cubit,
      act: (c) => c.load('l1'),
      expect: () {
        final listing = _seed();
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        );
        return [
          const EditListingState.loading(),
          EditListingState.ready(
            listing,
            listingGalleryImages: const <ListingImage>[],
            galleryLoadSucceeded: true,
            initialGallerySlots: initial,
            ownerVinSourceResults: [
              OwnerListingVinSourceResult(
                sourceId: 'nhtsa_vpic',
                statusRaw: 'succeeded',
                normalizedSummary: const {'make': 'Subaru'},
              ),
            ],
          ),
        ];
      },
    );
  });

  group('save', () {
    test('is a no-op before load', () async {
      await cubit.save(input: _input(_seed()), galleryDraft: []);
      verifyNever(() => editRepo.updateDetailsV2(any()));
      expect(cubit.state, const EditListingState.initial());
    });

    blocTest<EditListingCubit, EditListingState>(
      'details-only save calls updateDetailsV2 and skips replace/payload',
      setUp: () {
        final updated = _seed().copyWithForTest(priceEur: 7777);
        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => Success(updated));
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        );
        return EditListingState.ready(
          listing,
          listingGalleryImages: const <ListingImage>[],
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
        );
      },
      act: (c) => c.save(
        input: _input(_seed()),
        galleryDraft: buildInitialEditListingGallerySlots(
          listing: _seed(),
          prefetchedGallery: const <ListingImage>[],
          galleryLoadSucceeded: true,
        ),
      ),
      verify: (_) {
        verify(() => editRepo.updateDetailsV2(any())).called(1);
        verifyNever(
          () => editRepo.replaceListingImages(
            listingId: any(named: 'listingId'),
            imagePublicUrls: any(named: 'imagePublicUrls'),
            storagePaths: any(named: 'storagePaths'),
          ),
        );
        verifyNever(() => imageRepo.uploadSequential(any()));
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'remote reorder triggers replaceListingImages without uploads',
      setUp: () {
        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => Success(_seed()));
        when(
          () => editRepo.replaceListingImages(
            listingId: any(named: 'listingId'),
            imagePublicUrls: any(named: 'imagePublicUrls'),
            storagePaths: any(named: 'storagePaths'),
          ),
        ).thenAnswer((_) async => Success(_seed()));
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        final imgs = [
          _img('i0', 'https://x/a.jpg', position: 0),
          _img('i1', 'https://x/b.jpg', position: 1),
        ];
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: imgs,
          galleryLoadSucceeded: true,
        );
        return EditListingState.ready(
          listing,
          listingGalleryImages: imgs,
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
        );
      },
      act: (c) {
        final reordered = <EditListingGallerySlot>[
          EditListingGalleryRemoteSlot.fromRow(
            _img('i1', 'https://x/b.jpg', position: 1, storagePath: 'pb'),
          ),
          EditListingGalleryRemoteSlot.fromRow(
            _img('i0', 'https://x/a.jpg', position: 0, storagePath: 'pa'),
          ),
        ];
        return c.save(input: _input(_seed()), galleryDraft: reordered);
      },
      verify: (_) {
        verify(() => editRepo.updateDetailsV2(any())).called(1);
        verify(
          () => editRepo.replaceListingImages(
            listingId: 'l1',
            imagePublicUrls: ['https://x/b.jpg', 'https://x/a.jpg'],
            storagePaths: ['pb', 'pa'],
          ),
        ).called(1);
        verifyNever(() => imageRepo.uploadSequential(any()));
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'sequential upload then details then replace',
      setUp: () {
        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => Success(_seed()));
        when(
          () => editRepo.replaceListingImages(
            listingId: any(named: 'listingId'),
            imagePublicUrls: any(named: 'imagePublicUrls'),
            storagePaths: any(named: 'storagePaths'),
          ),
        ).thenAnswer((_) async => Success(_seed()));

        var n = 0;
        when(() => imageRepo.uploadSequential(any())).thenAnswer((inv) async {
          final uploads =
              inv.positionalArguments.single as List<CoverImageUpload>;
          expect(uploads, hasLength(1));
          n++;
          return Success([
            UploadedListingImage(
              publicUrl: 'https://cdn/new$n.jpg',
              storagePath: 'sn',
            ),
          ]);
        });
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        final row = _img('i0', 'https://x/existing.jpg');
        final imgs = [row];
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: imgs,
          galleryLoadSucceeded: true,
        );
        return EditListingState.ready(
          listing,
          listingGalleryImages: imgs,
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
        );
      },
      act: (c) {
        final draft = <EditListingGallerySlot>[
          EditListingGalleryRemoteSlot.fromRow(
            _img('i0', 'https://x/existing.jpg'),
          ),
          EditListingGalleryLocalSlot(upload: _upload()),
        ];
        return c.save(input: _input(_seed()), galleryDraft: draft);
      },
      verify: (_) {
        verify(() => imageRepo.uploadSequential(any())).called(1);
        verify(() => editRepo.updateDetailsV2(any())).called(1);
        verify(
          () => editRepo.replaceListingImages(
            listingId: 'l1',
            imagePublicUrls: ['https://x/existing.jpg', 'https://cdn/new1.jpg'],
            storagePaths: any(named: 'storagePaths'),
          ),
        ).called(1);
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'upload failure prevents details/replace RPCs',
      setUp: () {
        when(
          () => imageRepo.uploadSequential(any()),
        ).thenAnswer((_) async => const FailureResult(ServerFailure('up')));
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        return EditListingState.ready(
          listing,
          listingGalleryImages: const <ListingImage>[],
          galleryLoadSucceeded: true,
          initialGallerySlots: <EditListingGallerySlot>[],
        );
      },
      act: (c) => c.save(
        input: _input(_seed()),
        galleryDraft: [EditListingGalleryLocalSlot(upload: _upload())],
      ),
      verify: (_) {
        verifyNever(() => editRepo.updateDetailsV2(any()));
        verifyNever(
          () => editRepo.replaceListingImages(
            listingId: any(named: 'listingId'),
            imagePublicUrls: any(named: 'imagePublicUrls'),
            storagePaths: any(named: 'storagePaths'),
          ),
        );
        expect(cubit.state.failureKind, EditListingFailureKind.uploadFailed);
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'details failure after uploads triggers deleteUploadedBatchBestEffort',
      setUp: () {
        when(() => imageRepo.uploadSequential(any())).thenAnswer(
          (_) async => Success([
            UploadedListingImage(
              publicUrl: 'https://cdn/orphan.jpg',
              storagePath: null,
            ),
          ]),
        );
        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => const FailureResult(ServerFailure('nope')));
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        return EditListingState.ready(
          listing,
          listingGalleryImages: const [],
          galleryLoadSucceeded: true,
          initialGallerySlots: <EditListingGallerySlot>[],
        );
      },
      act: (c) => c.save(
        input: _input(_seed()),
        galleryDraft: [EditListingGalleryLocalSlot(upload: _upload())],
      ),
      verify: (_) {
        final batch =
            verify(
                  () => imageRepo.deleteUploadedBatchBestEffort(
                    images: captureAny(named: 'images'),
                    sellerId: 's1',
                  ),
                ).captured.single
                as List<UploadedListingImage>;
        expect(batch.single.publicUrl, 'https://cdn/orphan.jpg');
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'replace failure deletes newly uploaded blobs',
      setUp: () {
        when(() => imageRepo.uploadSequential(any())).thenAnswer(
          (_) async => Success([
            const UploadedListingImage(
              publicUrl: 'https://cdn/n.jpg',
              storagePath: 'sn',
            ),
          ]),
        );
        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => Success(_seed()));
        when(
          () => editRepo.replaceListingImages(
            listingId: any(named: 'listingId'),
            imagePublicUrls: any(named: 'imagePublicUrls'),
            storagePaths: any(named: 'storagePaths'),
          ),
        ).thenAnswer((_) async => const FailureResult(ServerFailure('repl')));
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        final imgs = [_img('i0', 'https://x/keep.jpg')];
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: imgs,
          galleryLoadSucceeded: true,
        );
        return EditListingState.ready(
          listing,
          listingGalleryImages: imgs,
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
        );
      },
      act: (c) {
        final draft = <EditListingGallerySlot>[
          EditListingGalleryRemoteSlot.fromRow(
            _img('i0', 'https://x/keep.jpg'),
          ),
          EditListingGalleryLocalSlot(upload: _upload()),
        ];
        return c.save(input: _input(_seed()), galleryDraft: draft);
      },
      verify: (_) {
        verify(
          () => imageRepo.deleteUploadedBatchBestEffort(
            images: any(named: 'images'),
            sellerId: 's1',
          ),
        ).called(1);
        expect(
          cubit.state.failureKind,
          EditListingFailureKind.galleryReplaceFailed,
        );
        expect(cubit.state.status, EditListingStatus.failure);
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'after successful replace, dropped remote urls are deleted best-effort',
      setUp: () {
        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => Success(_seed()));
        when(
          () => editRepo.replaceListingImages(
            listingId: any(named: 'listingId'),
            imagePublicUrls: any(named: 'imagePublicUrls'),
            storagePaths: any(named: 'storagePaths'),
          ),
        ).thenAnswer((_) async => Success(_seed()));
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        final imgs = [
          _img('i0', 'https://x/a.jpg', position: 0),
          _img('i1', 'https://x/b.jpg', position: 1),
        ];
        final initial = buildInitialEditListingGallerySlots(
          listing: listing,
          prefetchedGallery: imgs,
          galleryLoadSucceeded: true,
        );
        return EditListingState.ready(
          listing,
          listingGalleryImages: imgs,
          galleryLoadSucceeded: true,
          initialGallerySlots: initial,
        );
      },
      act: (c) {
        final draft = <EditListingGallerySlot>[
          EditListingGalleryRemoteSlot.fromRow(_img('i0', 'https://x/a.jpg')),
        ];
        return c.save(input: _input(_seed()), galleryDraft: draft);
      },
      verify: (_) {
        verify(
          () => imageRepo.deleteByPublicUrl(
            publicUrl: 'https://x/b.jpg',
            sellerId: 's1',
          ),
        ).called(1);
      },
    );

    blocTest<EditListingCubit, EditListingState>(
      'when gallery load failed, identical empty draft skips replace RPC',
      setUp: () {
        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => Success(_seed()));
      },
      build: () => cubit,
      seed: () {
        final listing = _seed();
        return EditListingState.ready(
          listing,
          listingGalleryImages: const [],
          galleryLoadSucceeded: false,
          initialGallerySlots: <EditListingGallerySlot>[],
        );
      },
      act: (c) => c.save(
        input: _input(_seed()),
        galleryDraft: <EditListingGallerySlot>[],
      ),
      verify: (_) {
        verifyNever(
          () => editRepo.replaceListingImages(
            listingId: any(named: 'listingId'),
            imagePublicUrls: any(named: 'imagePublicUrls'),
            storagePaths: any(named: 'storagePaths'),
          ),
        );
      },
    );

    test('second synchronous save during upload awaits is ignored '
        '(single upload batch)', () async {
      final listing = _seed();
      cubit.emit(
        EditListingState.ready(
          listing,
          listingGalleryImages: const [],
          galleryLoadSucceeded: true,
          initialGallerySlots: <EditListingGallerySlot>[],
        ),
      );

      final gate = Completer<void>();
      when(() => imageRepo.uploadSequential(any())).thenAnswer((_) async {
        await gate.future;
        return const Success([
          UploadedListingImage(publicUrl: 'https://cdn/n.jpg'),
        ]);
      });
      when(
        () => editRepo.updateDetailsV2(any()),
      ).thenAnswer((_) async => Success(listing));
      when(
        () => editRepo.replaceListingImages(
          listingId: any(named: 'listingId'),
          imagePublicUrls: any(named: 'imagePublicUrls'),
          storagePaths: any(named: 'storagePaths'),
        ),
      ).thenAnswer((_) async => Success(listing));

      final draft = <EditListingGallerySlot>[
        EditListingGalleryLocalSlot(upload: _upload()),
      ];

      final first = cubit.save(input: _input(listing), galleryDraft: draft);
      await Future<void>.value();
      expect(cubit.state.status, EditListingStatus.submitting);

      final dup = cubit.save(input: _input(listing), galleryDraft: draft);
      gate.complete();

      await first;
      await dup;

      verify(() => imageRepo.uploadSequential(any())).called(1);
      verify(() => editRepo.updateDetailsV2(any())).called(1);
      verify(
        () => editRepo.replaceListingImages(
          listingId: 'l1',
          imagePublicUrls: ['https://cdn/n.jpg'],
          storagePaths: any(named: 'storagePaths'),
        ),
      ).called(1);
    });

    test(
      'updateDetailsV2 receives USD currency and custom detail fields',
      () async {
        final listing = _seed(
          make: 'Zaporozhets',
          currency: ListingCurrency.usd,
        );

        cubit.emit(
          EditListingState.ready(
            listing,
            listingGalleryImages: const [],
            galleryLoadSucceeded: true,
            initialGallerySlots: <EditListingGallerySlot>[],
          ),
        );

        when(
          () => editRepo.updateDetailsV2(any()),
        ).thenAnswer((_) async => Success(listing.copyWithForTest(year: 2015)));

        final input = EditListingInput(
          listingId: listing.id,
          title: listing.title,
          make: listing.make,
          model: listing.model,
          year: 2015,
          priceEur: 5555,
          mileageKm: listing.mileageKm,
          type: listing.type,
          city: listing.city,
          marketRegion: listing.marketRegion,
          contactPhone: listing.contactPhone!,
          telegramUsername: listing.telegramUsername,
          whatsappEnabled: listing.whatsappEnabled,
          priceCurrency: ListingCurrency.usd,
        );

        await cubit.save(
          input: input,
          galleryDraft: <EditListingGallerySlot>[],
        );

        final cap = verify(
          () => editRepo.updateDetailsV2(captureAny()),
        ).captured.single;
        expect(cap, isA<EditListingInput>());
        final capturedInput = cap as EditListingInput;
        expect(capturedInput.priceCurrency, ListingCurrency.usd);
        expect(capturedInput.year, 2015);
        expect(capturedInput.make, 'Zaporozhets');
      },
    );

    test('updateDetailsV2 receives body type when provided', () async {
      final listing = _seed();

      cubit.emit(
        EditListingState.ready(
          listing,
          listingGalleryImages: const [],
          galleryLoadSucceeded: true,
          initialGallerySlots: <EditListingGallerySlot>[],
        ),
      );

      when(
        () => editRepo.updateDetailsV2(any()),
      ).thenAnswer((_) async => Success(listing));

      final input = EditListingInput(
        listingId: listing.id,
        title: listing.title,
        make: listing.make,
        model: listing.model,
        year: listing.year,
        priceEur: listing.priceEur,
        mileageKm: listing.mileageKm,
        type: listing.type,
        city: listing.city,
        marketRegion: listing.marketRegion,
        contactPhone: listing.contactPhone!,
        telegramUsername: listing.telegramUsername,
        whatsappEnabled: listing.whatsappEnabled,
        priceCurrency: listing.priceCurrency,
        bodyType: ListingBodyType.pickup,
      );

      await cubit.save(input: input, galleryDraft: <EditListingGallerySlot>[]);

      final captured =
          verify(() => editRepo.updateDetailsV2(captureAny())).captured.single
              as EditListingInput;
      expect(captured.bodyType, ListingBodyType.pickup);
    });
  });

  group('buildReplaceListingGalleryPayload', () {
    test('pairs locals with staged uploads in order', () {
      final out = EditListingCubit.buildReplaceListingGalleryPayload(
        [
          EditListingGalleryRemoteSlot.legacyCover('https://r/1.jpg'),
          EditListingGalleryLocalSlot(upload: _upload()),
        ],
        [
          const UploadedListingImage(
            publicUrl: 'https://u/2.jpg',
            storagePath: 'sp2',
          ),
        ],
      );
      expect(out.urls, ['https://r/1.jpg', 'https://u/2.jpg']);
      expect(out.paths, [null, 'sp2']);
    });
  });
}

extension _ListingTestCopy on Listing {
  Listing copyWithForTest({
    num? priceEur,
    ListingCurrency? priceCurrency,
    String? make,
    int? year,
    ListingVinStatus? vinStatus,
  }) => Listing(
    id: id,
    title: title,
    make: make ?? this.make,
    model: model,
    year: year ?? this.year,
    priceEur: priceEur ?? this.priceEur,
    priceCurrency: priceCurrency ?? this.priceCurrency,
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
    vinStatus: vinStatus ?? this.vinStatus,
  );
}
