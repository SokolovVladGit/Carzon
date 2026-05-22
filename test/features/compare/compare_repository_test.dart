import 'package:carzon/features/compare/data/datasources/compare_local_datasource.dart';
import 'package:carzon/features/compare/data/repositories/compare_repository_impl.dart';
import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CompareRepositoryImpl repo;

  CompareItem item(String id, {DateTime? addedAt}) {
    return CompareItem(
      snapshot: CompareListingSnapshot(
        listingId: id,
        addedAt: addedAt ?? DateTime.utc(2026, 5, 20, 12),
        make: 'Audi',
        model: 'A4',
        year: 2020,
        priceEur: 12000,
        priceCurrency: ListingCurrency.eur,
        city: 'Chișinău',
        marketRegionRaw: 'moldova',
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    repo = CompareRepositoryImpl(SharedPreferencesCompareLocalDataSource());
  });

  test('empty storage returns empty list', () async {
    expect(await repo.loadItems(), isEmpty);
  });

  test('save and load round trip preserves order', () async {
    final items = [
      item('a', addedAt: DateTime.utc(2026, 5, 1)),
      item('b', addedAt: DateTime.utc(2026, 5, 2)),
      item('c', addedAt: DateTime.utc(2026, 5, 3)),
    ];
    await repo.saveItems(items);
    final loaded = await repo.loadItems();
    expect(loaded.map((e) => e.listingId), ['a', 'b', 'c']);
    expect(loaded.first.snapshot.make, 'Audi');
  });

  test('malformed JSON returns empty list safely', () async {
    SharedPreferences.setMockInitialValues({
      SharedPreferencesCompareLocalDataSource.storageKey: '{not-json',
    });
    repo = CompareRepositoryImpl(SharedPreferencesCompareLocalDataSource());
    expect(await repo.loadItems(), isEmpty);
  });

  test('clear removes persisted data', () async {
    await repo.saveItems([item('x')]);
    await repo.clear();
    expect(await repo.loadItems(), isEmpty);
  });
}
