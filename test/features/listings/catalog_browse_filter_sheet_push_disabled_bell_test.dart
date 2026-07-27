// Widget coverage: catalog filter-alert sheet bell when
// `PUSH_NOTIFICATIONS_ENABLED=false`.

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/filter_alerts/domain/entities/saved_search.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/saved_searches_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_browse_filter_alert_sheet_bell.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_sheet_feedback.dart';
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

import '../../helpers/browse_catalog_filter_alerts_sl.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _MockDeliveryOrchestrator extends Mock
    implements FilterAlertDeliveryOrchestrator {}

SavedSearch _savedRow({
  String id = 'ss-1',
  String name = 'Test search',
  required ListingDiscoveryCriteria criteria,
  bool alertsEnabled = false,
}) {
  return testSavedSearch(
    id: id,
    name: name,
    criteria: criteria,
    alertsEnabled: alertsEnabled,
  );
}

void _wireMutableSavedSearches(
  MockSavedSearchesRepository repo,
  List<SavedSearch> searches,
) {
  when(() => repo.list()).thenAnswer((_) async => Success(searches));
  when(
    () => repo.create(
      name: any(named: 'name'),
      criteria: any(named: 'criteria'),
      alertsEnabled: any(named: 'alertsEnabled'),
    ),
  ).thenAnswer((inv) async {
    final criteria = inv.namedArguments[#criteria] as ListingDiscoveryCriteria;
    final alertsEnabled = inv.namedArguments[#alertsEnabled] as bool;
    final name = inv.namedArguments[#name] as String;
    final row = _savedRow(
      name: name,
      criteria: criteria,
      alertsEnabled: alertsEnabled,
    );
    searches
      ..clear()
      ..addAll([...searches, row]);
    return Success(row);
  });
  when(() => repo.delete(any())).thenAnswer((inv) async {
    final id = inv.positionalArguments.first as String;
    searches
      ..clear()
      ..addAll(searches.where((s) => s.id != id));
    return const Success(null);
  });
}

BrowseCatalogFilterAlertsCubit _buildAlertsCubit({
  required SavedSearchesRepository savedSearchesRepo,
  required NotificationsRepository notifRepo,
  required FilterAlertDeliveryOrchestrator orch,
}) {
  return buildTestBrowseCatalogFilterAlertsCubit(
    savedSearchesRepo: savedSearchesRepo,
    notificationsRepo: notifRepo,
    deliveryOrchestrator: orch,
  );
}

NotificationPreferences _prefsAllOn() => NotificationPreferences(
  userId: 'u',
  globalEnabled: true,
  messagesEnabled: true,
  filterAlertsEnabled: true,
  priceDropsEnabled: false,
  createdAt: DateTime.utc(2026, 5, 1),
  updatedAt: DateTime.utc(2026, 5, 2),
);

void _loadPushDisabledEnv() {
  dotenv.testLoad(
    fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=false
''',
  );
}

Icon _sheetBellIcon(WidgetTester tester) {
  return tester.widgetList<Icon>(
    find.descendant(
      of: find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey),
      matching: find.byType(Icon),
    ),
  ).first;
}

class _PushDisabledSheetHarness extends StatefulWidget {
  const _PushDisabledSheetHarness({
    required this.formKey,
    required this.seedState,
    required this.onApply,
  });

  final GlobalKey<ListingsFilterFormState> formKey;
  final ListingsState seedState;
  final ValueChanged<dynamic> onApply;

  @override
  State<_PushDisabledSheetHarness> createState() =>
      _PushDisabledSheetHarnessState();
}

class _PushDisabledSheetHarnessState extends State<_PushDisabledSheetHarness> {
  CatalogFilterSheetFeedback? _sheetFeedback;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => ListingsFilterHost(
        filterFormExternalKey: widget.formKey,
        seed: ListingsFilterFormSeed.fromListingsState(widget.seedState),
        onDismiss: () {},
        onApply: widget.onApply,
        onBrowseDraftMutated: () => setState(() => _sheetFeedback = null),
        browseHeaderTrailing: CatalogBrowseFilterAlertSheetBell(
          sheetFormKey: widget.formKey,
          sheetContext: context,
          searchSnippet: () => '',
          appliedState: widget.seedState,
          onSheetFeedbackRequested: (feedback) =>
              setState(() => _sheetFeedback = feedback),
        ),
        browseSheetFeedbackOverlay: _sheetFeedback == null
            ? null
            : CatalogFilterSheetFeedbackOverlay(
                feedback: _sheetFeedback!,
                onDismissed: () => setState(() => _sheetFeedback = null),
              ),
      ),
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      testSavedSearch(criteria: const ListingDiscoveryCriteria()),
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
          body: _PushDisabledSheetHarness(
            formKey: formKey,
            seedState: seedState,
            onApply: onApply,
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
    whenListen(auth, const Stream<AuthState>.empty(), initialState: state);
    return auth;
  }

  testWidgets(
    'push-disabled: first tap saves criteria, shows push-unavailable feedback, '
    'keeps inactive bell, never calls delivery orchestrator',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final savedSearchesRepo = MockSavedSearchesRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      final searches = <SavedSearch>[];
      _wireMutableSavedSearches(savedSearchesRepo, searches);
      when(
        () => notifRepo.getMyPreferences(),
      ).thenAnswer((_) async => Success(_prefsAllOn()));

      final alertsCubit = _buildAlertsCubit(
        savedSearchesRepo: savedSearchesRepo,
        notifRepo: notifRepo,
        orch: orch,
      );
      await alertsCubit.onAuthChanged(
        const AuthState.authenticated(
          AuthUser(id: 'u', email: 'u@example.com'),
        ),
      );

      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(
        buildSheet(
          alertsCubit: alertsCubit,
          auth: auth,
          formKey: formKey,
          seedState: const ListingsState(
            make: 'Toyota',
            regionFilter: MarketRegionFilter.transnistria,
          ),
          onApply: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();

      verify(
        () => savedSearchesRepo.create(
          name: any(named: 'name'),
          criteria: any(named: 'criteria'),
          alertsEnabled: false,
        ),
      ).called(1);
      verifyNever(() => orch.enableDeliveries(any()));
      verifyNever(() => orch.disableDeliveries(any()));

      final l10n = ruStrings();
      expect(find.text(l10n.savedSearchAlertsPushUnavailableHint), findsOneWidget);
      expect(_sheetBellIcon(tester).icon, Icons.notifications_none);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.notifications_active), findsNothing);
    },
  );

  testWidgets(
    'push-disabled: second tap on saved criteria shows feedback and does not delete',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final savedSearchesRepo = MockSavedSearchesRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      final searches = <SavedSearch>[];
      _wireMutableSavedSearches(savedSearchesRepo, searches);
      when(
        () => notifRepo.getMyPreferences(),
      ).thenAnswer((_) async => Success(_prefsAllOn()));

      final alertsCubit = _buildAlertsCubit(
        savedSearchesRepo: savedSearchesRepo,
        notifRepo: notifRepo,
        orch: orch,
      );
      await alertsCubit.onAuthChanged(
        const AuthState.authenticated(
          AuthUser(id: 'u', email: 'u@example.com'),
        ),
      );

      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(
        buildSheet(
          alertsCubit: alertsCubit,
          auth: auth,
          formKey: formKey,
          seedState: const ListingsState(
            make: 'Toyota',
            regionFilter: MarketRegionFilter.transnistria,
          ),
          onApply: (_) {},
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
      await tester.pumpAndSettle();

      verifyNever(() => savedSearchesRepo.delete(any()));
      verifyNever(() => orch.enableDeliveries(any()));
      expect(_sheetBellIcon(tester).icon, Icons.notifications_none);
      expect(find.text(ruStrings().savedSearchAlertsPushUnavailableHint), findsOneWidget);
    },
  );

  testWidgets(
    'reopen-after-save: saved-only matching criteria keeps inactive bell from first frame',
    (tester) async {
      _loadPushDisabledEnv();
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      final auth = signedInAuth();
      final savedSearchesRepo = MockSavedSearchesRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();

      const savedCrit = ListingDiscoveryCriteria(
        make: 'BMW',
        marketRegion: MarketRegion.transnistria,
      );
      final searches = [_savedRow(criteria: savedCrit, alertsEnabled: false)];
      _wireMutableSavedSearches(savedSearchesRepo, searches);
      when(
        () => notifRepo.getMyPreferences(),
      ).thenAnswer((_) async => Success(_prefsAllOn()));

      final alertsCubit = _buildAlertsCubit(
        savedSearchesRepo: savedSearchesRepo,
        notifRepo: notifRepo,
        orch: orch,
      );
      await alertsCubit.onAuthChanged(
        const AuthState.authenticated(
          AuthUser(id: 'u', email: 'u@example.com'),
        ),
      );

      const appliedState = ListingsState(
        make: 'BMW',
        regionFilter: MarketRegionFilter.transnistria,
      );

      final formKey = GlobalKey<ListingsFilterFormState>();
      await tester.pumpWidget(
        buildSheet(
          alertsCubit: alertsCubit,
          auth: auth,
          formKey: formKey,
          seedState: appliedState,
          onApply: (_) {},
        ),
      );
      await tester.pump();

      expect(_sheetBellIcon(tester).icon, Icons.notifications_none);
      expect(find.byIcon(Icons.bookmark), findsNothing);
      expect(find.byIcon(Icons.notifications_active), findsNothing);
    },
  );
}
