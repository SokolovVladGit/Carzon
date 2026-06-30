import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/recent_searches/domain/usecases/record_recent_search.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

final class _CountingRecordRecentSearch implements RecordRecentSearch {
  int callCount = 0;
  ListingDiscoveryCriteria? lastCriteria;

  @override
  Future<void> call(
    ListingDiscoveryCriteria criteria, {
    DateTime? searchedAt,
  }) async {
    callCount++;
    lastCriteria = criteria;
  }
}

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

void main() {
  late _MockListingsRepository repo;
  late _CountingRecordRecentSearch recorder;

  setUpAll(() {
    registerFallbackValue(const ListingsQuery());
  });

  setUp(() {
    repo = _MockListingsRepository();
    recorder = _CountingRecordRecentSearch();
    when(() => repo.fetchBuyerVinReportSources(any())).thenAnswer(
      (_) async => const Success(BuyerListingVinReportLookupResult()),
    );
  });

  ListingsBloc buildBloc() => ListingsBloc(
    getListings: GetListings(repo),
    lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    recordRecentSearch: recorder,
  );

  blocTest<ListingsBloc, ListingsState>(
    'records after successful meaningful page-0 search submit',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => Success([_listing('1')]));
    },
    build: buildBloc,
    act: (b) => b.add(const ListingsSearchChanged('bmw')),
    verify: (_) {
      expect(recorder.callCount, 1);
      expect(recorder.lastCriteria?.search, 'bmw');
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'does not record default feed initial load',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: buildBloc,
    act: (b) => b.add(const ListingsRequested()),
    verify: (_) {
      expect(recorder.callCount, 0);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'does not record sort-only change',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: buildBloc,
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      sortOption: ListingSortOption.newestFirst,
    ),
    act: (b) => b.add(
      const ListingsFiltersApplied(
        make: null,
        model: null,
        minYear: null,
        maxYear: null,
        minPrice: null,
        maxPrice: null,
        maxMileage: null,
        city: null,
        typeFilter: ListingTypeFilter.any,
        sort: ListingSortOption.priceLowToHigh,
        regionFilter: MarketRegionFilter.both,
        bodyType: null,
        fuelType: null,
        transmissionType: null,
        drivetrain: null,
        priceCurrencyFilter: ListingPriceCurrencyFilter.any,
      ),
    ),
    verify: (_) {
      expect(recorder.callCount, 0);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'does not record failed page-0 fetch',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const FailureResult(ServerFailure('x')));
    },
    build: buildBloc,
    act: (b) => b.add(const ListingsSearchChanged('audi')),
    verify: (_) {
      expect(recorder.callCount, 0);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'does not record pagination loads',
    setUp: () {
      when(() => repo.getListings(any())).thenAnswer((invocation) async {
        final q = invocation.positionalArguments.first as ListingsQuery;
        if (q.page == 0) {
          return Success(List.generate(20, (i) => _listing('p0-$i')));
        }
        return Success([_listing('p1-0')]);
      });
    },
    build: buildBloc,
    act: (b) async {
      b.add(const ListingsSearchChanged('vw'));
      await Future<void>.delayed(Duration.zero);
      recorder.callCount = 0;
      b.add(const ListingsNextPageRequested());
    },
    verify: (_) {
      expect(recorder.callCount, 0);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'does not record hydration/reapply echo',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => Success([_listing('1')]));
    },
    build: buildBloc,
    act: (b) => b.add(
      ListingsHydratedFromDiscovery(
        const ListingDiscoveryCriteria(search: 'saved'),
      ),
    ),
    verify: (_) {
      expect(recorder.callCount, 0);
    },
  );
}
