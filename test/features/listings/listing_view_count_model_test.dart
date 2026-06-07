import 'package:carzon/features/listings/data/models/listing_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('fromPublicJson maps view_count', () {
    final model = ListingModel.fromPublicJson({
      'id': 'a',
      'title': 't',
      'make': 'm',
      'model': 'x',
      'year': 2019,
      'price_eur': 1000,
      'price_currency': 'eur',
      'mileage_km': 10,
      'type': 'sale',
      'city': 'Chi',
      'market_region': 'moldova',
      'created_at': '2026-03-01T12:00:00.000Z',
      'view_count': 128,
    });

    expect(model.viewCount, 128);
  });

  test('fromPublicJson defaults missing view_count to 0', () {
    final model = ListingModel.fromPublicJson({
      'id': 'a',
      'title': 't',
      'make': 'm',
      'model': 'x',
      'year': 2019,
      'price_eur': 1000,
      'price_currency': 'eur',
      'mileage_km': 10,
      'type': 'sale',
      'city': 'Chi',
      'market_region': 'moldova',
      'created_at': '2026-03-01T12:00:00.000Z',
    });

    expect(model.viewCount, 0);
  });
}
