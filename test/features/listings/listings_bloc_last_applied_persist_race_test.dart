import 'dart:async';

import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/discovery_feed_chip_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/noop_record_recent_search.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

final class _PendingRequest {
  _PendingRequest(this.query);

  final ListingsQuery query;
  final completer = Completer<Result<List<Listing>>>();

  void succeed([List<Listing> listings = const []]) {
    completer.complete(Success(listings));
  }

  void fail([String message = 'network']) {
    completer.complete(FailureResult(ServerFailure(message)));
  }
}

final class _ControlledListingsRequests {
  _ControlledListingsRequests(this.repository) {
    when(() => repository.getListings(any())).thenAnswer((invocation) {
      final request = _PendingRequest(
        invocation.positionalArguments.single as ListingsQuery,
      );
      _pending.add(request);
      _requestAvailable?.complete();
      _requestAvailable = null;
      return request.completer.future;
    });
  }

  final _MockListingsRepository repository;
  final List<_PendingRequest> _pending = [];
  Completer<void>? _requestAvailable;

  Future<_PendingRequest> take() async {
    if (_pending.isEmpty) {
      _requestAvailable = Completer<void>();
      await _requestAvailable!.future;
    }
    return _pending.removeAt(0);
  }
}

final class _RecordingLastApplied
    implements LastAppliedListingDiscoveryRepository {
  ListingDiscoveryCriteria? lastPersisted;
  final persists = <ListingDiscoveryCriteria>[];

  @override
  Future<ListingDiscoveryCriteria?> load() async => lastPersisted;

  @override
  Future<void> persistIfNeeded(ListingDiscoveryCriteria snapshot) async {
    persists.add(snapshot);
    lastPersisted = snapshot;
  }
}

Listing _listing(String id) => Listing(
  id: id,
  title: 'Listing $id',
  make: 'Toyota',
  model: 'Camry',
  year: 2020,
  priceEur: 10000,
  mileageKm: 80000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
);

const _criteriaA = ListingDiscoveryCriteria(search: 'golf', make: 'Volkswagen');
const _criteriaB = ListingDiscoveryCriteria(search: 'passat', make: 'Skoda');

ListingsFiltersApplied _quickMake(String? make) {
  return ListingsFiltersApplied(
    make: make,
    model: null,
    minYear: null,
    maxYear: null,
    minPrice: null,
    maxPrice: null,
    maxMileage: null,
    city: null,
    typeFilter: ListingTypeFilter.any,
    sort: ListingSortOption.newestFirst,
    regionFilter: MarketRegionFilter.both,
    bodyType: null,
    fuelType: null,
    transmissionType: null,
    drivetrain: null,
    priceCurrencyFilter: ListingPriceCurrencyFilter.any,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockListingsRepository repository;
  late _ControlledListingsRequests requests;
  late _RecordingLastApplied lastApplied;

  setUpAll(() {
    registerFallbackValue(const ListingsQuery());
  });

  setUp(() {
    repository = _MockListingsRepository();
    requests = _ControlledListingsRequests(repository);
    lastApplied = _RecordingLastApplied();
  });

  ListingsBloc buildBloc() => ListingsBloc(
    getListings: GetListings(repository),
    lastAppliedDiscovery: lastApplied,
    recordRecentSearch: NoopRecordRecentSearch(),
  );

  test('A: Search apply persists B before listings fetch succeeds', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const ListingsHydratedFromDiscovery(_criteriaA));
    final first = await requests.take();
    expect(lastApplied.lastPersisted?.search, 'golf');
    expect(lastApplied.lastPersisted?.make, 'Volkswagen');

    bloc.add(const ListingsHydratedFromDiscovery(_criteriaB));
    await requests.take();

    expect(lastApplied.lastPersisted?.search, 'passat');
    expect(lastApplied.lastPersisted?.make, 'Skoda');
    expect(first.completer.isCompleted, isFalse);
    expect(bloc.state.status, ListingsStatus.loading);
  });

  test('B: quick Make persists Toyota before query success', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(_quickMake('Toyota'));
    await requests.take();

    expect(lastApplied.lastPersisted?.make, 'Toyota');
    expect(bloc.state.status, ListingsStatus.loading);
    expect(bloc.state.make, 'Toyota');
  });

  test(
    'C: removing Make persists cleared make before replacement success',
    () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(
        const ListingsHydratedFromDiscovery(
          ListingDiscoveryCriteria(make: 'Toyota'),
        ),
      );
      final first = await requests.take();
      expect(lastApplied.lastPersisted?.make, 'Toyota');

      bloc.add(
        const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.make),
      );
      await requests.take();

      expect(lastApplied.lastPersisted?.make, isNull);
      expect(first.completer.isCompleted, isFalse);
    },
  );

  test(
    'D: rapid A then B leaves LastApplied as B after adversarial completes',
    () async {
      final bloc = buildBloc();
      addTearDown(bloc.close);

      bloc.add(const ListingsHydratedFromDiscovery(_criteriaA));
      final older = await requests.take();
      bloc.add(const ListingsHydratedFromDiscovery(_criteriaB));
      final newer = await requests.take();

      expect(lastApplied.lastPersisted?.search, 'passat');
      expect(lastApplied.lastPersisted?.make, 'Skoda');

      older.succeed([_listing('a')]);
      newer.succeed([_listing('b')]);
      await bloc.stream.firstWhere(
        (state) =>
            state.status == ListingsStatus.success && state.make == 'Skoda',
      );

      expect(lastApplied.lastPersisted?.search, 'passat');
      expect(lastApplied.lastPersisted?.make, 'Skoda');
      expect(lastApplied.persists.last.make, 'Skoda');
    },
  );

  test('E: query failure keeps LastApplied as applied B', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(const ListingsHydratedFromDiscovery(_criteriaB));
    final request = await requests.take();
    expect(lastApplied.lastPersisted?.make, 'Skoda');

    request.fail();
    await bloc.stream.firstWhere(
      (state) => state.status == ListingsStatus.failure,
    );

    expect(lastApplied.lastPersisted?.search, 'passat');
    expect(lastApplied.lastPersisted?.make, 'Skoda');
    expect(lastApplied.persists, hasLength(1));
  });

  test('pagination success does not rewrite LastApplied', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(_quickMake('Toyota'));
    final first = await requests.take();
    first.succeed([
      for (var i = 0; i < AppConstants.defaultPageSize; i++) _listing('1-$i'),
    ]);
    await bloc.stream.firstWhere(
      (state) => state.status == ListingsStatus.success,
    );
    expect(lastApplied.persists, hasLength(1));

    bloc.add(const ListingsNextPageRequested());
    final next = await requests.take();
    next.succeed([_listing('2')]);
    await bloc.stream.firstWhere(
      (state) => state.status == ListingsStatus.success && state.page == 1,
    );

    expect(lastApplied.persists, hasLength(1));
    expect(lastApplied.lastPersisted?.make, 'Toyota');
  });

  test('refresh does not persist unchanged criteria', () async {
    final bloc = buildBloc();
    addTearDown(bloc.close);

    bloc.add(_quickMake('Toyota'));
    final first = await requests.take();
    first.succeed([_listing('1')]);
    await bloc.stream.firstWhere(
      (state) => state.status == ListingsStatus.success,
    );

    bloc.add(const ListingsRefreshed());
    final refresh = await requests.take();
    refresh.succeed([_listing('2')]);
    await bloc.stream.firstWhere(
      (state) =>
          state.status == ListingsStatus.success && state.items.first.id == '2',
    );

    expect(lastApplied.persists, hasLength(1));
  });
}
