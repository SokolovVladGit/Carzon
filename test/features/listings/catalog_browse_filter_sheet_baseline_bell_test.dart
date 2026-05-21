// Catalog filter-alert sheet bell tests: too-broad criteria flow.
//
// The previous version of this file pinned a root-snackbar bleed
// regression for "criteria too broad" feedback. The bleed was fixed by
// keeping the feedback inside the open sheet via an inline notice
// rendered through `ListingsFilterHost.browseHeaderNotice`. These
// tests now cover the new inline notice flow:
//   1. tapping the bell on a baseline draft surfaces the inline notice
//      and shows NO SnackBar (no root-messenger bleed onto listings);
//   2. editing any draft field dismisses the inline notice;
//   3. tapping the bell on a non-broad draft does not show the inline
//      notice.
import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/filter_alerts_repository.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_browse_filter_alert_sheet_bell.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_browse_filter_alert_sheet_notice.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_alert_ui_constants.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_host.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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

/// Test-only harness mirroring the inline-notice ownership pattern in
/// `lib/features/listings/presentation/pages/listings_page.dart::
/// _openFiltersSheet`: the sheet builder owns a `CatalogBellInlineNotice?`
/// state, clears it on draft mutation, and publishes new payloads via
/// the bell's `onInlineNoticeRequested` callback.
class _SheetHarness extends StatefulWidget {
  const _SheetHarness({
    required this.formKey,
    required this.seedState,
  });

  final GlobalKey<ListingsFilterFormState> formKey;
  final ListingsState seedState;

  @override
  State<_SheetHarness> createState() => _SheetHarnessState();
}

class _SheetHarnessState extends State<_SheetHarness> {
  CatalogBellInlineNotice? _inlineNotice;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => ListingsFilterHost(
        filterFormExternalKey: widget.formKey,
        seed: ListingsFilterFormSeed.fromListingsState(widget.seedState),
        onDismiss: () {},
        onApply: (_) {},
        onBrowseDraftMutated: () =>
            setState(() => _inlineNotice = null),
        onBrowseFeedReset: () => setState(() => _inlineNotice = null),
        browseHeaderTrailing: CatalogBrowseFilterAlertSheetBell(
          sheetFormKey: widget.formKey,
          sheetContext: context,
          searchSnippet: () => '',
          appliedState: widget.seedState,
          onInlineNoticeRequested: (notice) =>
              setState(() => _inlineNotice = notice),
        ),
        browseHeaderNotice: _inlineNotice == null
            ? null
            : CatalogBrowseFilterAlertSheetNotice(notice: _inlineNotice!),
      ),
    );
  }
}

