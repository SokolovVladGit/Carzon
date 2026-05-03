import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_image.dart';
import 'package:carzon/features/listings/presentation/utils/listing_details_hero_urls.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _baseListing({String? cover}) => Listing(
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

ListingImage _img({required int position, required String url}) => ListingImage(
  id: 'i$position',
  listingId: 'l1',
  publicUrl: url,
  position: position,
  createdAt: DateTime.utc(2026, 1, 2),
);

void main() {
  group('listingDetailsHeroImageUrls', () {
    test(
      'uses ordered gallery URLs only — does not append cover duplicates',
      () {
        final listing = _baseListing(cover: 'https://cdn/cover-only.jpg');
        final urls = listingDetailsHeroImageUrls(
          listing: listing,
          imagesResult: Success([
            _img(position: 1, url: 'https://cdn/b.jpg'),
            _img(position: 0, url: 'https://cdn/a.jpg'),
          ]),
        );
        expect(urls, ['https://cdn/a.jpg', 'https://cdn/b.jpg']);
      },
    );

    test('gallery fetch failure falls back to cover URL', () {
      final listing = _baseListing(cover: 'https://cdn/cover.jpg');
      final urls = listingDetailsHeroImageUrls(
        listing: listing,
        imagesResult: FailureResult(ServerFailure('down')),
      );
      expect(urls, ['https://cdn/cover.jpg']);
    });

    test('empty gallery rows falls back to cover', () {
      final listing = _baseListing(cover: 'https://cdn/x.jpg');
      final urls = listingDetailsHeroImageUrls(
        listing: listing,
        imagesResult: const Success([]),
      );
      expect(urls, ['https://cdn/x.jpg']);
    });

    test('drops blank urls; empty result falls through to cover', () {
      final listing = _baseListing(cover: 'https://cdn/fallback.jpg');
      final urls = listingDetailsHeroImageUrls(
        listing: listing,
        imagesResult: Success([
          _img(position: 0, url: '   '),
          _img(position: 1, url: 'https://cdn/ok.jpg'),
        ]),
      );
      expect(urls, ['https://cdn/ok.jpg']);
    });
  });
}
