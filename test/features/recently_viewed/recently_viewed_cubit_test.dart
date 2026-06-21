import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/recently_viewed/domain/entities/recently_viewed_entry.dart';
import 'package:carzon/features/recently_viewed/domain/repositories/recently_viewed_repository.dart';
import 'package:carzon/features/recently_viewed/presentation/cubit/recently_viewed_cubit.dart';
import 'package:carzon/features/recently_viewed/presentation/cubit/recently_viewed_state.dart';
import 'package:flutter_test/flutter_test.dart';

class _MemoryRecentlyViewedRepository implements RecentlyViewedRepository {
  List<RecentlyViewedEntry> stored = const [];

  @override
  Future<void> clear() async {
    stored = const [];
  }

  @override
  Future<List<RecentlyViewedEntry>> load() async =>
      List<RecentlyViewedEntry>.from(stored);

  @override
  Future<List<RecentlyViewedEntry>> record(RecentlyViewedEntry entry) async {
    stored = [entry, ...stored.where((e) => e.listingId != entry.listingId)];
    return List<RecentlyViewedEntry>.from(stored);
  }
}

RecentlyViewedEntry _entry(String id) => RecentlyViewedEntry(
  listingId: id,
  viewedAt: DateTime.utc(2026, 6, 1),
  title: 'Title $id',
  make: 'Audi',
  model: 'A4',
  year: 2020,
  priceEur: 12000,
  priceCurrency: ListingCurrency.eur,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
);

void main() {
  late _MemoryRecentlyViewedRepository repository;
  late RecentlyViewedCubit cubit;

  setUp(() {
    repository = _MemoryRecentlyViewedRepository();
    cubit = RecentlyViewedCubit(repository: repository);
  });

  tearDown(() => cubit.close());

  test('loadFromStorage restores persisted entries', () async {
    repository.stored = [_entry('a'), _entry('b')];
    await cubit.loadFromStorage();
    expect(cubit.state.status, RecentlyViewedStatus.ready);
    expect(cubit.state.entries.map((e) => e.listingId), ['a', 'b']);
  });

  test('syncEntries updates ready state', () {
    cubit.syncEntries([_entry('z')]);
    expect(cubit.state.entries.single.listingId, 'z');
  });

  test('clear empties state', () async {
    repository.stored = [_entry('a')];
    await cubit.loadFromStorage();
    final ok = await cubit.clear();
    expect(ok, isTrue);
    expect(cubit.state.isEmpty, isTrue);
  });
}
