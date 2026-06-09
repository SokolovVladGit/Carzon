import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
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

Listing _listing(String id) => Listing(
  id: id,
  title: 'Listing $id',
  make: 'Volkswagen',
  model: 'Golf',
  year: 2018,
  priceEur: 9000,
  mileageKm: 100000,
  type: ListingType.sale,
  city: 'Tiraspol',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
);

final class _RecordingLastApplied
    implements LastAppliedListingDiscoveryRepository {
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
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    ),
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
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    ),
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
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    ),
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
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    ),
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
          listingsStateFromDiscoveryCriteria(
            lastAppliedRecorder!.lastPersisted!,
          ),
        ),
        isTrue,
      );
    },
  );

  group('pagination failure handling', () {
    final firstPage = List<Listing>.generate(
      20,
      (i) => _listing('page0-$i'),
      growable: false,
    );
    final secondPage = [_listing('page1-0'), _listing('page1-1')];

    blocTest<ListingsBloc, ListingsState>(
      'initial load failure still emits full failure state',
      setUp: () {
        when(() => repo.getListings(any())).thenAnswer(
          (_) async => const FailureResult(NetworkFailure('offline')),
        );
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) => b.add(const ListingsRequested()),
      expect: () => [
        const ListingsState(status: ListingsStatus.loading),
        const ListingsState(
          status: ListingsStatus.failure,
          loadFailure: NetworkFailure('offline'),
        ),
      ],
    );

    blocTest<ListingsBloc, ListingsState>(
      'next-page failure preserves loaded items and current page',
      setUp: () {
        var call = 0;
        when(() => repo.getListings(any())).thenAnswer((_) async {
          call += 1;
          if (call == 1) return Success(firstPage);
          return const FailureResult(NetworkFailure('next page down'));
        });
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) async {
        b.add(const ListingsRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
      },
      expect: () => [
        const ListingsState(status: ListingsStatus.loading),
        ListingsState(
          status: ListingsStatus.success,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.paginationFailure,
          items: firstPage,
          hasReachedEnd: false,
          loadFailure: const NetworkFailure('next page down'),
        ),
      ],
    );

    blocTest<ListingsBloc, ListingsState>(
      'retry after next-page failure appends the failed page once',
      setUp: () {
        var call = 0;
        when(() => repo.getListings(any())).thenAnswer((_) async {
          call += 1;
          if (call == 1) return Success(firstPage);
          if (call == 2) {
            return const FailureResult(NetworkFailure('next page down'));
          }
          return Success(secondPage);
        });
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) async {
        b.add(const ListingsRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(
          const ListingsNextPageRequested(isExplicitRetry: true),
        );
      },
      expect: () => [
        const ListingsState(status: ListingsStatus.loading),
        ListingsState(
          status: ListingsStatus.success,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.paginationFailure,
          items: firstPage,
          hasReachedEnd: false,
          loadFailure: const NetworkFailure('next page down'),
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.success,
          items: [...firstPage, ...secondPage],
          page: 1,
          hasReachedEnd: true,
        ),
      ],
      verify: (_) {
        final queries = verify(() => repo.getListings(captureAny())).captured;
        expect(queries.map((q) => (q as ListingsQuery).page), [0, 1, 1]);
      },
    );

    blocTest<ListingsBloc, ListingsState>(
      'retry failure keeps loaded items and retry state',
      setUp: () {
        var call = 0;
        when(() => repo.getListings(any())).thenAnswer((_) async {
          call += 1;
          if (call == 1) return Success(firstPage);
          return FailureResult(NetworkFailure('next page down $call'));
        });
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) async {
        b.add(const ListingsRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(
          const ListingsNextPageRequested(isExplicitRetry: true),
        );
      },
      expect: () => [
        const ListingsState(status: ListingsStatus.loading),
        ListingsState(
          status: ListingsStatus.success,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.paginationFailure,
          items: firstPage,
          hasReachedEnd: false,
          loadFailure: const NetworkFailure('next page down 2'),
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.paginationFailure,
          items: firstPage,
          hasReachedEnd: false,
          loadFailure: const NetworkFailure('next page down 3'),
        ),
      ],
    );

    blocTest<ListingsBloc, ListingsState>(
      'next-page request is ignored while paginationFailure',
      setUp: () {
        var call = 0;
        when(() => repo.getListings(any())).thenAnswer((_) async {
          call += 1;
          if (call == 1) return Success(firstPage);
          return const FailureResult(NetworkFailure('next page down'));
        });
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) async {
        b.add(const ListingsRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const ListingsState(status: ListingsStatus.loading),
        ListingsState(
          status: ListingsStatus.success,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.paginationFailure,
          items: firstPage,
          hasReachedEnd: false,
          loadFailure: const NetworkFailure('next page down'),
        ),
      ],
      verify: (_) {
        final queries = verify(() => repo.getListings(captureAny())).captured;
        expect(queries.map((q) => (q as ListingsQuery).page), [0, 1]);
      },
    );

    blocTest<ListingsBloc, ListingsState>(
      'explicit retry after paginationFailure loads the failed next page',
      setUp: () {
        var call = 0;
        when(() => repo.getListings(any())).thenAnswer((_) async {
          call += 1;
          if (call == 1) return Success(firstPage);
          if (call == 2) {
            return const FailureResult(NetworkFailure('next page down'));
          }
          return Success(secondPage);
        });
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) async {
        b.add(const ListingsRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(
          const ListingsNextPageRequested(isExplicitRetry: true),
        );
      },
      expect: () => [
        const ListingsState(status: ListingsStatus.loading),
        ListingsState(
          status: ListingsStatus.success,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.paginationFailure,
          items: firstPage,
          hasReachedEnd: false,
          loadFailure: const NetworkFailure('next page down'),
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.success,
          items: [...firstPage, ...secondPage],
          page: 1,
          hasReachedEnd: true,
        ),
      ],
      verify: (_) {
        final queries = verify(() => repo.getListings(captureAny())).captured;
        expect(queries.map((q) => (q as ListingsQuery).page), [0, 1, 1]);
      },
    );

    blocTest<ListingsBloc, ListingsState>(
      'search change after paginationFailure resets pagination state',
      setUp: () {
        var call = 0;
        when(() => repo.getListings(any())).thenAnswer((_) async {
          call += 1;
          if (call == 1) return Success(firstPage);
          if (call == 2) {
            return const FailureResult(NetworkFailure('next page down'));
          }
          return Success([_listing('search-0')]);
        });
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) async {
        b.add(const ListingsRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsSearchChanged('bmw'));
      },
      expect: () => [
        const ListingsState(status: ListingsStatus.loading),
        ListingsState(
          status: ListingsStatus.success,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.loadingMore,
          items: firstPage,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.paginationFailure,
          items: firstPage,
          hasReachedEnd: false,
          loadFailure: const NetworkFailure('next page down'),
        ),
        const ListingsState(
          status: ListingsStatus.loading,
          search: 'bmw',
          items: [],
          page: 0,
          hasReachedEnd: false,
        ),
        ListingsState(
          status: ListingsStatus.success,
          search: 'bmw',
          items: [_listing('search-0')],
          page: 0,
          hasReachedEnd: true,
        ),
      ],
    );

    blocTest<ListingsBloc, ListingsState>(
      'duplicate next-page requests do not overlap while loadingMore',
      setUp: () {
        when(() => repo.getListings(any())).thenAnswer((invocation) async {
          final q = invocation.positionalArguments.single as ListingsQuery;
          if (q.page == 0) return Success(firstPage);
          await Future<void>.delayed(const Duration(milliseconds: 50));
          return Success(secondPage);
        });
      },
      build: () => ListingsBloc(
        getListings: GetListings(repo),
        lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      ),
      act: (b) async {
        b.add(const ListingsRequested());
        await Future<void>.delayed(Duration.zero);
        b.add(const ListingsNextPageRequested());
        b.add(const ListingsNextPageRequested());
        await Future<void>.delayed(Duration.zero);
      },
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        final queries = verify(() => repo.getListings(captureAny())).captured;
        expect(queries.map((q) => (q as ListingsQuery).page), [0, 1]);
      },
    );
  });
}
