import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/utils/discovery_feed_chip_labels.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/noop_last_applied_listing_discovery_repository.dart';
import '../../helpers/noop_record_recent_search.dart';

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

void main() {
  late _MockListingsRepository repo;

  setUpAll(() {
    registerFallbackValue(const ListingsQuery());
  });

  setUp(() {
    repo = _MockListingsRepository();
    when(() => repo.fetchBuyerVinReportSources(any())).thenAnswer(
      (_) async => const Success(BuyerListingVinReportLookupResult()),
    );
  });

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved search clears search only',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      search: 'Audi',
      make: 'Skoda',
      minYear: 2022,
      maxYear: 2025,
      minPrice: 3000,
      maxPrice: 4000,
    ),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.search),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.search, isNull);
      expect(q.make, 'Skoda');
      expect(q.minYear, 2022);
      expect(q.maxYear, 2025);
      expect(q.minPrice, 3000);
      expect(q.maxPrice, 4000);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved make keeps other filters',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      make: 'Skoda',
      minYear: 2022,
      maxYear: 2025,
      minPrice: 3000,
      maxPrice: 4000,
    ),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.make),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.make, isNull);
      expect(q.minYear, 2022);
      expect(q.maxYear, 2025);
      expect(q.minPrice, 3000);
      expect(q.maxPrice, 4000);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved year keeps brand and price',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      make: 'Skoda',
      minYear: 2022,
      maxYear: 2025,
      minPrice: 3000,
      maxPrice: 4000,
    ),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.year),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.make, 'Skoda');
      expect(q.minYear, isNull);
      expect(q.maxYear, isNull);
      expect(q.minPrice, 3000);
      expect(q.maxPrice, 4000);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved priceRange keeps brand and year',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      make: 'Skoda',
      minYear: 2022,
      maxYear: 2025,
      minPrice: 3000,
      maxPrice: 4000,
    ),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(
        ListingsDiscoveryChipKind.priceRange,
      ),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.make, 'Skoda');
      expect(q.minYear, 2022);
      expect(q.maxYear, 2025);
      expect(q.minPrice, isNull);
      expect(q.maxPrice, isNull);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved last make chip clears active constraints',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => Success([_listing('1')]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () =>
        const ListingsState(status: ListingsStatus.success, make: 'Skoda'),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.make),
    ),
    expect: () => [
      const ListingsState(
        status: ListingsStatus.loading,
        make: null,
        page: 0,
        hasReachedEnd: false,
        items: [],
      ),
      ListingsState(
        status: ListingsStatus.success,
        items: [_listing('1')],
        page: 0,
        hasReachedEnd: true,
      ),
    ],
    verify: (bloc) {
      expect(bloc.state.hasActiveDiscoveryConstraints, isFalse);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved fuel clears fuel only',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      fuelTypeFilter: ListingFuelType.hybrid,
      transmissionTypeFilter: ListingTransmissionType.automatic,
      make: 'Toyota',
    ),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(ListingsDiscoveryChipKind.fuelType),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.fuelType, isNull);
      expect(q.transmissionType, ListingTransmissionType.automatic);
      expect(q.make, 'Toyota');
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved transmission clears transmission only',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      fuelTypeFilter: ListingFuelType.hybrid,
      transmissionTypeFilter: ListingTransmissionType.automatic,
    ),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(
        ListingsDiscoveryChipKind.transmissionType,
      ),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.fuelType, ListingFuelType.hybrid);
      expect(q.transmissionType, isNull);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'ListingsDiscoveryFilterRemoved drivetrain clears drivetrain only',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
      recordRecentSearch: NoopRecordRecentSearch(),
    ),
    seed: () => const ListingsState(
      status: ListingsStatus.success,
      drivetrainFilter: ListingDrivetrain.awd,
      fuelTypeFilter: ListingFuelType.hybrid,
    ),
    act: (b) => b.add(
      const ListingsDiscoveryFilterRemoved(
        ListingsDiscoveryChipKind.drivetrain,
      ),
    ),
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.drivetrain, isNull);
      expect(q.fuelType, ListingFuelType.hybrid);
    },
  );
}
