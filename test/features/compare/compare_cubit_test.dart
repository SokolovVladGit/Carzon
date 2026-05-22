import 'package:carzon/features/compare/domain/entities/compare_item.dart';
import 'package:carzon/features/compare/domain/entities/compare_listing_snapshot.dart';
import 'package:carzon/features/compare/domain/repositories/compare_repository.dart';
import 'package:carzon/features/compare/presentation/cubit/compare_cubit.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCompareRepository implements CompareRepository {
  List<CompareItem> stored = const [];

  @override
  Future<void> clear() async {
    stored = const [];
  }

  @override
  Future<List<CompareItem>> loadItems() async => List<CompareItem>.from(stored);

  @override
  Future<void> saveItems(List<CompareItem> items) async {
    stored = List<CompareItem>.from(items);
  }
}

CompareListingSnapshot snapshot(String id) {
  return CompareListingSnapshot(
    listingId: id,
    addedAt: DateTime.utc(2026, 5, 22),
    make: 'Toyota',
    model: 'Camry',
    year: 2019,
    priceEur: 9000,
    priceCurrency: ListingCurrency.eur,
  );
}

void main() {
  late _FakeCompareRepository repository;
  late CompareCubit cubit;

  setUp(() {
    repository = _FakeCompareRepository();
    cubit = CompareCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('loadFromStorage restores persisted items', () async {
    repository.stored = [
      CompareItem(snapshot: snapshot('l1')),
      CompareItem(snapshot: snapshot('l2')),
    ];
    await cubit.loadFromStorage();
    expect(cubit.state.count, 2);
    expect(cubit.state.hasMinimumForCompare, isTrue);
  });

  test('addSnapshot appends and persists', () async {
    await cubit.addSnapshot(snapshot('a'));
    expect(cubit.state.count, 1);
    await cubit.addSnapshot(snapshot('b'));
    expect(cubit.state.count, 2);
    expect(repository.stored.map((e) => e.listingId), ['a', 'b']);
  });

  test('duplicate add does not increase count', () async {
    await cubit.addSnapshot(snapshot('dup'));
    await cubit.addSnapshot(snapshot('dup'));
    expect(cubit.state.count, 1);
    expect(repository.stored.length, 1);
  });

  test('max 3 items enforced', () async {
    for (var i = 1; i <= 4; i++) {
      await cubit.addSnapshot(snapshot('id$i'));
    }
    expect(cubit.state.count, 3);
    expect(cubit.state.isFull, isTrue);
    expect(repository.stored.length, 3);
  });

  test('loadFromStorage trims persisted list to maxItems', () async {
    repository.stored = [
      CompareItem(snapshot: snapshot('a')),
      CompareItem(snapshot: snapshot('b')),
      CompareItem(snapshot: snapshot('c')),
      CompareItem(snapshot: snapshot('d')),
    ];
    await cubit.loadFromStorage();
    expect(cubit.state.count, 3);
    expect(cubit.state.items.map((e) => e.listingId), ['a', 'b', 'c']);
    expect(repository.stored.length, 3);
  });

  test('remove and clear update state and storage', () async {
    await cubit.addSnapshot(snapshot('r1'));
    await cubit.addSnapshot(snapshot('r2'));
    await cubit.remove('r1');
    expect(cubit.state.count, 1);
    await cubit.clear();
    expect(cubit.state.isEmpty, isTrue);
    expect(repository.stored, isEmpty);
  });

  test('toggleSnapshot adds then removes', () async {
    await cubit.toggleSnapshot(snapshot('t1'));
    expect(cubit.state.count, 1);
    await cubit.toggleSnapshot(snapshot('t1'));
    expect(cubit.state.isEmpty, isTrue);
  });

  test('containsListing reflects current set', () async {
    await cubit.addSnapshot(snapshot('x'));
    expect(cubit.state.containsListing('x'), isTrue);
    expect(cubit.state.containsListing('y'), isFalse);
  });
}
