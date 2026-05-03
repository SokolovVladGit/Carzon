import 'package:carzon/features/edit_listing/data/datasources/edit_listing_remote_datasource.dart';
import 'package:carzon/features/edit_listing/data/repositories/edit_listing_repository_impl.dart';
import 'package:carzon/features/edit_listing/domain/entities/edit_listing_input.dart';
import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRemote extends Mock implements EditListingRemoteDataSource {}

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

EditListingInput _minimalInput({
  ListingCurrency currency = ListingCurrency.eur,
}) => EditListingInput(
  listingId: _row().id,
  title: 'x',
  make: 'm',
  model: 'm',
  year: 2020,
  priceEur: 1,
  mileageKm: 1,
  type: ListingType.sale,
  city: 'c',
  marketRegion: MarketRegion.moldova,
  contactPhone: '+373 690 00001',
  priceCurrency: currency,
);

void main() {
  late _MockRemote remote;
  late EditListingRepositoryImpl repo;

  setUpAll(() {
    registerFallbackValue(_minimalInput());
  });

  setUp(() {
    remote = _MockRemote();
    repo = EditListingRepositoryImpl(remote);
  });

  group('updateDetailsV2', () {
    test('forwards to datasource and returns Success', () async {
      final expected = _row();
      when(
        () => remote.updateDetailsV2(any()),
      ).thenAnswer((_) async => expected);

      final out = await repo.updateDetailsV2(_minimalInput());

      expect(
        out.fold<Listing?>((_) => throw StateError('failure'), (v) => v),
        same(expected),
      );
      verify(() => remote.updateDetailsV2(any())).called(1);
    });
  });

  group('replaceListingImages', () {
    test('forwards ordered URLs and optional paths', () async {
      final expected = _row();
      when(
        () => remote.replaceListingImages(
          listingId: any(named: 'listingId'),
          imagePublicUrls: any(named: 'imagePublicUrls'),
          storagePaths: any(named: 'storagePaths'),
        ),
      ).thenAnswer((_) async => expected);

      final out = await repo.replaceListingImages(
        listingId: '11111111-1111-1111-1111-111111111111',
        imagePublicUrls: ['https://a/1.jpg', 'https://a/2.jpg'],
        storagePaths: ['p1', null],
      );

      expect(
        out.fold<Listing?>((_) => throw StateError('failure'), (v) => v),
        same(expected),
      );
      verify(
        () => remote.replaceListingImages(
          listingId: '11111111-1111-1111-1111-111111111111',
          imagePublicUrls: ['https://a/1.jpg', 'https://a/2.jpg'],
          storagePaths: ['p1', null],
        ),
      ).called(1);
    });

    test('passes null storagePaths', () async {
      when(
        () => remote.replaceListingImages(
          listingId: any(named: 'listingId'),
          imagePublicUrls: any(named: 'imagePublicUrls'),
          storagePaths: null,
        ),
      ).thenAnswer((_) async => _row());

      await repo.replaceListingImages(
        listingId: '11111111-1111-1111-1111-111111111111',
        imagePublicUrls: const ['https://x/z.png'],
        storagePaths: null,
      );

      verify(
        () => remote.replaceListingImages(
          listingId: '11111111-1111-1111-1111-111111111111',
          imagePublicUrls: const ['https://x/z.png'],
          storagePaths: null,
        ),
      ).called(1);
    });
  });
}
