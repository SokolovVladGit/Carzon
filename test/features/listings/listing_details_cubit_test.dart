import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_image.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_by_id.dart';
import 'package:carzon/features/listings/domain/usecases/get_listing_images.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_cubit.dart';
import 'package:carzon/features/listings/presentation/bloc/listing_details_state.dart';
import 'package:carzon/features/messaging/domain/usecases/get_or_create_conversation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetListingById extends Mock implements GetListingById {}

class _MockGetListingImages extends Mock implements GetListingImages {}

class _MockGetOrCreateConversation extends Mock
    implements GetOrCreateConversation {}

Listing _listing({String? cover}) => Listing(
  id: 'l1',
  title: 't',
  make: 'Audi',
  model: 'A4',
  year: 2020,
  priceEur: 1,
  mileageKm: 100,
  type: ListingType.sale,
  city: '',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
  coverImageUrl: cover,
);

void main() {
  late _MockGetListingById getById;
  late _MockGetListingImages getImages;
  late _MockGetOrCreateConversation getOrCreateConversation;

  setUpAll(() => registerFallbackValue(''));

  setUp(() {
    getById = _MockGetListingById();
    getImages = _MockGetListingImages();
    getOrCreateConversation = _MockGetOrCreateConversation();
    reset(getById);
    reset(getImages);
    reset(getOrCreateConversation);
  });

  blocTest<ListingDetailsCubit, ListingDetailsState>(
    'gallery rows drive ordered heroImageUrls after fetchById succeeds',
    setUp: () {
      final listing = _listing(cover: 'https://cdn/c.jpg');
      when(() => getById('l1')).thenAnswer((_) async => Success(listing));
      when(() => getImages('l1')).thenAnswer(
        (_) async => Success([
          ListingImage(
            id: 'i2',
            listingId: 'l1',
            publicUrl: 'https://cdn/b.jpg',
            position: 2,
            createdAt: DateTime.utc(2026, 1, 4),
          ),
          ListingImage(
            id: 'i0',
            listingId: 'l1',
            publicUrl: 'https://cdn/a.jpg',
            position: 0,
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        ]),
      );
    },
    build: () => ListingDetailsCubit(
      getListingById: getById,
      getListingImages: getImages,
      getOrCreateConversation: getOrCreateConversation,
    ),
    act: (c) => c.load('l1'),
    expect: () => [
      const ListingDetailsState.loading(),
      ListingDetailsState.success(
        _listing(cover: 'https://cdn/c.jpg'),
        heroImageUrls: const ['https://cdn/a.jpg', 'https://cdn/b.jpg'],
      ),
    ],
    verify: (_) {
      verify(() => getImages('l1')).called(1);
      verifyNever(() => getOrCreateConversation(any()));
    },
  );

  blocTest<ListingDetailsCubit, ListingDetailsState>(
    'initialCoverImageUrl prepended before ordered gallery URLs',
    setUp: () {
      final listing = _listing(cover: 'https://cdn/cover-only.jpg');
      when(() => getById('l1')).thenAnswer((_) async => Success(listing));
      when(() => getImages('l1')).thenAnswer(
        (_) async => Success([
          ListingImage(
            id: 'i2',
            listingId: 'l1',
            publicUrl: 'https://cdn/b.jpg',
            position: 2,
            createdAt: DateTime.utc(2026, 1, 4),
          ),
          ListingImage(
            id: 'i0',
            listingId: 'l1',
            publicUrl: 'https://cdn/a.jpg',
            position: 0,
            createdAt: DateTime.utc(2026, 1, 2),
          ),
        ]),
      );
    },
    build: () => ListingDetailsCubit(
      getListingById: getById,
      getListingImages: getImages,
      getOrCreateConversation: getOrCreateConversation,
    ),
    act: (c) =>
        c.load('l1', initialCoverImageUrl: 'https://cdn/cover-only.jpg'),
    expect: () => [
      const ListingDetailsState.loading(),
      ListingDetailsState.success(
        _listing(cover: 'https://cdn/cover-only.jpg'),
        heroImageUrls: const [
          'https://cdn/cover-only.jpg',
          'https://cdn/a.jpg',
          'https://cdn/b.jpg',
        ],
      ),
    ],
    verify: (_) {
      verify(() => getImages('l1')).called(1);
      verifyNever(() => getOrCreateConversation(any()));
    },
  );

  blocTest<ListingDetailsCubit, ListingDetailsState>(
    'gallery RPC failure ⇒ success + cover fallback (no thrown error)',
    setUp: () {
      final listing = _listing(cover: 'https://cdn/fallback.jpg');
      when(() => getById('l1')).thenAnswer((_) async => Success(listing));
      when(
        () => getImages('l1'),
      ).thenAnswer((_) async => FailureResult(ServerFailure('down')));
    },
    build: () => ListingDetailsCubit(
      getListingById: getById,
      getListingImages: getImages,
      getOrCreateConversation: getOrCreateConversation,
    ),
    act: (c) => c.load('l1'),
    expect: () => [
      const ListingDetailsState.loading(),
      ListingDetailsState.success(
        _listing(cover: 'https://cdn/fallback.jpg'),
        heroImageUrls: const ['https://cdn/fallback.jpg'],
      ),
    ],
    verify: (_) {
      verify(() => getImages('l1')).called(1);
      verifyNever(() => getOrCreateConversation(any()));
    },
  );

  blocTest<ListingDetailsCubit, ListingDetailsState>(
    'listing fetch fails before gallery call',
    setUp: () {
      when(
        () => getById('l1'),
      ).thenAnswer((_) async => FailureResult(const NetworkFailure('offline')));
    },
    build: () => ListingDetailsCubit(
      getListingById: getById,
      getListingImages: getImages,
      getOrCreateConversation: getOrCreateConversation,
    ),
    act: (c) => c.load('l1'),
    expect: () => [
      const ListingDetailsState.loading(),
      ListingDetailsState.failure(const NetworkFailure('offline')),
    ],
    verify: (_) {
      verifyNever(() => getImages(any()));
      verifyNever(() => getOrCreateConversation(any()));
    },
  );

  test('startConversationForListing delegates to messaging use case', () async {
    when(
      () => getOrCreateConversation('l1'),
    ).thenAnswer((_) async => const Success('conv-z'));
    final cubit = ListingDetailsCubit(
      getListingById: getById,
      getListingImages: getImages,
      getOrCreateConversation: getOrCreateConversation,
    );
    final r = await cubit.startConversationForListing('l1');
    expect(r, const Success<String>('conv-z'));
    verify(() => getOrCreateConversation('l1')).called(1);
    await cubit.close();
  });
}
