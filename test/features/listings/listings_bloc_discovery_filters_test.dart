import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/listing_discovery_state_sync.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

final class _RecordingLastApplied implements LastAppliedListingDiscoveryRepository {
  ListingDiscoveryCriteria? lastPersisted;

  @override
  Future<ListingDiscoveryCriteria?> load() async => null;

  @override
  Future<void> persistIfNeeded(ListingDiscoveryCriteria snapshot) async {
    lastPersisted = snapshot;
  }
}

void main() {
  late _MockListingsRepository repo;
  _RecordingLastApplied? lastAppliedRecorder;

  setUpAll(() {
    registerFallbackValue(const ListingsQuery());
  });

  setUp(() {
    repo = _MockListingsRepository();
    lastAppliedRecorder = null;
    when(() => repo.fetchBuyerVinReportSources(any())).thenAnswer(
      (_) async => const Success(BuyerListingVinReportLookupResult()),
    );
  });

  blocTest<ListingsBloc, ListingsState>(
    'ListingsRequested issues default feed query (no optional text/numeric filters)',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(getListings: GetListings(repo), lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository()),
    act: (b) => b.add(const ListingsRequested()),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.status, ListingStatus.active);
      expect(q.marketRegion, MarketRegion.transnistria);
      expect(q.sort, ListingSortOption.newestFirst);
      expect(q.search, isNull);
      expect(q.make, isNull);
      expect(q.model, isNull);
      expect(q.city, isNull);
      expect(q.minPrice, isNull);
      expect(q.maxMileage, isNull);
      expect(q.typeIn, isNull);
      expect(q.bodyType, isNull);
      expect(q.priceCurrency, isNull);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersApplied maps model, price, mileage, city, and sort into query',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(getListings: GetListings(repo), lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository()),
    act: (b) => b.add(
      const ListingsFiltersApplied(
        make: null,
        model: ' Golf ',
        minYear: null,
        maxYear: null,
        minPrice: 1000,
        maxPrice: 8000,
        maxMileage: 200000,
        city: ' Tiraspol ',
        typeFilter: ListingTypeFilter.any,
        sort: ListingSortOption.priceLowToHigh,
        regionFilter: MarketRegionFilter.transnistria,
        bodyType: null,
        priceCurrencyFilter: ListingPriceCurrencyFilter.any,
      ),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.make, isNull);
      expect(q.model, 'Golf');
      expect(q.minPrice, 1000);
      expect(q.maxPrice, 8000);
      expect(q.maxMileage, 200000);
      expect(q.city, 'Tiraspol');
      expect(q.sort, ListingSortOption.priceLowToHigh);
      expect(q.status, ListingStatus.active);
      expect(q.priceCurrency, isNull);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersApplied maps USD listing currency into ListingsQuery',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(getListings: GetListings(repo), lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository()),
    act: (b) => b.add(
      const ListingsFiltersApplied(
        make: null,
        model: null,
        minYear: null,
        maxYear: null,
        minPrice: 500,
        maxPrice: 5000,
        maxMileage: null,
        city: null,
        typeFilter: ListingTypeFilter.any,
        sort: ListingSortOption.newestFirst,
        regionFilter: MarketRegionFilter.transnistria,
        bodyType: null,
        priceCurrencyFilter: ListingPriceCurrencyFilter.usd,
      ),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.priceCurrency, ListingCurrency.usd);
      expect(q.minPrice, 500);
      expect(q.maxPrice, 5000);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersCleared resets sort to newestFirst',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(getListings: GetListings(repo), lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository()),
    act: (b) => b
      ..add(
        const ListingsFiltersApplied(
          make: null,
          model: 'x',
          minYear: null,
          maxYear: null,
          minPrice: null,
          maxPrice: null,
          maxMileage: null,
          city: null,
          typeFilter: ListingTypeFilter.any,
          sort: ListingSortOption.priceHighToLow,
          regionFilter: MarketRegionFilter.transnistria,
          bodyType: null,
          priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
        ),
      )
      ..add(const ListingsFiltersCleared()),
    verify: (_) {
      final captured = verify(() => repo.getListings(captureAny())).captured;
      expect(captured.length, 2);
      final q = captured.last as ListingsQuery;
      expect(q.sort, ListingSortOption.newestFirst);
      expect(q.model, isNull);
      expect(q.priceCurrency, isNull);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersCleared clears make after ListingsFiltersApplied',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    ),
    act: (b) => b
      ..add(
        const ListingsFiltersApplied(
          make: 'Skoda',
          model: null,
          minYear: null,
          maxYear: null,
          minPrice: null,
          maxPrice: null,
          maxMileage: null,
          city: null,
          typeFilter: ListingTypeFilter.any,
          sort: ListingSortOption.newestFirst,
          regionFilter: MarketRegionFilter.transnistria,
          bodyType: null,
          priceCurrencyFilter: ListingPriceCurrencyFilter.any,
        ),
      )
      ..add(const ListingsFiltersCleared()),
    verify: (bloc) {
      expect(bloc.state.make, isNull);
      final captured = verify(() => repo.getListings(captureAny())).captured;
      expect(captured.length, 2);
      expect((captured.last as ListingsQuery).make, isNull);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersCleared leaves default last-applied snapshot (no make)',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () {
      lastAppliedRecorder = _RecordingLastApplied();
      return ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: lastAppliedRecorder!,
      );
    },
    act: (b) async {
      b.add(
        const ListingsFiltersApplied(
          make: 'Skoda',
          model: null,
          minYear: null,
          maxYear: null,
          minPrice: null,
          maxPrice: null,
          maxMileage: null,
          city: null,
          typeFilter: ListingTypeFilter.any,
          sort: ListingSortOption.newestFirst,
          regionFilter: MarketRegionFilter.transnistria,
          bodyType: null,
          priceCurrencyFilter: ListingPriceCurrencyFilter.any,
        ),
      );
      await Future<void>.delayed(Duration.zero);
      b.add(const ListingsFiltersCleared());
      await Future<void>.delayed(Duration.zero);
    },
    verify: (_) {
      final snap = lastAppliedRecorder!.lastPersisted;
      expect(snap, isNotNull);
      expect(snap!.make, isNull);
      expect(
        isDefaultListingsDiscoveryState(
          listingsStateFromDiscoveryCriteria(snap),
        ),
        isTrue,
      );
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersCleared resets region to default marketplace',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    ),
    act: (b) => b
      ..add(const ListingsRegionFilterChanged(MarketRegionFilter.moldova))
      ..add(const ListingsFiltersCleared()),
    verify: (_) {
      final last =
          verify(() => repo.getListings(captureAny())).captured.last
              as ListingsQuery;
      expect(last.marketRegion, MarketRegion.transnistria);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersCleared clears persisted search from last-applied snapshot',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () {
      lastAppliedRecorder = _RecordingLastApplied();
      return ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: lastAppliedRecorder!,
      );
    },
    act: (b) async {
      b.add(const ListingsRequested());
      await Future<void>.delayed(Duration.zero);
      b.add(const ListingsSearchChanged('bmw query'));
      await Future<void>.delayed(Duration.zero);
      b.add(const ListingsFiltersCleared());
      await Future<void>.delayed(Duration.zero);
    },
    verify: (_) {
      expect(lastAppliedRecorder!.lastPersisted, isNotNull);
      expect(
        lastAppliedRecorder!.lastPersisted!.search?.contains('bmw'),
        isNot(true),
      );
      expect(lastAppliedRecorder!.lastPersisted!.search, isNull);
      expect(
        isDefaultListingsDiscoveryState(
          listingsStateFromDiscoveryCriteria(lastAppliedRecorder!.lastPersisted!),
        ),
        isTrue,
      );
    },
  );
}

