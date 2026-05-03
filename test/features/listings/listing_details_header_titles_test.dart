import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/utils/listing_details_header_titles.dart';
import 'package:flutter_test/flutter_test.dart';

Listing _listing({
  required String title,
  required String make,
  required String model,
}) => Listing(
  id: 'x',
  title: title,
  make: make,
  model: model,
  year: 2020,
  priceEur: 1,
  mileageKm: 1,
  type: ListingType.sale,
  city: '',
  marketRegion: MarketRegion.moldova,
  createdAt: DateTime.utc(2026, 1, 1),
);

void main() {
  group('ListingDetailsHeaderDisplay.fromListing', () {
    test('primary is make + model; title becomes tagline when distinct', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(title: 'white beast', make: 'Audi', model: 'A5'),
      );
      expect(d.primaryLine, 'Audi A5');
      expect(d.tagline, 'white beast');
    });

    test('subtitle hidden when title normalizes equal to vehicle line', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(title: '  audi   A5 ', make: 'Audi', model: 'A5'),
      );
      expect(d.primaryLine, 'Audi A5');
      expect(d.tagline, isNull);
    });

    test('missing make/model: primary falls back to title; no subtitle', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(title: 'mystery car', make: '', model: ''),
      );
      expect(d.primaryLine, 'mystery car');
      expect(d.tagline, isNull);
    });

    test('missing model uses make only', () {
      final d = ListingDetailsHeaderDisplay.fromListing(
        _listing(title: 'seller note', make: 'BMW', model: ''),
      );
      expect(d.primaryLine, 'BMW');
      expect(d.tagline, 'seller note');
    });
  });
}
