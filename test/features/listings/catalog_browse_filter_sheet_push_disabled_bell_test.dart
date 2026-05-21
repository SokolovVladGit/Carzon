// Widget coverage for Phase 4 + follow-up: catalog filter-alert sheet bell
// behavior when `PUSH_NOTIFICATIONS_ENABLED=false`.
//
// Asserts:
//  * eligible (non-vanilla) bell tap persists criteria via
//    `filterRepo.saveCriteria` while never touching the delivery
//    orchestrator, OS permission, prefs, or token sync;
//  * feedback is delivered **inline inside the sheet**: a header status
//    banner with localized success-shaped copy is rendered, and **no**
//    root snackbar is shown (neither the legacy technical
//    `filterAlertNotificationsPushDisabled` nor the previous
//    `catalogBrowseFilterBellSavedDeliveryUnavailableSnack`);
//  * the in-sheet bell glyph transitions into the distinct
//    saved-no-delivery visual (test hook key on the icon), never into
//    the fully-active `notifications_active` glyph;
//  * "Show cars" stays disabled while a bell operation is in flight, so
//    nothing can land on the listings page after the modal closes;
//  * an apply-only path (no bell tap) shows no inline banner and no
//    snackbar.

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/filter_alerts_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_browse_filter_alert_sheet_bell.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_alert_ui_constants.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_host.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

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
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 2),
    );

NotificationPreferences _prefsAllOn() => NotificationPreferences(
      userId: 'u',
      globalEnabled: true,
      messagesEnabled: true,
      filterAlertsEnabled: true,
      createdAt: DateTime.utc(2026, 5, 1),
      updatedAt: DateTime.utc(2026, 5, 2),
    );

