// Sheet-local filter feedback: sign-in action safety + narrow-width layout.

import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/router/app_router.dart';
import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/filter_alerts/domain/services/filter_alert_delivery_orchestrator.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/cubit/browse_catalog_filter_alerts_cubit.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_browse_filter_alert_sheet_bell.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_alert_ui_constants.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/catalog_filter_sheet_feedback.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_host.dart';
import 'package:carzon/features/notifications/domain/entities/notification_preferences.dart';
import 'package:carzon/features/notifications/domain/repositories/notifications_repository.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:carzon/l10n/app_localizations_ro.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/browse_catalog_filter_alerts_sl.dart';
import '../../helpers/l10n_test_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockNotificationsRepository extends Mock
    implements NotificationsRepository {}

class _SignInSheetHarness extends StatefulWidget {
  const _SignInSheetHarness({required this.formKey});

  final GlobalKey<ListingsFilterFormState> formKey;

  @override
  State<_SignInSheetHarness> createState() => _SignInSheetHarnessState();
}

class _SignInSheetHarnessState extends State<_SignInSheetHarness> {
  CatalogFilterSheetFeedback? _sheetFeedback;

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) => ListingsFilterHost(
        filterFormExternalKey: widget.formKey,
        seed: ListingsFilterFormSeed.fromListingsState(
          const ListingsState(make: 'BMW'),
        ),
        onDismiss: () => Navigator.of(context).pop(),
        onApply: (_) {},
        browseHeaderTrailing: CatalogBrowseFilterAlertSheetBell(
          sheetFormKey: widget.formKey,
          sheetContext: context,
          searchSnippet: () => '',
          appliedState: const ListingsState(make: 'BMW'),
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
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  group('CatalogFilterSheetFeedbackToast layout', () {
    Future<void> pumpToast(
      WidgetTester tester, {
      required CatalogFilterSheetFeedback feedback,
      required Locale locale,
      double width = 320,
      ThemeData? theme,
    }) async {
      tester.view.physicalSize = Size(width, 800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        MaterialApp(
          theme: theme ?? ThemeData.light(),
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          home: Scaffold(
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: CatalogFilterSheetFeedbackToast(feedback: feedback),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    }

    testWidgets('RU longest save-failed copy fits at 320px without overflow', (
      tester,
    ) async {
      final ru = ruStrings();
      await pumpToast(
        tester,
        locale: const Locale('ru'),
        feedback: CatalogFilterSheetFeedback(
          message: ru.catalogBrowseFilterBellSaveFailedSnack,
          kind: CatalogFilterSheetFeedbackKind.error,
        ),
      );
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
        findsOneWidget,
      );
    });

    testWidgets('RU max-saved-searches copy fits at 320px without overflow', (
      tester,
    ) async {
      final ru = ruStrings();
      await pumpToast(
        tester,
        locale: const Locale('ru'),
        feedback: CatalogFilterSheetFeedback(
          message: ru.savedSearchesMaxReachedSnack,
          kind: CatalogFilterSheetFeedbackKind.error,
        ),
      );
    });

    testWidgets(
      'RU max-5 toast with action fits at 320px without overflow',
      (tester) async {
        final ru = ruStrings();
        await pumpToast(
          tester,
          locale: const Locale('ru'),
          feedback: CatalogFilterSheetFeedback(
            message: ru.savedSearchesMaxReachedSnack,
            kind: CatalogFilterSheetFeedbackKind.error,
            actionLabel: ru.savedSearchesMaxReachedOpenAction,
            onAction: () {},
          ),
        );
        expect(find.text(ru.savedSearchesMaxReachedOpenAction), findsOneWidget);
      },
    );

    testWidgets(
      'RU sign-in toast with action fits at 320px without overflow',
      (tester) async {
        final ru = ruStrings();
        var tapped = false;
        await pumpToast(
          tester,
          locale: const Locale('ru'),
          feedback: CatalogFilterSheetFeedback(
            message: ru.filterAlertSignInRequired,
            kind: CatalogFilterSheetFeedbackKind.info,
            actionLabel: ru.commonSignIn,
            onAction: () => tapped = true,
          ),
        );
        await tester.tap(find.text(ru.commonSignIn));
        await tester.pumpAndSettle();
        expect(tapped, isTrue);
        expect(tester.takeException(), isNull);
      },
    );

    testWidgets('RO save-failed copy fits at 320px without overflow', (
      tester,
    ) async {
      final ro = AppLocalizationsRo();
      await pumpToast(
        tester,
        locale: const Locale('ro'),
        feedback: CatalogFilterSheetFeedback(
          message: ro.catalogBrowseFilterBellSaveFailedSnack,
          kind: CatalogFilterSheetFeedbackKind.error,
        ),
      );
    });

    group('dark theme at 320px', () {
      testWidgets('RU save-failed copy fits without overflow', (tester) async {
        final ru = ruStrings();
        await pumpToast(
          tester,
          locale: const Locale('ru'),
          theme: AppTheme.dark(),
          feedback: CatalogFilterSheetFeedback(
            message: ru.catalogBrowseFilterBellSaveFailedSnack,
            kind: CatalogFilterSheetFeedbackKind.error,
          ),
        );
        expect(
          find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
          findsOneWidget,
        );
      });

      testWidgets('RU max-5 toast with action fits without overflow', (
        tester,
      ) async {
        final ru = ruStrings();
        await pumpToast(
          tester,
          locale: const Locale('ru'),
          theme: AppTheme.dark(),
          feedback: CatalogFilterSheetFeedback(
            message: ru.savedSearchesMaxReachedSnack,
            kind: CatalogFilterSheetFeedbackKind.error,
            actionLabel: ru.savedSearchesMaxReachedOpenAction,
            onAction: () {},
          ),
        );
        expect(find.text(ru.savedSearchesMaxReachedOpenAction), findsOneWidget);
      });

      testWidgets('RU sign-in toast with action fits without overflow', (
        tester,
      ) async {
        final ru = ruStrings();
        await pumpToast(
          tester,
          locale: const Locale('ru'),
          theme: AppTheme.dark(),
          feedback: CatalogFilterSheetFeedback(
            message: ru.filterAlertSignInRequired,
            kind: CatalogFilterSheetFeedbackKind.info,
            actionLabel: ru.commonSignIn,
            onAction: () {},
          ),
        );
        expect(find.text(ru.commonSignIn), findsOneWidget);
      });
    });
  });

  group('CatalogFilterSheetFeedbackOverlay auto-dismiss', () {
    Widget autoDismissHost({
      required CatalogFilterSheetFeedback feedback,
      required ValueChanged<bool> onDismissed,
    }) {
      return _AutoDismissHarness(
        feedback: feedback,
        onDismissed: () => onDismissed(true),
      );
    }

    testWidgets('max-saved-filters toast stays visible before transient duration',
        (tester) async {
      final ru = ruStrings();
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: autoDismissHost(
            feedback: CatalogFilterSheetFeedback(
              message: ru.savedSearchesMaxReachedSnack,
              kind: CatalogFilterSheetFeedbackKind.error,
            ),
            onDismissed: (v) => dismissed = v,
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
        findsOneWidget,
      );

      await tester.pump(const Duration(milliseconds: 2000));
      expect(dismissed, isFalse);
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
        findsOneWidget,
      );
    });

    testWidgets('max-saved-filters toast auto-dismisses after transient duration',
        (tester) async {
      final ru = ruStrings();
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: autoDismissHost(
            feedback: CatalogFilterSheetFeedback(
              message: ru.savedSearchesMaxReachedSnack,
              kind: CatalogFilterSheetFeedbackKind.error,
            ),
            onDismissed: (v) => dismissed = v,
          ),
        ),
      );
      await tester.pump();

      await tester.pump(CatalogFilterSheetFeedbackDismissTiming.transient);
      await tester.pump();

      expect(dismissed, isTrue);
      expect(
        find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
        findsNothing,
      );
    });

    testWidgets('timer is cancelled when overlay is disposed', (tester) async {
      final ru = ruStrings();
      var dismissed = false;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: autoDismissHost(
            feedback: CatalogFilterSheetFeedback(
              message: ru.savedSearchesMaxReachedSnack,
              kind: CatalogFilterSheetFeedbackKind.error,
            ),
            onDismissed: (v) => dismissed = v,
          ),
        ),
      );
      await tester.pump();

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: const SizedBox.shrink(),
        ),
      );
      await tester.pump(CatalogFilterSheetFeedbackDismissTiming.transient);
      await tester.pump();

      expect(dismissed, isFalse);
    });

    testWidgets(
      'max-5 toast with action stays visible before action dismiss duration',
      (tester) async {
        final ru = ruStrings();
        var dismissed = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: autoDismissHost(
              feedback: CatalogFilterSheetFeedback(
                message: ru.savedSearchesMaxReachedSnack,
                kind: CatalogFilterSheetFeedbackKind.error,
                actionLabel: ru.savedSearchesMaxReachedOpenAction,
                onAction: () {},
              ),
              onDismissed: (v) => dismissed = v,
            ),
          ),
        );
        await tester.pump();

        await tester.pump(CatalogFilterSheetFeedbackDismissTiming.transient);
        await tester.pump();

        expect(dismissed, isFalse);
        expect(
          find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'max-5 toast with action auto-dismisses after action duration',
      (tester) async {
        final ru = ruStrings();
        var dismissed = false;
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: autoDismissHost(
              feedback: CatalogFilterSheetFeedback(
                message: ru.savedSearchesMaxReachedSnack,
                kind: CatalogFilterSheetFeedbackKind.error,
                actionLabel: ru.savedSearchesMaxReachedOpenAction,
                onAction: () {},
              ),
              onDismissed: (v) => dismissed = v,
            ),
          ),
        );
        await tester.pump();

        await tester.pump(CatalogFilterSheetFeedbackDismissTiming.withAction);
        await tester.pump();

        expect(dismissed, isTrue);
        expect(
          find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
          findsNothing,
        );
      },
    );
  });

  group('filter sheet bell max-5 action', () {
    late _MockAuthCubit auth;
    late MockSavedSearchesRepository savedSearchesRepo;
    late _MockNotificationsRepository notificationsRepo;

    setUp(() {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );

      auth = _MockAuthCubit();
      const user = AuthUser(id: 'id', email: 'e@m.com');
      when(() => auth.state).thenReturn(AuthState.authenticated(user));
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: AuthState.authenticated(user),
      );

      savedSearchesRepo = MockSavedSearchesRepository();
      notificationsRepo = _MockNotificationsRepository();
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
      when(() => notificationsRepo.getMyPreferences()).thenAnswer(
        (_) async => Success(
          NotificationPreferences(
            userId: 'u',
            globalEnabled: true,
            messagesEnabled: true,
            filterAlertsEnabled: true,
            priceDropsEnabled: false,
            createdAt: DateTime.utc(2026, 4, 1),
            updatedAt: DateTime.utc(2026, 4, 2),
          ),
        ),
      );
    });

    testWidgets(
      'at-cap bell tap shows max-5 toast with manage action; tap closes '
      'sheet and pushes filter-alert route',
      (tester) async {
        tester.view.physicalSize = const Size(420, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final alertsCubit = buildTestBrowseCatalogFilterAlertsCubit(
          savedSearchesRepo: savedSearchesRepo,
          notificationsRepo: notificationsRepo,
          deliveryOrchestrator: MockFilterAlertDeliveryOrchestrator(),
        );
        await alertsCubit.refresh();

        var sheetClosed = false;
        final formKey = GlobalKey<ListingsFilterFormState>();
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => MultiBlocProvider(
                providers: [
                  BlocProvider<BrowseCatalogFilterAlertsCubit>.value(
                    value: alertsCubit,
                  ),
                  BlocProvider<AuthCubit>.value(value: auth),
                ],
                child: Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (sheetContext) => SizedBox(
                            height: MediaQuery.sizeOf(sheetContext).height,
                            child: MultiBlocProvider(
                              providers: [
                                BlocProvider<
                                  BrowseCatalogFilterAlertsCubit
                                >.value(value: alertsCubit),
                                BlocProvider<AuthCubit>.value(value: auth),
                              ],
                              child: _SignInSheetHarness(formKey: formKey),
                            ),
                          ),
                        );
                        sheetClosed = true;
                      },
                      child: const Text('open-filters-sheet'),
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.filterAlert,
              builder: (_, _) => const Scaffold(
                body: Center(child: Text('filter-alert-page')),
              ),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('open-filters-sheet'));
        await tester.pumpAndSettle();

        final ru = ruStrings();
        await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
          findsOneWidget,
        );
        expect(find.text(ru.savedSearchesMaxReachedSnack), findsOneWidget);
        expect(find.text(ru.savedSearchesMaxReachedOpenAction), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);
        verifyNever(
          () => savedSearchesRepo.create(
            name: any(named: 'name'),
            criteria: any(named: 'criteria'),
            alertsEnabled: any(named: 'alertsEnabled'),
          ),
        );

        await tester.tap(find.text(ru.savedSearchesMaxReachedOpenAction));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(sheetClosed, isTrue);
        expect(find.text('filter-alert-page'), findsOneWidget);
        expect(
          find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
          findsNothing,
        );
      },
    );
  });

  group('filter sheet bell sign-in action', () {
    late _MockAuthCubit auth;
    late MockSavedSearchesRepository savedSearchesRepo;
    late _MockNotificationsRepository notificationsRepo;

    setUp(() {
      dotenv.testLoad(
        fileInput: '''
SUPABASE_URL=https://example.supabase.co
SUPABASE_ANON_KEY=anon
PUSH_NOTIFICATIONS_ENABLED=true
''',
      );

      auth = _MockAuthCubit();
      when(() => auth.state).thenReturn(const AuthState.unauthenticated());
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.unauthenticated(),
      );

      savedSearchesRepo = MockSavedSearchesRepository();
      notificationsRepo = _MockNotificationsRepository();
      when(
        () => savedSearchesRepo.list(),
      ).thenAnswer((_) async => const Success([]));
      when(() => notificationsRepo.getMyPreferences()).thenAnswer(
        (_) async => Success(
          NotificationPreferences(
            userId: 'u',
            globalEnabled: true,
            messagesEnabled: true,
            filterAlertsEnabled: true,
            priceDropsEnabled: false,
            createdAt: DateTime.utc(2026, 4, 1),
            updatedAt: DateTime.utc(2026, 4, 2),
          ),
        ),
      );
    });

    testWidgets(
      'signed-out bell tap shows sign-in toast; action pops sheet and '
      'navigates without throwing',
      (tester) async {
        tester.view.physicalSize = const Size(420, 1400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final alertsCubit = buildTestBrowseCatalogFilterAlertsCubit(
          savedSearchesRepo: savedSearchesRepo,
          notificationsRepo: notificationsRepo,
          deliveryOrchestrator: MockFilterAlertDeliveryOrchestrator(),
        );
        await alertsCubit.refresh();

        var sheetClosed = false;
        final formKey = GlobalKey<ListingsFilterFormState>();
        final router = GoRouter(
          initialLocation: '/',
          routes: [
            GoRoute(
              path: '/',
              builder: (context, _) => MultiBlocProvider(
                providers: [
                  BlocProvider<BrowseCatalogFilterAlertsCubit>.value(
                    value: alertsCubit,
                  ),
                  BlocProvider<AuthCubit>.value(value: auth),
                ],
                child: Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async {
                        await showModalBottomSheet<void>(
                          context: context,
                          isScrollControlled: true,
                          builder: (sheetContext) => SizedBox(
                            height: MediaQuery.sizeOf(sheetContext).height,
                            child: MultiBlocProvider(
                              providers: [
                                BlocProvider<
                                  BrowseCatalogFilterAlertsCubit
                                >.value(value: alertsCubit),
                                BlocProvider<AuthCubit>.value(value: auth),
                              ],
                              child: _SignInSheetHarness(formKey: formKey),
                            ),
                          ),
                        );
                        sheetClosed = true;
                      },
                      child: const Text('open-filters-sheet'),
                    ),
                  ),
                ),
              ),
            ),
            GoRoute(
              path: AppRoutes.signIn,
              builder: (_, _) =>
                  const Scaffold(body: Center(child: Text('sign-in-page'))),
            ),
          ],
        );

        await tester.pumpWidget(
          MaterialApp.router(
            locale: const Locale('ru'),
            supportedLocales: AppLocalizations.supportedLocales,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            routerConfig: router,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('open-filters-sheet'));
        await tester.pumpAndSettle();

        final ru = ruStrings();
        await tester.tap(find.byKey(CatalogBrowseFilterAlertSheetBell.bellKey));
        await tester.pumpAndSettle();

        expect(
          find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
          findsOneWidget,
        );
        expect(find.text(ru.filterAlertSignInRequired), findsOneWidget);
        expect(find.byType(SnackBar), findsNothing);

        await tester.tap(find.text(ru.commonSignIn));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(sheetClosed, isTrue);
        expect(find.text('sign-in-page'), findsOneWidget);
        expect(
          find.byKey(CatalogFilterAlertAccent.sheetFeedbackToastKey),
          findsNothing,
        );
      },
    );
  });
}

class MockFilterAlertDeliveryOrchestrator extends Mock
    implements FilterAlertDeliveryOrchestrator {}

class _AutoDismissHarness extends StatefulWidget {
  const _AutoDismissHarness({
    required this.feedback,
    required this.onDismissed,
  });

  final CatalogFilterSheetFeedback feedback;
  final VoidCallback onDismissed;

  @override
  State<_AutoDismissHarness> createState() => _AutoDismissHarnessState();
}

class _AutoDismissHarnessState extends State<_AutoDismissHarness> {
  CatalogFilterSheetFeedback? _feedback;

  @override
  void initState() {
    super.initState();
    _feedback = widget.feedback;
  }

  @override
  Widget build(BuildContext context) {
    final feedback = _feedback;
    return Scaffold(
      body: feedback == null
          ? const SizedBox.shrink()
          : CatalogFilterSheetFeedbackOverlay(
              feedback: feedback,
              onDismissed: () {
                widget.onDismissed();
                setState(() => _feedback = null);
              },
            ),
    );
  }
}
