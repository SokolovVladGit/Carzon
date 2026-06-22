import 'package:carzon/features/fuel_prices/domain/entities/fuel_price_snapshot.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FuelPriceSnapshot.tryParse maps public RPC row', () {
    final parsed = FuelPriceSnapshot.tryParse({
      'snapshot': {
        'territory': 'moldova',
        'status': 'succeeded',
        'is_stale': false,
        'source_label': 'ANRE · e-Carburanți',
        'effective_date': '2026-06-22',
        'fetched_at': '2026-06-22T10:00:00Z',
        'currency': 'MDL',
        'unit': 'liter',
        'items': [
          {'fuel_code': 'gasoline_95', 'price': 27.99},
          {'fuel_code': 'diesel', 'price': 25.86},
        ],
        'limitation_codes': ['national_ceiling', 'verify_at_station'],
      },
    });

    expect(parsed, isNotNull);
    expect(parsed!.territory, 'moldova');
    expect(parsed.isAvailable, isTrue);
    expect(parsed.items, hasLength(2));
    expect(parsed.items.first.price, 27.99);
  });

  test('FuelPriceSnapshot.tryParse rejects invalid row', () {
    expect(FuelPriceSnapshot.tryParse({'snapshot': {'status': 'x'}}), isNull);
  });
}
