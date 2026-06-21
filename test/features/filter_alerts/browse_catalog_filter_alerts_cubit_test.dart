import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/saved_searches_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/listings/domain/browse_state_for_alert_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_models.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/browse_catalog_filter_alerts_sl.dart';

class _MockSavedSearchesRepository extends Mock
    implements SavedSearchesRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockDeliveryOrchestrator extends Mock
    implements FilterAlertDeliveryOrchestrator {}

ListingDiscoveryCriteria _discoveryCriteriaWithSortOnly(
  ListingDiscoveryCriteria base,
  ListingSortOption sort,
) => ListingDiscoveryCriteria(
  search: base.search,
  make: base.make,
  model: base.model,
  minYear: base.minYear,
  maxYear: base.maxYear,
  minPrice: base.minPrice,
  maxPrice: base.maxPrice,
  maxMileage: base.maxMileage,
  city: base.city,
  marketRegion: base.marketRegion,
  bodyType: base.bodyType,
  fuelType: base.fuelType,
  transmissionType: base.transmissionType,
  drivetrain: base.drivetrain,
  typeIn: base.typeIn,
  priceCurrencyFilter: base.priceCurrencyFilter,
  sort: sort,
);

void _setPushEnv({required bool enabled}) {
  dotenv.testLoad(
    fileInput:
        '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=${enabled ? 'true' : 'false'}
''',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      testSavedSearch(criteria: const ListingDiscoveryCriteria()),
    );
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  late _MockSavedSearchesRepository savedSearchesRepo;
  late _MockNotificationsRepository notifRepo;
  late _MockDeliveryOrchestrator orchestrator;

  NotificationPreferences prefsAllOn() => NotificationPreferences(
    userId: 'u',
    globalEnabled: true,
    messagesEnabled: true,
    filterAlertsEnabled: true,
    priceDropsEnabled: false,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );

  BrowseCatalogFilterAlertsCubit buildCubit() {
    return buildTestBrowseCatalogFilterAlertsCubit(
      savedSearchesRepo: savedSearchesRepo,
      notificationsRepo: notifRepo,
      deliveryOrchestrator: orchestrator,
    );
  }

  setUp(() {
    _setPushEnv(enabled: true);

    savedSearchesRepo = _MockSavedSearchesRepository();
    notifRepo = _MockNotificationsRepository();
    orchestrator = _MockDeliveryOrchestrator();

    when(
      () => notifRepo.getMyPreferences(),
    ).thenAnswer((_) async => Success(prefsAllOn()));
    when(
      () => savedSearchesRepo.list(),
    ).thenAnswer((_) async => const Success([]));
  });

  test('baseline browse snapshot cannot enable alert deliveries', () async {
    final cubit = buildCubit();
    await cubit.refresh();

    final outcome = await cubit.handleCatalogFilterBell(
      draftCriteria: listingDiscoveryCriteriaFromBrowseStateForAlert(
        const ListingsState(),
      ),
      authenticated: true,
      autoName: 'Baseline',
    );

    expect(outcome, BrowseCatalogBellOutcome.criteriaTooBroad);
    verifyNever(
      () => savedSearchesRepo.create(
        name: any(named: 'name'),
        criteria: any(named: 'criteria'),
        alertsEnabled: any(named: 'alertsEnabled'),
      ),
    );
  });

  test(
    'enabling persists criteria with search payload then activates deliveries',
    () async {
      final bmwCrit = ListingDiscoveryCriteria(
        search: 'diesel',
        make: 'BMW',
        marketRegion: MarketRegion.transnistria,
        sort: ListingSortOption.lowestMileageFirst,
      );
      final postSave = testSavedSearch(
        id: 'ss-new',
        name: 'BMW search',
        criteria: bmwCrit,
        alertsEnabled: false,
      );
      final postEnable = testSavedSearch(
        id: 'ss-new',
        name: 'BMW search',
        criteria: bmwCrit,
        alertsEnabled: true,
      );

      when(
        () => savedSearchesRepo.create(
          name: any(named: 'name'),
          criteria: any(named: 'criteria'),
          alertsEnabled: any(named: 'alertsEnabled'),
        ),
      ).thenAnswer((inv) async {
        final passed =
            inv.namedArguments[#criteria] as ListingDiscoveryCriteria;
        expect(passed.search, 'diesel');
        expect(passed.make, 'BMW');
        return Success(postSave);
      });

      when(() => orchestrator.enableDeliveries(any())).thenAnswer((_) async {
        return Success(postEnable);
      });

      final cubit = buildCubit();
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: bmwCrit,
        authenticated: true,
        autoName: 'BMW search',
      );

      expect(outcome, BrowseCatalogBellOutcome.deliveriesEnabled);
      verify(
        () => savedSearchesRepo.create(
          name: 'BMW search',
          criteria: any(
            named: 'criteria',
            that: predicate<ListingDiscoveryCriteria>(
              (c) => c.search == 'diesel' && c.make == 'BMW',
            ),
          ),
          alertsEnabled: false,
        ),
      ).called(1);
      verify(() => orchestrator.enableDeliveries(any())).called(1);
    },
  );

  test(
    'catalog FAB badge only when applied discovery matches enabled row',
    () async {
      const toyotaFeed = ListingsState(
        make: 'Toyota',
        regionFilter: MarketRegionFilter.transnistria,
      );
      final toyotaCrit = listingDiscoveryCriteriaFromBrowseStateForAlert(
        toyotaFeed,
      );

      final cubit = buildCubit();
      cubit.emit(
        BrowseCatalogFilterAlertsState(
          phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          prefs: prefsAllOn(),
          savedSearches: [
            testSavedSearch(criteria: toyotaCrit, alertsEnabled: true),
          ],
        ),
      );

      expect(cubit.catalogBellBadgeVisibleForApplied(toyotaFeed), isTrue);

      const mismatchFeed = ListingsState(
        make: 'Mazda',
        regionFilter: MarketRegionFilter.transnistria,
      );
      expect(cubit.catalogBellBadgeVisibleForApplied(mismatchFeed), isFalse);

      const sortFeed = ListingsState(
        regionFilter: MarketRegionFilter.transnistria,
        sortOption: ListingSortOption.priceLowToHigh,
      );
      expect(cubit.catalogBellBadgeVisibleForApplied(sortFeed), isFalse);
    },
  );

  test(
    'sheet bell drafts track saved delivery row ignoring saved sort deltas',
    () async {
      final toyotaBaseline = listingDiscoveryCriteriaFromBrowseStateForAlert(
        const ListingsState(
          make: 'Toyota',
          regionFilter: MarketRegionFilter.transnistria,
        ),
      );
      final toyotaDraft = _discoveryCriteriaWithSortOnly(
        toyotaBaseline,
        ListingSortOption.priceLowToHigh,
      );
      final savedToyota = _discoveryCriteriaWithSortOnly(
        toyotaBaseline,
        ListingSortOption.priceHighToLow,
      );

      final cubit = buildCubit();
      cubit.emit(
        BrowseCatalogFilterAlertsState(
          phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          prefs: prefsAllOn(),
          savedSearches: [
            testSavedSearch(criteria: savedToyota, alertsEnabled: true),
          ],
        ),
      );

      expect(cubit.browseBellShowsActiveDraft(toyotaDraft), isTrue);
    },
  );

  test(
    'returns maxSavedSearchesReached when user already has five saved searches',
    () async {
      final cap = List.generate(
        5,
        (i) => testSavedSearch(
          id: 'ss-$i',
          name: 'Search $i',
          criteria: ListingDiscoveryCriteria(make: 'Make$i'),
        ),
      );
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success(cap));

      final cubit = buildCubit();
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: const ListingDiscoveryCriteria(
          make: 'Volvo',
          marketRegion: MarketRegion.transnistria,
        ),
        authenticated: true,
        autoName: 'Volvo',
      );

      expect(outcome, BrowseCatalogBellOutcome.maxSavedSearchesReached);
      verifyNever(
        () => savedSearchesRepo.create(
          name: any(named: 'name'),
          criteria: any(named: 'criteria'),
          alertsEnabled: any(named: 'alertsEnabled'),
        ),
      );
    },
  );

  group('push-disabled build', () {
    test(
      'eligible bell tap persists criteria, returns criteriaSavedDeliveryUnavailable, '
      'never touches orchestrator/prefs/permission',
      () async {
        _setPushEnv(enabled: false);

        final toyotaCrit = ListingDiscoveryCriteria(
          make: 'Toyota',
          marketRegion: MarketRegion.transnistria,
        );
        when(
          () => savedSearchesRepo.create(
            name: any(named: 'name'),
            criteria: any(named: 'criteria'),
            alertsEnabled: any(named: 'alertsEnabled'),
          ),
        ).thenAnswer(
          (_) async => Success(
            testSavedSearch(criteria: toyotaCrit, alertsEnabled: false),
          ),
        );

        final cubit = buildCubit();
        await cubit.refresh();

        final outcome = await cubit.handleCatalogFilterBell(
          draftCriteria: toyotaCrit,
          authenticated: true,
          autoName: 'Toyota',
        );

        expect(
          outcome,
          BrowseCatalogBellOutcome.criteriaSavedDeliveryUnavailable,
        );

        verify(
          () => savedSearchesRepo.create(
            name: 'Toyota',
            criteria: any(
              named: 'criteria',
              that: predicate<ListingDiscoveryCriteria>(
                (c) => c.make == 'Toyota',
              ),
            ),
            alertsEnabled: false,
          ),
        ).called(1);

        verifyNever(() => orchestrator.enableDeliveries(any()));
        verifyNever(
          () => notifRepo.updateMyPreferences(
            globalEnabled: any(named: 'globalEnabled'),
            messagesEnabled: any(named: 'messagesEnabled'),
            filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
            priceDropsEnabled: any(named: 'priceDropsEnabled'),
          ),
        );

        expect(cubit.state.bellBusy, isFalse);
        expect(
          cubit.state.deliveryFullyEnabledForCriteria(toyotaCrit),
          isFalse,
        );
      },
    );

    test('eligible bell tap on already-saved-matching criteria toggles OFF: '
        'returns savedAlertCleared and never re-creates', () async {
      _setPushEnv(enabled: false);

      final toyotaCrit = ListingDiscoveryCriteria(
        make: 'Toyota',
        marketRegion: MarketRegion.transnistria,
      );
      final saved = testSavedSearch(
        id: 'ss-toyota',
        criteria: toyotaCrit,
        alertsEnabled: false,
      );

      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([saved]));
      when(
        () => savedSearchesRepo.delete('ss-toyota'),
      ).thenAnswer((_) async => const Success(null));

      final cubit = buildCubit();
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: toyotaCrit,
        authenticated: true,
        autoName: 'Toyota',
      );

      expect(outcome, BrowseCatalogBellOutcome.savedAlertCleared);
      verify(() => savedSearchesRepo.delete('ss-toyota')).called(1);
      verifyNever(
        () => savedSearchesRepo.create(
          name: any(named: 'name'),
          criteria: any(named: 'criteria'),
          alertsEnabled: any(named: 'alertsEnabled'),
        ),
      );
      verifyNever(() => orchestrator.enableDeliveries(any()));
    });

    test('sort-only/default criteria remain ineligible (broad)', () async {
      _setPushEnv(enabled: false);

      final cubit = buildCubit();
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: listingDiscoveryCriteriaFromBrowseStateForAlert(
          const ListingsState(sortOption: ListingSortOption.priceLowToHigh),
        ),
        authenticated: true,
        autoName: 'Sort only',
      );

      expect(outcome, BrowseCatalogBellOutcome.criteriaTooBroad);
      verifyNever(
        () => savedSearchesRepo.create(
          name: any(named: 'name'),
          criteria: any(named: 'criteria'),
          alertsEnabled: any(named: 'alertsEnabled'),
        ),
      );
    });

    test('catalogBellSavedWithoutDeliveryVisibleForApplied true when saved '
        'matches applied feed but delivery is not fully enabled', () async {
      _setPushEnv(enabled: false);

      const toyotaApplied = ListingsState(
        make: 'Toyota',
        regionFilter: MarketRegionFilter.transnistria,
      );
      final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
        toyotaApplied,
      );

      final cubit = buildCubit();
      cubit.emit(
        BrowseCatalogFilterAlertsState(
          phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          prefs: prefsAllOn(),
          savedSearches: [
            testSavedSearch(criteria: critToyota, alertsEnabled: false),
          ],
        ),
      );

      expect(
        cubit.catalogBellSavedWithoutDeliveryVisibleForApplied(toyotaApplied),
        isTrue,
      );
      expect(cubit.catalogBellBadgeVisibleForApplied(toyotaApplied), isFalse);
    });

    test('catalogBellSavedWithoutDeliveryVisibleForApplied false when delivery '
        'is fully enabled (active-delivery ornament owns this case)', () async {
      const toyotaApplied = ListingsState(
        make: 'Toyota',
        regionFilter: MarketRegionFilter.transnistria,
      );
      final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
        toyotaApplied,
      );

      final cubit = buildCubit();
      cubit.emit(
        BrowseCatalogFilterAlertsState(
          phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          prefs: prefsAllOn(),
          savedSearches: [
            testSavedSearch(criteria: critToyota, alertsEnabled: true),
          ],
        ),
      );

      expect(
        cubit.catalogBellSavedWithoutDeliveryVisibleForApplied(toyotaApplied),
        isFalse,
      );
      expect(cubit.catalogBellBadgeVisibleForApplied(toyotaApplied), isTrue);
    });

    test('catalogBellSavedWithoutDeliveryVisibleForApplied false when applied '
        'feed differs from saved criteria', () async {
      _setPushEnv(enabled: false);

      const toyotaSavedFeed = ListingsState(
        make: 'Toyota',
        regionFilter: MarketRegionFilter.transnistria,
      );
      final critToyota = listingDiscoveryCriteriaFromBrowseStateForAlert(
        toyotaSavedFeed,
      );

      final cubit = buildCubit();
      cubit.emit(
        BrowseCatalogFilterAlertsState(
          phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          prefs: prefsAllOn(),
          savedSearches: [
            testSavedSearch(criteria: critToyota, alertsEnabled: false),
          ],
        ),
      );

      const skodaApplied = ListingsState(
        make: 'Skoda',
        regionFilter: MarketRegionFilter.transnistria,
      );
      expect(
        cubit.catalogBellSavedWithoutDeliveryVisibleForApplied(skodaApplied),
        isFalse,
      );
    });

    test('browseBellShowsSavedDraftWithoutDelivery is true for matching saved '
        'criteria when delivery is not fully enabled', () async {
      _setPushEnv(enabled: false);

      final toyotaCrit = ListingDiscoveryCriteria(
        make: 'Toyota',
        marketRegion: MarketRegion.transnistria,
      );

      final cubit = buildCubit();
      cubit.emit(
        BrowseCatalogFilterAlertsState(
          phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          prefs: prefsAllOn(),
          savedSearches: [
            testSavedSearch(criteria: toyotaCrit, alertsEnabled: false),
          ],
        ),
      );

      expect(
        cubit.browseBellShowsSavedDraftWithoutDelivery(toyotaCrit),
        isTrue,
      );
      expect(cubit.browseBellShowsActiveDraft(toyotaCrit), isFalse);
    });

    test('browseBellShowsSavedDraftWithoutDelivery is false when delivery is '
        'fully enabled (covered by active state instead)', () async {
      final toyotaCrit = ListingDiscoveryCriteria(
        make: 'Toyota',
        marketRegion: MarketRegion.transnistria,
      );

      final cubit = buildCubit();
      cubit.emit(
        BrowseCatalogFilterAlertsState(
          phase: BrowseCatalogFilterAlertsLoadPhase.ready,
          prefs: prefsAllOn(),
          savedSearches: [
            testSavedSearch(criteria: toyotaCrit, alertsEnabled: true),
          ],
        ),
      );

      expect(
        cubit.browseBellShowsSavedDraftWithoutDelivery(toyotaCrit),
        isFalse,
      );
      expect(cubit.browseBellShowsActiveDraft(toyotaCrit), isTrue);
    });

    test(
      'matched draft with delivery fully off (push-disabled env): tap deletes '
      'the saved search, returns savedAlertCleared, and helpers return false '
      'afterwards',
      () async {
        _setPushEnv(enabled: false);

        final toyotaCrit = ListingDiscoveryCriteria(
          make: 'Toyota',
          marketRegion: MarketRegion.transnistria,
        );
        final saved = testSavedSearch(
          id: 'ss-toyota',
          criteria: toyotaCrit,
          alertsEnabled: false,
        );

        final searches = [saved];
        when(
          () => savedSearchesRepo.list(),
        ).thenAnswer((_) async => Success(List.of(searches)));
        when(() => savedSearchesRepo.delete('ss-toyota')).thenAnswer((_) async {
          searches.clear();
          return const Success(null);
        });

        final cubit = buildCubit();
        await cubit.refresh();
        const toyotaApplied = ListingsState(
          make: 'Toyota',
          regionFilter: MarketRegionFilter.transnistria,
        );
        expect(
          cubit.browseBellShowsSavedDraftWithoutDelivery(toyotaCrit),
          isTrue,
        );
        expect(
          cubit.catalogBellSavedWithoutDeliveryVisibleForApplied(toyotaApplied),
          isTrue,
        );

        final outcome = await cubit.handleCatalogFilterBell(
          draftCriteria: toyotaCrit,
          authenticated: true,
          autoName: 'Toyota',
        );

        expect(outcome, BrowseCatalogBellOutcome.savedAlertCleared);
        verify(() => savedSearchesRepo.delete('ss-toyota')).called(1);
        verifyNever(() => orchestrator.enableDeliveries(any()));
        verifyNever(
          () => savedSearchesRepo.create(
            name: any(named: 'name'),
            criteria: any(named: 'criteria'),
            alertsEnabled: any(named: 'alertsEnabled'),
          ),
        );

        expect(
          cubit.browseBellShowsSavedDraftWithoutDelivery(toyotaCrit),
          isFalse,
        );
        expect(
          cubit.catalogBellSavedWithoutDeliveryVisibleForApplied(toyotaApplied),
          isFalse,
        );
      },
    );

    test(
      'matched draft with delivery fully on: tap deletes saved search, '
      'returns savedAlertCleared, never calls orchestrator disable',
      () async {
        final toyotaCrit = ListingDiscoveryCriteria(
          make: 'Toyota',
          marketRegion: MarketRegion.transnistria,
        );
        final saved = testSavedSearch(
          id: 'ss-toyota',
          criteria: toyotaCrit,
          alertsEnabled: true,
        );

        final searches = [saved];
        when(
          () => savedSearchesRepo.list(),
        ).thenAnswer((_) async => Success(List.of(searches)));
        when(() => savedSearchesRepo.delete('ss-toyota')).thenAnswer((_) async {
          searches.clear();
          return const Success(null);
        });

        final cubit = buildCubit();
        await cubit.refresh();
        const toyotaApplied = ListingsState(
          make: 'Toyota',
          regionFilter: MarketRegionFilter.transnistria,
        );
        expect(cubit.browseBellShowsActiveDraft(toyotaCrit), isTrue);
        expect(cubit.catalogBellBadgeVisibleForApplied(toyotaApplied), isTrue);

        final outcome = await cubit.handleCatalogFilterBell(
          draftCriteria: toyotaCrit,
          authenticated: true,
          autoName: 'Toyota',
        );

        expect(outcome, BrowseCatalogBellOutcome.savedAlertCleared);
        verify(() => savedSearchesRepo.delete('ss-toyota')).called(1);
        verifyNever(() => orchestrator.disableDeliveries(any()));

        expect(cubit.browseBellShowsActiveDraft(toyotaCrit), isFalse);
        expect(cubit.catalogBellBadgeVisibleForApplied(toyotaApplied), isFalse);
        expect(
          cubit.browseBellShowsSavedDraftWithoutDelivery(toyotaCrit),
          isFalse,
        );
        expect(
          cubit.catalogBellSavedWithoutDeliveryVisibleForApplied(toyotaApplied),
          isFalse,
        );
      },
    );

    test('delete failure returns savedAlertClearFailed and leaves saved row '
        'in place', () async {
      final toyotaCrit = ListingDiscoveryCriteria(
        make: 'Toyota',
        marketRegion: MarketRegion.transnistria,
      );
      final saved = testSavedSearch(
        id: 'ss-toyota',
        criteria: toyotaCrit,
        alertsEnabled: true,
      );

      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => Success([saved]));
      when(
        () => savedSearchesRepo.delete('ss-toyota'),
      ).thenAnswer((_) async => const FailureResult(ServerFailure('boom')));

      final cubit = buildCubit();
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: toyotaCrit,
        authenticated: true,
        autoName: 'Toyota',
      );

      expect(outcome, BrowseCatalogBellOutcome.savedAlertClearFailed);
      verify(() => savedSearchesRepo.delete('ss-toyota')).called(1);
      expect(cubit.state.bellBusy, isFalse);
    });
  });
}
