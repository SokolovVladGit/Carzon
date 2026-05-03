import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/create_listing/data/repositories/create_listing_repository_impl.dart';
import 'package:carzon/features/create_listing/data/datasources/create_listing_remote_datasource.dart';
import 'package:carzon/features/create_listing/domain/constants/listing_gallery_limits.dart';
import 'package:carzon/features/create_listing/domain/entities/new_listing_input.dart';
import 'package:carzon/features/create_listing/domain/entities/uploaded_listing_image.dart';
import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements CreateListingRemoteDataSource {}

ListingModel _row() => ListingModel(
  id: '11111111-1111-1111-1111-111111111111',
  title: 'x',
  make: 'make',
  model: 'mod',
  year: 2020,
  priceEur: 999,
  priceCurrency: ListingCurrency.usd,
  mileageKm: 1,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 2),
  contactPhone: '+373 690 00001',
);

NewListingInput _fallbackInput() => NewListingInput(
  sellerId: 's',
  title: 't',
  make: 'm',
  model: 'm',
  year: 2020,
  priceEur: 1,
  mileageKm: 1,
  type: ListingType.sale,
  city: 'c',
  marketRegion: MarketRegion.moldova,
  contactPhone: '+373 690 00001',
);

NewListingInput _oversizedGalleryInput() => NewListingInput(
  sellerId: 'seller',
  title: 't',
  make: 'm',
  model: 'm',
  year: 2020,
  priceEur: 100,
  priceCurrency: ListingCurrency.usd,
  mileageKm: 1,
  type: ListingType.sale,
  city: 'c',
  marketRegion: MarketRegion.moldova,
  contactPhone: '+373 690 00001',
  uploadedGallery: List.generate(
    kMaxListingPhotos + 1,
    (i) => UploadedListingImage(publicUrl: 'https://h/$i'),
  ),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_fallbackInput());
  });

  group('CreateListingRepositoryImpl.createV2', () {
    test(
      'returns failure without calling remote when gallery too large',
      () async {
        final remote = _MockRemote();
        final repo = CreateListingRepositoryImpl(remote);
        final r = await repo.createV2(_oversizedGalleryInput());
        expect(r, isA<FailureResult<Listing>>());
        verifyNever(() => remote.insertV2(any()));
      },
    );

    test('forwards to remote.insertV2 on success', () async {
      final remote = _MockRemote();
      final repo = CreateListingRepositoryImpl(remote);
      final input = NewListingInput(
        sellerId: 'seller',
        title: 't',
        make: 'm',
        model: 'm',
        year: 2020,
        priceEur: 100,
        priceCurrency: ListingCurrency.usd,
        mileageKm: 1,
        type: ListingType.sale,
        city: 'c',
        marketRegion: MarketRegion.moldova,
        contactPhone: '+373 690 00001',
        uploadedGallery: const [
          UploadedListingImage(
            publicUrl: 'https://cdn.example/a.jpg',
            storagePath: 'listings/seller/x.jpg',
          ),
        ],
      );
      when(() => remote.insertV2(any())).thenAnswer((_) async => _row());
      final r = await repo.createV2(input);
      expect(r, isA<Success<Listing>>());
      final cap =
          verify(() => remote.insertV2(captureAny())).captured.single
              as NewListingInput;
      expect(cap.priceCurrency, ListingCurrency.usd);
      expect(cap.uploadedGallery?.length, 1);
      expect(cap.uploadedGallery?.first.storagePath, 'listings/seller/x.jpg');
    });
  });
}
