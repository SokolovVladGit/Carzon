import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/domain/entities/buyer_listing_vin_report_source_result.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/repositories/listings_repository.dart';
import 'package:carzon/features/listings/domain/usecases/get_listings.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_bloc.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_event.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/noop_last_applied_listing_discovery_repository.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

Listing _item(String id) => Listing(
  id: id,
  title: 't',
  make: 'M',
  model: 'm',
  year: 2020,
  priceEur: 1,
  mileageKm: 1,
  type: ListingType.sale,
  city: 'c',
  marketRegion: MarketRegion.transnistria,
  createdAt: DateTime.utc(2026, 1, 1),
  status: ListingStatus.active,
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
    'ListingsBodyTypeFilterChanged issues query with bodyType set',
    setUp: () {
      when(
        () => repo.getListings(any()),
      ).thenAnswer((_) async => const Success([]));
    },
    build: () => ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    ),
    act: (b) => b.add(const ListingsBodyTypeFilterChanged(ListingBodyType.suv)),
    expect: () => [
      isA<ListingsState>()
          .having((s) => s.status, 'status', ListingsStatus.loading)
          .having(
            (s) => s.bodyTypeFilter,
            'bodyTypeFilter',
            ListingBodyType.suv,
          ),
      isA<ListingsState>().having(
        (s) => s.status,
        'status',
        ListingsStatus.success,
      ),
    ],
    verify: (_) {
      final q =
          verify(() => repo.getListings(captureAny())).captured.single
              as ListingsQuery;
      expect(q.bodyType, ListingBodyType.suv);
    },
  );

  blocTest<ListingsBloc, ListingsState>(
    'initial ListingsRequested load does not apply body type filter',
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
      expect(q.bodyType, isNull);
    },
  );

  test('pagination preserves selected body type', () async {
    when(() => repo.getListings(any())).thenAnswer((invocation) async {
      final q = invocation.positionalArguments.first as ListingsQuery;
      if (q.page == 0) {
        return Success(
          List.generate(AppConstants.defaultPageSize, (i) => _item('p0-$i')),
        );
      }
      return Success([_item('p1-0')]);
    });

    final bloc = ListingsBloc(
      getListings: GetListings(repo),
      lastAppliedDiscovery: const NoopLastAppliedListingDiscoveryRepository(),
    );

    bloc.add(const ListingsBodyTypeFilterChanged(ListingBodyType.suv));
    await bloc.stream.firstWhere(
      (s) =>
          s.status == ListingsStatus.success &&
          s.bodyTypeFilter == ListingBodyType.suv &&
          s.page == 0 &&
          !s.hasReachedEnd,
    );

    bloc.add(const ListingsNextPageRequested());
    await bloc.stream.firstWhere(
      (s) =>
          s.status == ListingsStatus.success &&
          s.bodyTypeFilter == ListingBodyType.suv &&
          s.page == 1,
    );

    final captured = verify(() => repo.getListings(captureAny())).captured;
    expect(captured.length, 2);
    expect((captured[0] as ListingsQuery).bodyType, ListingBodyType.suv);
    expect((captured[0] as ListingsQuery).page, 0);
    expect((captured[1] as ListingsQuery).bodyType, ListingBodyType.suv);
    expect((captured[1] as ListingsQuery).page, 1);

    await bloc.close();
  });

  blocTest<ListingsBloc, ListingsState>(
    'ListingsFiltersCleared clears body type filter',
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
      ..add(const ListingsBodyTypeFilterChanged(ListingBodyType.sedan))
      ..add(const ListingsFiltersCleared()),
    verify: (_) {
      final captured = verify(() => repo.getListings(captureAny())).captured;
      expect(captured.length, 2);
      expect((captured.last as ListingsQuery).bodyType, isNull);
    },
  );
}
