import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/constants/app_constants.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
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

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/noop_last_applied_listing_discovery_repository.dart';
import '../../helpers/noop_record_recent_search.dart';

class _MockListingsRepository extends Mock implements ListingsRepository {}

ListingsQuery _queryFromState(ListingsState state) {
  return ListingDiscoveryCriteria(
    search: state.search,
    make: state.make,
    model: state.model,
    minYear: state.minYear,
    maxYear: state.maxYear,
    minPrice: state.minPrice,
    maxPrice: state.maxPrice,
    maxMileage: state.maxMileage,
    city: state.city,
    marketRegion: state.regionFilter.asMarketRegion,
    bodyType: state.bodyTypeFilter,
    fuelType: state.fuelTypeFilter,
    transmissionType: state.transmissionTypeFilter,
    drivetrain: state.drivetrainFilter,
    typeIn: state.typeFilter.asListingTypes,
    sort: state.sortOption,
    priceCurrencyFilter: state.priceCurrencyFilter,
  ).toListingsQuery(
    page: 0,
    pageSize: AppConstants.defaultPageSize,
    status: ListingStatus.active,
  );
}

void main() {
  late _MockListingsRepository repo;

  setUpAll(() {
    registerFallbackValue(const ListingsQuery());
  });

  setUp(() {
    repo = _MockListingsRepository();
  });

  group('default region filter', () {
    test('initial ListingsState uses all-regions (both)', () {
      const state = ListingsState();
      expect(state.regionFilter, MarketRegionFilter.both);
      expect(state.hasActiveDiscoveryConstraints, isFalse);
    });

    test('default query omits market_region', () {
      final q = _queryFromState(const ListingsState());
      expect(q.marketRegion, isNull);
      expect(q.status, ListingStatus.active);
    });

    test('default catalog shows no region chip', () {
      final l10n = ruStrings();
      const state = ListingsState();
      expect(listingsDiscoveryChips(state, l10n), isEmpty);
      expect(listingsDiscoveryActiveFilterGroupCount(state), 0);
    });
  });

  group('explicit region selection', () {
    test('Moldova maps to market_region moldova', () {
      final q = _queryFromState(
        const ListingsState(regionFilter: MarketRegionFilter.moldova),
      );
      expect(q.marketRegion, MarketRegion.moldova);
    });

    test('Transnistria maps to market_region transnistria', () {
      final q = _queryFromState(
        const ListingsState(regionFilter: MarketRegionFilter.transnistria),
      );
      expect(q.marketRegion, MarketRegion.transnistria);
    });

    test('Moldova shows region chip', () {
      final l10n = ruStrings();
      const state = ListingsState(regionFilter: MarketRegionFilter.moldova);
      final chips = listingsDiscoveryChips(state, l10n);
      expect(chips, hasLength(1));
      expect(chips.single.kind, ListingsDiscoveryChipKind.region);
      expect(chips.single.value, l10n.regionMoldova);
    });

    test('Transnistria shows region chip', () {
      final l10n = ruStrings();
      const state = ListingsState(
        regionFilter: MarketRegionFilter.transnistria,
      );
      final chips = listingsDiscoveryChips(state, l10n);
      expect(chips, hasLength(1));
      expect(chips.single.kind, ListingsDiscoveryChipKind.region);
      expect(chips.single.value, l10n.regionTransnistria);
    });
  });

  group('clearing region filter', () {
    test('chip removal resets to all-regions', () {
      const moldova = ListingsState(regionFilter: MarketRegionFilter.moldova);
      final cleared = listingsStateAfterDiscoveryChipRemoved(
        moldova,
        ListingsDiscoveryChipKind.region,
      );
      expect(cleared.regionFilter, MarketRegionFilter.both);
      expect(_queryFromState(cleared).marketRegion, isNull);
    });

    blocTest<ListingsBloc, ListingsState>(
      'ListingsFiltersCleared resets region to all-regions',
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
      act: (b) => b
        ..add(const ListingsRegionFilterChanged(MarketRegionFilter.moldova))
        ..add(const ListingsFiltersCleared()),
      verify: (_) {
        final last =
            verify(() => repo.getListings(captureAny())).captured.last
                as ListingsQuery;
        expect(last.marketRegion, isNull);
      },
    );
  });
}
