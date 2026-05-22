import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/entities/compare_resolved_slot.dart';
import 'package:carzon/features/compare/presentation/utils/compare_spec_builder.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

CompareResolvedSlot _slot({
  required String id,
  required int price,
  required int mileage,
  required int year,
  ListingVinStatus vin = ListingVinStatus.notProvided,
}) {
  final listing = Listing(
    id: id,
    title: 'T',
    make: 'BMW',
    model: '3',
    year: year,
    priceEur: price,
    mileageKm: mileage,
    type: ListingType.sale,
    city: 'City',
    marketRegion: MarketRegion.moldova,
    createdAt: DateTime.utc(2026, 4, 1),
    status: ListingStatus.active,
    vinStatus: vin,
    sellerId: 's',
  );
  return CompareResolvedSlot(
    item: CompareItem(
      snapshot: CompareListingSnapshot(
        listingId: id,
        addedAt: DateTime.utc(2026, 5, 22),
        make: 'BMW',
        model: '3',
        year: year,
        priceEur: price,
      ),
    ),
    phase: CompareSlotPhase.ready,
    listing: listing,
  );
}

void main() {
  final ru = ruStrings();

  test('filterOnlyDifferences hides identical rows', () {
    final slots = [
      _slot(id: 'a', price: 10000, mileage: 50000, year: 2018),
      _slot(id: 'b', price: 12000, mileage: 80000, year: 2020),
    ];
    final sections = CompareSpecBuilder(ru, slots).buildSections();
    final filtered = filterOnlyDifferences(sections);
    final priceRows = filtered
        .expand((s) => s.rows)
        .where((r) => r.id == 'price');
    expect(priceRows, isNotEmpty);
    final makeRows = filtered.expand((s) => s.rows).where((r) => r.id == 'make');
    expect(makeRows, isEmpty);
  });

  test('VIN row uses safe provided/not-provided labels only', () {
    final slots = [
      _slot(id: 'a', price: 1, mileage: 1, year: 2018, vin: ListingVinStatus.formatValid),
      _slot(id: 'b', price: 2, mileage: 2, year: 2019, vin: ListingVinStatus.notProvided),
    ];
    final sections = CompareSpecBuilder(ru, slots).buildSections();
    final vinRow = sections
        .expand((s) => s.rows)
        .firstWhere((r) => r.id == 'vin');
    expect(vinRow.values, [ru.compareVinProvided, ru.compareVinNotProvided]);
    for (final v in vinRow.values) {
      expect(v.length, lessThan(20));
      expect(v.toLowerCase(), isNot(contains('verify')));
      expect(v.toLowerCase(), isNot(contains('отчёт')));
    }
  });
}