void main() {
  setUpAll(() {
    registerFallbackValue(
      FilterAlertSettings(
        userId: 'u',
        criteria: null,
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 1, 2),
        updatedAt: DateTime.utc(2026, 1, 3),
      ),
    );
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  group('catalog filter sheet bell — criteria too broad inline notice', () {
    _MockAuthCubit buildSignedInAuth() {
      final auth = _MockAuthCubit();
      const user = AuthUser(id: 'id', email: 'e@m.com');
      when(() => auth.state).thenReturn(AuthState.authenticated(user));
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: AuthState.authenticated(user),
      );
      return auth;
    }

    Future<(
      BrowseCatalogFilterAlertsCubit,
      _MockDeliveryOrchestrator,
      _MockFilterAlertsRepository
    )> setupCubit() async {
      final filterRepo = _MockFilterAlertsRepository();
      final notifRepo = _MockNotificationsRepository();
      final orch = _MockDeliveryOrchestrator();
      when(() => filterRepo.loadMine()).thenAnswer(
        (_) async => Success(
          FilterAlertSettings(
            userId: 'u',
            criteria: null,
            notificationsEnabled: false,
            createdAt: DateTime.utc(2026, 1, 8),
            updatedAt: DateTime.utc(2026, 1, 9),
          ),
        ),
      );
      when(() => notifRepo.getMyPreferences()).thenAnswer(
        (_) async => Success(
          NotificationPreferences(
            userId: 'u',
            globalEnabled: true,
            messagesEnabled: true,
            filterAlertsEnabled: true,
            createdAt: DateTime.utc(2026, 4, 1),
            updatedAt: DateTime.utc(2026, 4, 2),
          ),
        ),
      );
      final cubit = BrowseCatalogFilterAlertsCubit(
        getSettings: GetFilterAlertSettings(filterRepo),
        saveCriteria: SaveFilterAlertCriteria(filterRepo),
        clearCriteria: ClearFilterAlertCriteria(filterRepo),
        notificationsRepository: notifRepo,
        deliveryOrchestrator: orch,
      );
      await cubit.refresh();
      return (cubit, orch, filterRepo);
    }

    Widget hostApp({
      required AuthCubit auth,
      required BrowseCatalogFilterAlertsCubit alertsCubit,
      required GlobalKey<ListingsFilterFormState> formKey,
      ListingsState seedState = const ListingsState(),
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
            body: _SheetHarness(formKey: formKey, seedState: seedState),
          ),
        ),
      );
    }

    testWidgets(
      'tapping bell on baseline draft surfaces inline notice inside the '
      'sheet and never shows a (root-bleeding) SnackBar',
      (tester) async {
        tester.view.physicalSize = const Size(420, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final auth = buildSignedInAuth();
        final (alertsCubit, orch, filterRepo) = await setupCubit();
        final formKey = GlobalKey<ListingsFilterFormState>();

        await tester.pumpWidget(hostApp(
          auth: auth,
          alertsCubit: alertsCubit,
          formKey: formKey,
        ));
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.sheetTooBroadNoticeKey),
          findsNothing,
          reason: 'No notice before the user attempts a save.',
        );

        await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
        await tester.pumpAndSettle();

        verifyNever(() => orch.enableDeliveries(any()));
        verifyNever(
          () => filterRepo.saveCriteria(
            any(),
            notificationsEnabled: any(named: 'notificationsEnabled'),
          ),
        );

        final notice =
            find.byKey(CatalogFilterAlertAccent.sheetTooBroadNoticeKey);
        expect(notice, findsOneWidget);
        final ru = ruStrings();
        expect(
          find.descendant(
            of: notice,
            matching:
                find.text(ru.catalogBrowseFilterAlertTooBroadInlineTitle),
          ),
          findsOneWidget,
        );
        expect(
          find.descendant(
            of: notice,
            matching: find.text(ru.catalogBrowseFilterAlertTooBroadInlineBody),
          ),
          findsOneWidget,
        );

        // No root-messenger snackbar — neither the new short copy nor
        // the legacy long sentence may render anywhere on screen.
        expect(find.byType(SnackBar), findsNothing);
        expect(find.text(ru.catalogBrowseFilterBellTooBroad), findsNothing);
      },
    );

    testWidgets(
      'host-level reset (footer "Clear" button) dismisses the inline '
      '"refine filter" notice — the host wiring forwards through '
      'onBrowseFeedReset so the sheet can drop the stale notice',
      (tester) async {
        tester.view.physicalSize = const Size(420, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final auth = buildSignedInAuth();
        final (alertsCubit, _, _) = await setupCubit();
        final formKey = GlobalKey<ListingsFilterFormState>();

        await tester.pumpWidget(hostApp(
          auth: auth,
          alertsCubit: alertsCubit,
          formKey: formKey,
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
        await tester.pumpAndSettle();
        expect(
          find.byKey(CatalogFilterAlertAccent.sheetTooBroadNoticeKey),
          findsOneWidget,
        );

        // Drive a draft mutation via the sticky footer's reset button
        // (`OutlinedButton` with the `filterClear` label). The host's
        // `_onResetTap` calls `resetDraftToVanilla()` and then invokes
        // `widget.onBrowseFeedReset?.call()`, which the sheet harness
        // wires to clear the inline notice (mirroring the listings-page
        // sheet builder). Tapping the always-visible footer avoids the
        // off-screen chip + scrolling hit-test fragility while still
        // exercising the host-level draft mutation path.
        final ru = ruStrings();
        final resetButton =
            find.widgetWithText(OutlinedButton, ru.filterClear);
        expect(resetButton, findsOneWidget);
        await tester.tap(resetButton);
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.sheetTooBroadNoticeKey),
          findsNothing,
          reason:
              'Draft edits must dismiss the "refine filter" inline notice '
              'so the user can iterate without manual close.',
        );
      },
    );

    testWidgets(
      'bell tap on a non-broad draft does not show the too-broad inline '
      'notice — the path is reserved for criteriaTooBroad outcomes only',
      (tester) async {
        tester.view.physicalSize = const Size(420, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final auth = buildSignedInAuth();
        final (alertsCubit, orch, filterRepo) = await setupCubit();
        // Accept any save with non-null criteria so the cubit's
        // too-broad guard never fires.
        when(() => filterRepo.saveCriteria(
              any(),
              notificationsEnabled: any(named: 'notificationsEnabled'),
            )).thenAnswer(
          (inv) async => Success(
            FilterAlertSettings(
              userId: 'u',
              criteria:
                  inv.positionalArguments.first as ListingDiscoveryCriteria,
              notificationsEnabled:
                  inv.namedArguments[#notificationsEnabled] as bool,
              createdAt: DateTime.utc(2026, 4, 1),
              updatedAt: DateTime.utc(2026, 4, 2),
            ),
          ),
        );
        when(() => orch.enableDeliveries(any())).thenAnswer(
          (inv) async => Success(
            inv.positionalArguments.first as FilterAlertSettings,
          ),
        );

        final formKey = GlobalKey<ListingsFilterFormState>();
        await tester.pumpWidget(hostApp(
          auth: auth,
          alertsCubit: alertsCubit,
          formKey: formKey,
          // Non-broad: a make selected is enough to clear the cubit's
          // too-broad guard.
          seedState: const ListingsState(make: 'BMW'),
        ));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.sheetTooBroadNoticeKey),
          findsNothing,
        );
        expect(
          find.text(ruStrings().catalogBrowseFilterAlertTooBroadInlineTitle),
          findsNothing,
        );
      },
    );
  });
}
