import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/filter_alerts_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
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

class _MockFilterAlertsRepository extends Mock
    implements FilterAlertsRepository {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockDeliveryOrchestrator extends Mock
    implements FilterAlertDeliveryOrchestrator {}

FilterAlertSettings _row({
  required ListingDiscoveryCriteria? criteria,
  required bool notificationsEnabled,
}) => FilterAlertSettings(
  userId: 'u',
  criteria: criteria,
  notificationsEnabled: notificationsEnabled,
  createdAt: DateTime.utc(2026, 2, 1),
  updatedAt: DateTime.utc(2026, 2, 2),
);

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
  typeIn: base.typeIn,
  priceCurrencyFilter: base.priceCurrencyFilter,
  sort: sort,
);

/// Replace the active dotenv snapshot so `Env.pushNotificationsEnabled`
/// flips deterministically per test. Keep the required Supabase keys
/// present so any incidental access does not throw `StateError`.
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
      _row(
        criteria: const ListingDiscoveryCriteria(),
        notificationsEnabled: false,
      ),
    );
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  late _MockFilterAlertsRepository filterRepo;
  late _MockNotificationsRepository notifRepo;
  late _MockDeliveryOrchestrator orchestrator;

  NotificationPreferences prefsAllOn() => NotificationPreferences(
    userId: 'u',
    globalEnabled: true,
    messagesEnabled: true,
    filterAlertsEnabled: true,
    createdAt: DateTime.utc(2026, 1, 1),
    updatedAt: DateTime.utc(2026, 1, 2),
  );

  BrowseCatalogFilterAlertsCubit buildCubit() {
    return BrowseCatalogFilterAlertsCubit(
      getSettings: GetFilterAlertSettings(filterRepo),
      saveCriteria: SaveFilterAlertCriteria(filterRepo),
      clearCriteria: ClearFilterAlertCriteria(filterRepo),
      notificationsRepository: notifRepo,
      deliveryOrchestrator: orchestrator,
    );
  }

  setUp(() {
    // Default to push-enabled so the pre-existing enable-delivery tests
    // exercise the orchestrator path. Push-disabled tests below opt out
    // explicitly via `_setPushEnv(enabled: false)`.
    _setPushEnv(enabled: true);

    filterRepo = _MockFilterAlertsRepository();
    notifRepo = _MockNotificationsRepository();
    orchestrator = _MockDeliveryOrchestrator();

    when(
      () => notifRepo.getMyPreferences(),
    ).thenAnswer((_) async => Success(prefsAllOn()));
  });

  test('baseline browse snapshot cannot enable alert deliveries', () async {
    final backend = _row(criteria: null, notificationsEnabled: false);

    when(() => filterRepo.loadMine()).thenAnswer((_) async => Success(backend));

    final cubit = buildCubit();
    await cubit.refresh();

    final outcome = await cubit.handleCatalogFilterBell(
      draftCriteria: listingDiscoveryCriteriaFromBrowseStateForAlert(
        const ListingsState(),
      ),
      authenticated: true,
    );

    expect(outcome, BrowseCatalogBellOutcome.criteriaTooBroad);
    verifyNever(
      () => filterRepo.saveCriteria(
        any(),
        notificationsEnabled: any(named: 'notificationsEnabled'),
      ),
    );
  });

  test(
    'enabling persists criteria with search payload then activates deliveries',
    () async {
      var backendSnapshot = _row(criteria: null, notificationsEnabled: false);
      final bmwCrit = ListingDiscoveryCriteria(
        search: 'diesel',
        make: 'BMW',
        marketRegion: MarketRegion.transnistria,
        sort: ListingSortOption.lowestMileageFirst,
      );
      final postSaveBackend = FilterAlertSettings(
        userId: 'u',
        criteria: bmwCrit,
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 2, 1),
        updatedAt: DateTime.utc(2026, 2, 5),
      );
      final postEnableBackend = FilterAlertSettings(
        userId: 'u',
        criteria: bmwCrit,
        notificationsEnabled: true,
        createdAt: DateTime.utc(2026, 2, 1),
        updatedAt: DateTime.utc(2026, 2, 6),
      );

      when(
        () => filterRepo.loadMine(),
      ).thenAnswer((_) async => Success(backendSnapshot));

      when(
        () => filterRepo.saveCriteria(
          any(),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((inv) async {
        final passed =
            inv.positionalArguments.first as ListingDiscoveryCriteria;
        expect(passed.search, 'diesel');
        expect(passed.make, 'BMW');
        backendSnapshot = postSaveBackend;
        return Success(postSaveBackend);
      });

      when(() => orchestrator.enableDeliveries(any())).thenAnswer((_) async {
        backendSnapshot = postEnableBackend;
        return Success(postEnableBackend);
      });

      final cubit = buildCubit();
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: bmwCrit,
        authenticated: true,
      );

      expect(outcome, BrowseCatalogBellOutcome.deliveriesEnabled);
      verify(
        () => filterRepo.saveCriteria(
          any(
            that: predicate<ListingDiscoveryCriteria>(
              (c) => c.search == 'diesel' && c.make == 'BMW',
            ),
          ),
          notificationsEnabled: any(named: 'notificationsEnabled'),
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
          settings: _row(criteria: toyotaCrit, notificationsEnabled: true),
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
          settings: _row(criteria: savedToyota, notificationsEnabled: true),
        ),
      );

      expect(cubit.browseBellShowsActiveDraft(toyotaDraft), isTrue);
    },
  );

  group('push-disabled build', () {
    test(
      'eligible bell tap persists criteria, returns criteriaSavedDeliveryUnavailable, '
      'never touches orchestrator/prefs/permission',
      () async {
        _setPushEnv(enabled: false);

        var backendSnapshot = _row(criteria: null, notificationsEnabled: false);
        final toyotaCrit = ListingDiscoveryCriteria(
          make: 'Toyota',
          marketRegion: MarketRegion.transnistria,
        );
        final postSaveBackend = FilterAlertSettings(
          userId: 'u',
          criteria: toyotaCrit,
          notificationsEnabled: false,
          createdAt: DateTime.utc(2026, 2, 1),
          updatedAt: DateTime.utc(2026, 2, 5),
        );

        when(
          () => filterRepo.loadMine(),
        ).thenAnswer((_) async => Success(backendSnapshot));

        when(
          () => filterRepo.saveCriteria(
            any(),
            notificationsEnabled: any(named: 'notificationsEnabled'),
          ),
        ).thenAnswer((inv) async {
          backendSnapshot = postSaveBackend;
          return Success(postSaveBackend);
        });

        final cubit = buildCubit();
        await cubit.refresh();

        final outcome = await cubit.handleCatalogFilterBell(
          draftCriteria: toyotaCrit,
          authenticated: true,
        );

        expect(
          outcome,
          BrowseCatalogBellOutcome.criteriaSavedDeliveryUnavailable,
        );

        verify(
          () => filterRepo.saveCriteria(
            any(
              that: predicate<ListingDiscoveryCriteria>(
                (c) => c.make == 'Toyota',
              ),
            ),
            notificationsEnabled: false,
          ),
        ).called(1);

        verifyNever(() => orchestrator.enableDeliveries(any()));
        verifyNever(() => orchestrator.disableDeliveriesFlagOnly());
        verifyNever(
          () => notifRepo.updateMyPreferences(
            globalEnabled: any(named: 'globalEnabled'),
            messagesEnabled: any(named: 'messagesEnabled'),
            filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
          ),
        );

        expect(cubit.state.bellBusy, isFalse);
        expect(cubit.state.deliveryFullyEnabled, isFalse);
      },
    );

    test(
      'eligible bell tap on already-saved-matching criteria now toggles OFF: '
      'returns savedAlertCleared and never re-saves',
      () async {
        _setPushEnv(enabled: false);

        final toyotaCrit = ListingDiscoveryCriteria(
          make: 'Toyota',
          marketRegion: MarketRegion.transnistria,
        );
        var backend = _row(criteria: toyotaCrit, notificationsEnabled: false);
        final clearedRow = _row(criteria: null, notificationsEnabled: false);

        when(
          () => filterRepo.loadMine(),
        ).thenAnswer((_) async => Success(backend));
        when(() => filterRepo.clearPersistedCriteria()).thenAnswer((_) async {
          backend = clearedRow;
          return Success(clearedRow);
        });

        final cubit = buildCubit();
        await cubit.refresh();

        final outcome = await cubit.handleCatalogFilterBell(
          draftCriteria: toyotaCrit,
          authenticated: true,
        );

        expect(outcome, BrowseCatalogBellOutcome.savedAlertCleared);
        verify(() => filterRepo.clearPersistedCriteria()).called(1);
        verifyNever(
          () => filterRepo.saveCriteria(
            any(),
            notificationsEnabled: any(named: 'notificationsEnabled'),
          ),
        );
        verifyNever(() => orchestrator.enableDeliveries(any()));
      },
    );

    test('sort-only/default criteria remain ineligible (broad)', () async {
      _setPushEnv(enabled: false);

      final cubit = buildCubit();
      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(_row(criteria: null, notificationsEnabled: false)),
      );
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: listingDiscoveryCriteriaFromBrowseStateForAlert(
          const ListingsState(sortOption: ListingSortOption.priceLowToHigh),
        ),
        authenticated: true,
      );

      expect(outcome, BrowseCatalogBellOutcome.criteriaTooBroad);
      verifyNever(
        () => filterRepo.saveCriteria(
          any(),
          notificationsEnabled: any(named: 'notificationsEnabled'),
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
          settings: _row(criteria: critToyota, notificationsEnabled: false),
        ),
      );

      expect(
        cubit.catalogBellSavedWithoutDeliveryVisibleForApplied(toyotaApplied),
        isTrue,
      );
      // Mutually exclusive with active-delivery FAB ornament.
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
          settings: _row(criteria: critToyota, notificationsEnabled: true),
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
          settings: _row(criteria: critToyota, notificationsEnabled: false),
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
          settings: _row(criteria: toyotaCrit, notificationsEnabled: false),
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
          settings: _row(criteria: toyotaCrit, notificationsEnabled: true),
        ),
      );

      expect(
        cubit.browseBellShowsSavedDraftWithoutDelivery(toyotaCrit),
        isFalse,
      );
      expect(cubit.browseBellShowsActiveDraft(toyotaCrit), isTrue);
    });

    test(
      'matched draft with delivery fully off (push-disabled env): tap clears '
      'the saved alert via clearPersistedCriteria, returns savedAlertCleared, '
      'and both saved-off helpers return false afterwards',
      () async {
        _setPushEnv(enabled: false);

        final toyotaCrit = ListingDiscoveryCriteria(
          make: 'Toyota',
          marketRegion: MarketRegion.transnistria,
        );
        var backend = _row(criteria: toyotaCrit, notificationsEnabled: false);
        final clearedRow = _row(criteria: null, notificationsEnabled: false);

        when(
          () => filterRepo.loadMine(),
        ).thenAnswer((_) async => Success(backend));
        when(() => filterRepo.clearPersistedCriteria()).thenAnswer((_) async {
          backend = clearedRow;
          return Success(clearedRow);
        });

        final cubit = buildCubit();
        await cubit.refresh();
        // Sanity: saved-off helpers report the matching state before tap.
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
        );

        expect(outcome, BrowseCatalogBellOutcome.savedAlertCleared);
        verify(() => filterRepo.clearPersistedCriteria()).called(1);
        verifyNever(() => orchestrator.enableDeliveries(any()));
        verifyNever(() => orchestrator.disableDeliveriesFlagOnly());
        verifyNever(
          () => filterRepo.saveCriteria(
            any(),
            notificationsEnabled: any(named: 'notificationsEnabled'),
          ),
        );

        // After the toggle clears the row, both indicator helpers must
        // return false so the inline banner + FAB ornament drop.
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

    test('matched draft with delivery fully on: tap clears the saved alert '
        '(criteria + delivery flag drop in a single upsert), returns '
        'savedAlertCleared, never calls disableDeliveriesFlagOnly', () async {
      final toyotaCrit = ListingDiscoveryCriteria(
        make: 'Toyota',
        marketRegion: MarketRegion.transnistria,
      );
      var backend = _row(criteria: toyotaCrit, notificationsEnabled: true);
      final clearedRow = _row(criteria: null, notificationsEnabled: false);

      when(
        () => filterRepo.loadMine(),
      ).thenAnswer((_) async => Success(backend));
      when(() => filterRepo.clearPersistedCriteria()).thenAnswer((_) async {
        backend = clearedRow;
        return Success(clearedRow);
      });

      final cubit = buildCubit();
      await cubit.refresh();
      // Sanity: active helpers fire before the toggle.
      const toyotaApplied = ListingsState(
        make: 'Toyota',
        regionFilter: MarketRegionFilter.transnistria,
      );
      expect(cubit.browseBellShowsActiveDraft(toyotaCrit), isTrue);
      expect(cubit.catalogBellBadgeVisibleForApplied(toyotaApplied), isTrue);

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: toyotaCrit,
        authenticated: true,
      );

      expect(outcome, BrowseCatalogBellOutcome.savedAlertCleared);
      verify(() => filterRepo.clearPersistedCriteria()).called(1);
      verifyNever(() => orchestrator.disableDeliveriesFlagOnly());

      // After clearing, all four indicator helpers must report false.
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
    });

    test('clear failure returns savedAlertClearFailed and leaves saved row '
        'in place; never falls back to disable-flag-only', () async {
      final toyotaCrit = ListingDiscoveryCriteria(
        make: 'Toyota',
        marketRegion: MarketRegion.transnistria,
      );
      final savedRow = _row(criteria: toyotaCrit, notificationsEnabled: true);

      when(
        () => filterRepo.loadMine(),
      ).thenAnswer((_) async => Success(savedRow));
      when(
        () => filterRepo.clearPersistedCriteria(),
      ).thenAnswer((_) async => const FailureResult(ServerFailure('boom')));

      final cubit = buildCubit();
      await cubit.refresh();

      final outcome = await cubit.handleCatalogFilterBell(
        draftCriteria: toyotaCrit,
        authenticated: true,
      );

      expect(outcome, BrowseCatalogBellOutcome.savedAlertClearFailed);
      verify(() => filterRepo.clearPersistedCriteria()).called(1);
      verifyNever(() => orchestrator.disableDeliveriesFlagOnly());
      expect(cubit.state.bellBusy, isFalse);
    });
  });
}