/// Loads a deterministic push-disabled dotenv snapshot. Required keys
/// remain present so unrelated `Env._required` accesses cannot trip the
/// test setup.
void _loadPushDisabledEnv() {
  dotenv.testLoad(
    fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
  );
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      _row(criteria: null, notificationsEnabled: false),
    );
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  Widget buildSheet({
    required BrowseCatalogFilterAlertsCubit alertsCubit,
    required AuthCubit auth,
    required GlobalKey<ListingsFilterFormState> formKey,
    required ListingsState seedState,
    required ValueChanged<dynamic> onApply,
  }) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<BrowseCatalogFilterAlertsCubit>.value(value: alertsCubit),
        BlocProvider<AuthCubit>.value(value: auth),
      ],
      child: MaterialApp(
        locale: const Locale('ru'),
        supportedLocales: AppLocalizations.supportedLocales,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return ListingsFilterHost(
                filterFormExternalKey: formKey,
                // `applyEnabled` intentionally not driven by
                // `alerts.bellBusy` so the "Show cars" CTA never
                // visually flickers when the bell toggles. Bell
                // self-disables via the cubit's `bellBusy` flag.
                seed: ListingsFilterFormSeed.fromListingsState(seedState),
                onDismiss: () {},
                onApply: onApply,
                browseHeaderTrailing: CatalogBrowseFilterAlertSheetBell(
                  sheetFormKey: formKey,
                  sheetContext: context,
                  searchSnippet: () => '',
                  appliedState: seedState,
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  AuthCubit signedInAuth() {
    final auth = _MockAuthCubit();
    final state = AuthState.authenticated(
      const AuthUser(id: 'id', email: 'e@m.com'),
    );
    when(() => auth.state).thenReturn(state);
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: state,
    );
    return auth;
  }

  testWidgets(
    'push-disabled: tapping bell on eligible Toyota draft renders inline '
    'sheet banner (no root snackbar), persists criteria, never touches delivery',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      // Backend mirror — `refresh()` re-reads `loadMine()` after the bell
      // save, so the mock must reflect the persisted criteria for the
      // sheet bell to render the saved-no-delivery glyph deterministically.
      var backend = _row(criteria: null, notificationsEnabled: false);
      when(() => filterRepo.loadMine())
          .thenAnswer((_) async => Success(backend));
      when(() => notifRepo.getMyPreferences())
          .thenAnswer((_) async => Success(_prefsAllOn()));

      ListingDiscoveryCriteria? lastSavedCriteria;
      bool? lastSavedNotificationsEnabled;
      when(
        () => filterRepo.saveCriteria(
          any(),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((inv) async {
        lastSavedCriteria =
            inv.positionalArguments.first as ListingDiscoveryCriteria;
        lastSavedNotificationsEnabled =
            inv.namedArguments[#notificationsEnabled] as bool;
        backend = _row(
          criteria: lastSavedCriteria,
          notificationsEnabled: false,
        );
        return Success(backend);
      });

      final alertsCubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await alertsCubit.refresh();

      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(buildSheet(
        alertsCubit: alertsCubit,
        auth: auth,
        formKey: formKey,
        seedState: const ListingsState(
          make: 'Toyota',
          regionFilter: MarketRegionFilter.transnistria,
        ),
        onApply: (_) {},
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();

      // Criteria persisted with notifications_enabled = false (delivery
      // intentionally stays off in a push-disabled build).
      verify(
        () => filterRepo.saveCriteria(
          any(),
          notificationsEnabled: false,
        ),
      ).called(1);
      expect(lastSavedCriteria?.make, 'Toyota');
      expect(lastSavedNotificationsEnabled, isFalse);

      // No delivery orchestrator / prefs write / token sync side effects.
      verifyNever(() => orch.enableDeliveries(any()));
      verifyNever(() => orch.disableDeliveriesFlagOnly());
      verifyNever(
        () => notifRepo.updateMyPreferences(
          globalEnabled: any(named: 'globalEnabled'),
          messagesEnabled: any(named: 'messagesEnabled'),
          filterAlertsEnabled: any(named: 'filterAlertsEnabled'),
        ),
      );

      // No inline banner, no root snackbar, no "push disabled in this
      // build" copy: the saved/off bell glyph + tooltip are the only
      // feedback surface so the catalog filter sheet reads product-
      // grade rather than build-flag-aware.
      final l10n = ruStrings();
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.textContaining('Доставка push'),
        findsNothing,
        reason:
            'Removed inline "push disabled in this build" banner must '
            'not be rendered in any form after the UX cleanup.',
      );
      expect(
        find.textContaining('Push-уведомления в этой сборке'),
        findsNothing,
        reason: 'Removed snackbar copy must not bleed back via any widget.',
      );
      expect(
        find.text(l10n.filterAlertNotificationsPushDisabled),
        findsNothing,
      );

      // Bell renders the dedicated saved-no-delivery glyph; the fully-
      // active `notifications_active` glyph is never used here.
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsOneWidget,
      );
      final icons = tester.widgetList<Icon>(
        find.descendant(
          of: find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
          matching: find.byType(Icon),
        ),
      );
      expect(
        icons.any((i) => i.icon == Icons.notifications_active),
        isFalse,
      );
      // Saved-off tooltip explicitly invites the user to tap to remove
      // the alert — toggle-off discoverability invariant.
      final saveOffTooltip = tester
          .widget<IconButton>(
            find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
          )
          .tooltip;
      expect(
        saveOffTooltip,
        l10n.catalogBrowseFilterBellSavedDeliveryUnavailableTooltip,
      );
    },
  );

  testWidgets(
    'push-disabled: second tap on the bell clears the saved alert, '
    'inline banner disappears, bell returns to inactive glyph',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      var backend = _row(criteria: null, notificationsEnabled: false);
      when(() => filterRepo.loadMine())
          .thenAnswer((_) async => Success(backend));
      when(() => notifRepo.getMyPreferences())
          .thenAnswer((_) async => Success(_prefsAllOn()));

      when(
        () => filterRepo.saveCriteria(
          any(),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      ).thenAnswer((inv) async {
        final crit =
            inv.positionalArguments.first as ListingDiscoveryCriteria;
        backend = _row(criteria: crit, notificationsEnabled: false);
        return Success(backend);
      });
      when(() => filterRepo.clearPersistedCriteria()).thenAnswer((_) async {
        backend = _row(criteria: null, notificationsEnabled: false);
        return Success(backend);
      });

      final alertsCubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await alertsCubit.refresh();

      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(buildSheet(
        alertsCubit: alertsCubit,
        auth: auth,
        formKey: formKey,
        seedState: const ListingsState(
          make: 'Toyota',
          regionFilter: MarketRegionFilter.transnistria,
        ),
        onApply: (_) {},
      ));
      await tester.pumpAndSettle();

      // First tap saves the alert; the saved/off glyph is now the
      // only visible saved-state surface (no inline banner anymore).
      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();

      final l10n = ruStrings();
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsOneWidget,
      );
      final savedOffTooltip = tester
          .widget<IconButton>(
            find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
          )
          .tooltip;
      expect(
        savedOffTooltip,
        l10n.catalogBrowseFilterBellSavedDeliveryUnavailableTooltip,
        reason:
            'Saved/off tooltip must advertise tap-to-remove without any '
            'build-flag copy.',
      );
      expect(
        find.textContaining('Доставка push'),
        findsNothing,
        reason: 'No technical banner copy after first tap.',
      );

      // Second tap on the SAME draft must clear the saved alert via
      // the new toggle path. Bell falls back to the inactive glyph
      // and no SnackBar bleeds anywhere.
      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();

      verify(() => filterRepo.clearPersistedCriteria()).called(1);
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsNothing,
      );
      // Inactive tooltip + the inactive glyph come back.
      final inactiveTooltip = tester
          .widget<IconButton>(
            find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
          )
          .tooltip;
      expect(inactiveTooltip, l10n.catalogBrowseFilterBellInactiveTooltip);
      final iconsAfter = tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
              matching: find.byType(Icon),
            ),
          )
          .toList();
      expect(
        iconsAfter.any((i) => i.icon == Icons.notifications_none),
        isTrue,
      );
      // No bleed: clear path emits no root SnackBar.
      expect(find.byType(SnackBar), findsNothing);
    },
  );

  testWidgets(
    'push-disabled: Show cars CTA stays visually stable while bellBusy '
    'toggles, and the bell self-disables to prevent duplicate taps',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(_row(criteria: null, notificationsEnabled: false)),
      );
      when(() => notifRepo.getMyPreferences())
          .thenAnswer((_) async => Success(_prefsAllOn()));

      final alertsCubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await alertsCubit.refresh();

      final formKey = GlobalKey<ListingsFilterFormState>();
      bool applyFired = false;

      await tester.pumpWidget(buildSheet(
        alertsCubit: alertsCubit,
        auth: auth,
        formKey: formKey,
        seedState: const ListingsState(
          make: 'Toyota',
          regionFilter: MarketRegionFilter.transnistria,
        ),
        onApply: (_) {
          applyFired = true;
        },
      ));
      await tester.pumpAndSettle();

      final l10n = ruStrings();
      final applyFinder = find.widgetWithText(FilledButton, l10n.filterShowCars);
      expect(applyFinder, findsOneWidget);
      // Snapshot the enabled CTA before flipping bellBusy.
      final enabledOnPressed =
          tester.widget<FilledButton>(applyFinder).onPressed;
      expect(enabledOnPressed, isNotNull);

      // Synthesize the in-flight bell operation. Toggling `bellBusy`
      // must NOT affect the Show cars CTA — the previous polish pass
      // moved CTA stability ahead of apply-side guarding.
      alertsCubit.emit(alertsCubit.state.copyWith(bellBusy: true));
      await tester.pumpAndSettle();
      expect(
        tester.widget<FilledButton>(applyFinder).onPressed,
        isNotNull,
        reason: 'Show cars must stay enabled while the bell is busy '
            '(no visual flicker between toggles).',
      );

      // Apply still fires on tap during a bell-in-flight window — the
      // sheet is plain-button-stable, not modal-locked. The bell, on
      // the other hand, must reject taps while busy: that protection
      // moved to the bell IconButton itself.
      await tester.tap(applyFinder);
      await tester.pumpAndSettle();
      expect(applyFired, isTrue);

      // Bell self-disables: tapping it while busy is rejected.
      final bellButton = tester
          .widget<IconButton>(
            find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
          );
      expect(
        bellButton.onPressed,
        isNull,
        reason: 'Bell IconButton must drop taps while `bellBusy=true` '
            'to prevent duplicate save/clear round-trips.',
      );

      // Releasing bellBusy re-enables the bell; Show cars never changed.
      alertsCubit.emit(alertsCubit.state.copyWith(bellBusy: false));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<IconButton>(
              find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
            )
            .onPressed,
        isNotNull,
      );
      expect(
        tester.widget<FilledButton>(applyFinder).onPressed,
        isNotNull,
      );
    },
  );

  testWidgets(
    'push-disabled: apply-only path (no bell tap) shows no push-related '
    'snackbar',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(_row(criteria: null, notificationsEnabled: false)),
      );
      when(() => notifRepo.getMyPreferences())
          .thenAnswer((_) async => Success(_prefsAllOn()));

      final alertsCubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await alertsCubit.refresh();

      final formKey = GlobalKey<ListingsFilterFormState>();
      bool applyFired = false;
      await tester.pumpWidget(buildSheet(
        alertsCubit: alertsCubit,
        auth: auth,
        formKey: formKey,
        seedState: const ListingsState(
          make: 'Toyota',
          regionFilter: MarketRegionFilter.transnistria,
        ),
        onApply: (_) {
          applyFired = true;
        },
      ));
      await tester.pumpAndSettle();

      final l10n = ruStrings();
      await tester.tap(
        find.widgetWithText(FilledButton, l10n.filterShowCars),
      );
      await tester.pumpAndSettle();

      expect(applyFired, isTrue);
      verifyNever(() => orch.enableDeliveries(any()));
      verifyNever(
        () => filterRepo.saveCriteria(
          any(),
          notificationsEnabled: any(named: 'notificationsEnabled'),
        ),
      );
      // No push-related snackbar fires and no saved/off bell glyph is
      // rendered — there is no saved alert yet, so the apply-only path
      // is genuinely neutral.
      expect(find.byType(SnackBar), findsNothing);
      expect(
        find.text(l10n.filterAlertNotificationsPushDisabled),
        findsNothing,
      );
      expect(
        find.textContaining('Доставка push'),
        findsNothing,
      );
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsNothing,
      );
    },
  );

  // ---------------------------------------------------------------------------
  // Regression — sheet bell must match the FAB indicator from the FIRST frame
  // when the sheet reopens on top of a saved alert. Previously the bell was
  // stuck on the inactive glyph because the form's GlobalKey.currentState
  // was null during the bell's first BlocBuilder pass and never recovered.
  // ---------------------------------------------------------------------------

  testWidgets(
    'reopen-after-save: sheet opens with the saved-off bell glyph from the '
    'first frame when applied state still matches saved criteria '
    '(push-disabled build)',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      // The cubit is already populated with a matching saved-but-off
      // row, simulating "user saved, dismissed sheet, FAB ornament
      // visible, user reopens sheet".
      final savedCrit = const ListingDiscoveryCriteria(
        make: 'BMW',
        marketRegion: MarketRegion.transnistria,
      );
      var backend = _row(criteria: savedCrit, notificationsEnabled: false);
      when(() => filterRepo.loadMine())
          .thenAnswer((_) async => Success(backend));
      when(() => notifRepo.getMyPreferences())
          .thenAnswer((_) async => Success(_prefsAllOn()));
      when(() => filterRepo.clearPersistedCriteria()).thenAnswer((_) async {
        backend = _row(criteria: null, notificationsEnabled: false);
        return Success(backend);
      });

      final alertsCubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await alertsCubit.refresh();

      const appliedState = ListingsState(
        make: 'BMW',
        regionFilter: MarketRegionFilter.transnistria,
      );

      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(buildSheet(
        alertsCubit: alertsCubit,
        auth: auth,
        formKey: formKey,
        seedState: appliedState,
        onApply: (_) {},
      ));
      // Single pump only — the canonical-applied-state fallback in the
      // bell must produce the saved-off glyph on this very first frame.
      await tester.pump();

      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsOneWidget,
        reason:
            'Reopening the sheet on top of a matching saved-off alert must '
            'render the saved-off glyph on the first frame so the bell '
            'never disagrees with the main catalog FAB indicator.',
      );

      // After full settle the same glyph remains (post-frame rebuild is
      // idempotent for matching applied + saved state).
      await tester.pumpAndSettle();
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsOneWidget,
      );

      // Tapping the bell on a matching draft must clear via the toggle
      // path — the user can disable the saved alert directly from the
      // sheet without leaving for /filter-alert.
      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();
      verify(() => filterRepo.clearPersistedCriteria()).called(1);
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsNothing,
      );
    },
  );

  testWidgets(
    'reopen-after-save: sheet preserves search snippet so the bell still '
    'recognises a saved alert that includes the catalog search',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      // Saved row matches BMW + Transnistria + the catalog search text.
      const searchSnippet = 'X5';
      final savedCrit = const ListingDiscoveryCriteria(
        search: searchSnippet,
        make: 'BMW',
        marketRegion: MarketRegion.transnistria,
      );
      final savedRow = _row(
        criteria: savedCrit,
        notificationsEnabled: false,
      );
      when(() => filterRepo.loadMine())
          .thenAnswer((_) async => Success(savedRow));
      when(() => notifRepo.getMyPreferences())
          .thenAnswer((_) async => Success(_prefsAllOn()));

      final alertsCubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await alertsCubit.refresh();

      // Build a tree that injects the search snippet manually, mirroring
      // ListingsPage's `resolvedSearchSnippet` closure semantics.
      const appliedState = ListingsState(
        search: searchSnippet,
        make: 'BMW',
        regionFilter: MarketRegionFilter.transnistria,
      );
      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<BrowseCatalogFilterAlertsCubit>.value(
              value: alertsCubit,
            ),
            BlocProvider<AuthCubit>.value(value: auth),
          ],
          child: MaterialApp(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            home: Scaffold(
              body: Builder(
                builder: (context) => ListingsFilterHost(
                  filterFormExternalKey: formKey,
                  seed:
                      ListingsFilterFormSeed.fromListingsState(appliedState),
                  onDismiss: () {},
                  onApply: (_) {},
                  browseHeaderTrailing: CatalogBrowseFilterAlertSheetBell(
                    sheetFormKey: formKey,
                    sheetContext: context,
                    searchSnippet: () => searchSnippet,
                    appliedState: appliedState,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsOneWidget,
        reason:
            'Bell must recognise the saved alert when both saved criteria '
            'and the catalog draft carry the same search snippet.',
      );
    },
  );

  testWidgets(
    'negative: sheet opens on a different applied filter than saved → bell '
    'stays inactive so tapping it saves the new draft rather than clearing '
    'an unrelated saved alert',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      // Saved row tracks BMW, but the sheet opens with Toyota applied.
      final savedCrit = const ListingDiscoveryCriteria(
        make: 'BMW',
        marketRegion: MarketRegion.transnistria,
      );
      final savedRow = _row(
        criteria: savedCrit,
        notificationsEnabled: false,
      );
      when(() => filterRepo.loadMine())
          .thenAnswer((_) async => Success(savedRow));
      when(() => notifRepo.getMyPreferences())
          .thenAnswer((_) async => Success(_prefsAllOn()));

      final alertsCubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await alertsCubit.refresh();

      const appliedState = ListingsState(
        make: 'Toyota',
        regionFilter: MarketRegionFilter.transnistria,
      );

      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(buildSheet(
        alertsCubit: alertsCubit,
        auth: auth,
        formKey: formKey,
        seedState: appliedState,
        onApply: (_) {},
      ));
      await tester.pumpAndSettle();

      // Bell must be inactive — saved BMW alert does not match applied
      // Toyota, so the user is creating a new alert (not toggling off).
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetBellSavedNoDeliveryIconKey),
        findsNothing,
      );
      final icons = tester
          .widgetList<Icon>(
            find.descendant(
              of: find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
              matching: find.byType(Icon),
            ),
          )
          .toList();
      expect(
        icons.any((i) => i.icon == Icons.notifications_none),
        isTrue,
        reason: 'Inactive glyph (`notifications_none`) is the expected '
            'default for a draft that does not match saved criteria.',
      );
    },
  );
}
