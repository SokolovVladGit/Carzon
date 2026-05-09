import 'package:bloc_test/bloc_test.dart';
import 'package:carzon/app/di/injection.dart';
import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/auth/domain/entities/auth_user.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:carzon/features/auth/presentation/bloc/auth_state.dart';
import 'package:carzon/features/filter_alerts/domain/entities/filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/repositories/filter_alerts_repository.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/clear_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/get_filter_alert_settings.dart';
import 'package:carzon/features/filter_alerts/domain/usecases/save_filter_alert_criteria.dart';
import 'package:carzon/features/filter_alerts/presentation/cubit/filter_alert_settings_cubit.dart';
import 'package:carzon/features/filter_alerts/presentation/pages/filter_alert_settings_page.dart';
import 'package:carzon/features/listings/data/local/last_applied_listing_discovery_repository.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/noop_last_applied_listing_discovery_repository.dart';
import '../../helpers/filter_form_brand_picker_helpers.dart';

class _MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class _MockFilterAlertsRepository extends Mock
    implements FilterAlertsRepository {}

void _registerSlWithRepository(FilterAlertsRepository repo) {
  sl.registerLazySingleton<LastAppliedListingDiscoveryRepository>(
    () => const NoopLastAppliedListingDiscoveryRepository(),
  );
  sl.registerLazySingleton<FilterAlertsRepository>(() => repo);
  sl.registerFactory(
    () => GetFilterAlertSettings(sl<FilterAlertsRepository>()),
  );
  sl.registerFactory(
    () => SaveFilterAlertCriteria(sl<FilterAlertsRepository>()),
  );
  sl.registerFactory(() => ClearFilterAlertCriteria(sl<FilterAlertsRepository>()));
  sl.registerFactory(
    () => FilterAlertSettingsCubit(
      getSettings: sl<GetFilterAlertSettings>(),
      saveCriteria: sl<SaveFilterAlertCriteria>(),
      clearCriteria: sl<ClearFilterAlertCriteria>(),
    ),
  );
}

Widget _wrappedPage(_MockAuthCubit auth) {
  return MaterialApp(
    locale: const Locale('ru'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: Scaffold(
      body: Builder(
        builder: (context) {
          return Center(
            child: TextButton(
              onPressed: () {
                Navigator.of(context).push<void>(
                  MaterialPageRoute<void>(
                    builder:
                        (_) => BlocProvider<AuthCubit>.value(
                          value: auth,
                          child: const FilterAlertSettingsPage(),
                        ),
                  ),
                );
              },
              child: const Text('open_alert_editor_test'),
            ),
          );
        },
      ),
    ),
  );
}

void main() {
  late _MockAuthCubit auth;
  late _MockFilterAlertsRepository repo;

  setUp(() {
    auth = _MockAuthCubit();
    repo = _MockFilterAlertsRepository();
  });

  setUpAll(() {
    registerFallbackValue(const ListingDiscoveryCriteria());
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('/filter-alert body shows alert editor titles and save CTA', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.loadMine()).thenAnswer((_) async => const Success(null));
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    final l10n = ruStrings();
    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.filterAlertEditorTitle), findsWidgets);
    expect(find.text(l10n.filterAlertEditorEyebrow), findsOneWidget);
    expect(find.text(l10n.filterAlertSaveFilterAction), findsOneWidget);

    verify(() => repo.loadMine()).called(1);
    verifyNever(() => repo.saveCriteria(any()));
  });

  testWidgets('does not show removed intermediate-page copy', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.loadMine()).thenAnswer((_) async => const Success(null));
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    final l10n = ruStrings();

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.filterAlertEditorSubtitle), findsOneWidget);
    expect(find.byType(Switch), findsNothing);
  });

  testWidgets('criteria from backend seeds editor make field', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    final settings = FilterAlertSettings(
      userId: 'u1',
      criteria: const ListingDiscoveryCriteria(make: 'Audi'),
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026, 5, 9),
      updatedAt: DateTime.utc(2026, 5, 9),
    );
    when(() => repo.loadMine()).thenAnswer((_) async => Success(settings));
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    expect(find.text('Audi'), findsWidgets);
  });

  testWidgets('load failure shows localized message and retry recalls repository', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    var loadCount = 0;
    when(() => repo.loadMine()).thenAnswer((_) async {
      loadCount++;
      if (loadCount == 1) {
        return const FailureResult(NetworkFailure('offline_probe'));
      }
      return const Success(null);
    });
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    final l10n = ruStrings();

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.filterAlertLoadFailed), findsOneWidget);
    expect(find.text('offline_probe'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, l10n.commonRetry));
    await tester.pumpAndSettle();

    expect(loadCount, 2);
    expect(find.text(l10n.filterAlertSaveFilterAction), findsOneWidget);
  });

  testWidgets('load failure hides PostgREST-style technical payloads', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.loadMine()).thenAnswer(
      (_) async => const FailureResult(
        ServerFailure(
          'PGRST116 {"hint":null,"message":"filter_alert_settings row missing","code":"PGRST"}',
        ),
      ),
    );
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    final l10n = ruStrings();

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    expect(find.text(l10n.filterAlertLoadFailed), findsOneWidget);
    expect(find.textContaining('PGRST'), findsNothing);
    expect(find.textContaining('filter_alert'), findsNothing);

    verify(() => repo.loadMine()).called(1);
    verifyNever(() => repo.saveCriteria(any()));
  });

  testWidgets('save failure snackbar shows safe localized message only', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.loadMine()).thenAnswer((_) async => const Success(null));
    when(() => repo.saveCriteria(any())).thenAnswer(
      (_) async => FailureResult(
        ServerFailure(r'{"code":"PGRST403","detail":"jwt expired"}'),
      ),
    );
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    final l10n = ruStrings();

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    await pickListingFilterBrand(tester, 'Toyota');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.filterAlertSaveFilterAction));
    await tester.pumpAndSettle();

    verify(() => repo.saveCriteria(any())).called(1);
    expect(find.text(l10n.filterAlertSaveFailed), findsOneWidget);
    expect(find.textContaining('PGRST'), findsNothing);
  });

  testWidgets('successful save pops route and persists via repository', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    ListingDiscoveryCriteria? storedCriteria;
    when(() => repo.loadMine()).thenAnswer((_) async {
      if (storedCriteria == null) {
        return const Success(null);
      }
      return Success(
        FilterAlertSettings(
          userId: 'u1',
          criteria: storedCriteria!,
          notificationsEnabled: false,
          createdAt: DateTime.utc(2026, 5, 9),
          updatedAt: DateTime.utc(2026, 5, 10),
        ),
      );
    });
    when(() => repo.saveCriteria(any())).thenAnswer((invocation) async {
      storedCriteria =
          invocation.positionalArguments.first as ListingDiscoveryCriteria;
      final c = storedCriteria!;
      return Success(
        FilterAlertSettings(
          userId: 'u1',
          criteria: c,
          notificationsEnabled: false,
          createdAt: DateTime.utc(2026, 5, 9),
          updatedAt: DateTime.utc(2026, 5, 10),
        ),
      );
    });
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    final l10n = ruStrings();

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    await pickListingFilterBrand(tester, 'Toyota');
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.filterAlertSaveFilterAction));
    await tester.pumpAndSettle();

    verify(() => repo.saveCriteria(any())).called(1);
    expect(storedCriteria?.make, 'Toyota');
    expect(find.text('open_alert_editor_test'), findsOneWidget);

    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();
    expect(find.text('Toyota'), findsWidgets);
  });

  testWidgets('dismiss/back without tapping save does not call saveCriteria', (
    tester,
  ) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    when(() => repo.loadMine()).thenAnswer((_) async => const Success(null));
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
    await tester.pumpAndSettle();

    verifyNever(() => repo.saveCriteria(any()));
  });

  testWidgets(
    'reset then save calls clearPersistedCriteria twice (reset + vanilla save)',
    (tester) async {
      tester.view.physicalSize = const Size(420, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      const user = AuthUser(id: 'u1', email: 'a@b.com');
      final audi = FilterAlertSettings(
        userId: 'u1',
        criteria: const ListingDiscoveryCriteria(make: 'Audi'),
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 5, 9),
        updatedAt: DateTime.utc(2026, 5, 9),
      );
      final clearedFromApi = FilterAlertSettings(
        userId: 'u1',
        criteria: null,
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 5, 9),
        updatedAt: DateTime.utc(2026, 5, 10),
      );
      var loadCount = 0;
      when(() => repo.loadMine()).thenAnswer((_) async {
        loadCount++;
        if (loadCount == 1) return Success(audi);
        return Success(clearedFromApi);
      });
      when(
        () => repo.clearPersistedCriteria(),
      ).thenAnswer((_) async => Success(clearedFromApi));
      when(() => auth.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await sl.reset();
      _registerSlWithRepository(repo);

      final l10n = ruStrings();

      await tester.pumpWidget(_wrappedPage(auth));
      await tester.tap(find.text('open_alert_editor_test'));
      await tester.pumpAndSettle();

      expect(find.text('Audi'), findsWidgets);

      await tester.ensureVisible(find.text(l10n.filterClear));
      await tester.tap(find.text(l10n.filterClear));
      await tester.pumpAndSettle();
      // Success SnackBar sits over the footer; dismiss via time pump before tapping save.
      await tester.pump(const Duration(seconds: 5));
      await tester.pumpAndSettle();

      final saveBtn = find.widgetWithText(
        FilledButton,
        l10n.filterAlertSaveFilterAction,
      );
      await tester.ensureVisible(saveBtn);
      await tester.tap(saveBtn);
      await tester.pumpAndSettle();

      verify(() => repo.clearPersistedCriteria()).called(2);
      verifyNever(() => repo.saveCriteria(any()));

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('open_alert_editor_test'));
      await tester.pumpAndSettle();

      expect(find.text('Audi'), findsNothing);
      expect(loadCount, 2);
    },
  );

  testWidgets(
    'reset persists immediately; reopen without save shows cleared criteria',
    (tester) async {
      const user = AuthUser(id: 'u1', email: 'a@b.com');
      final audi = FilterAlertSettings(
        userId: 'u1',
        criteria: const ListingDiscoveryCriteria(make: 'Audi'),
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 5, 9),
        updatedAt: DateTime.utc(2026, 5, 9),
      );
      final clearedFromApi = FilterAlertSettings(
        userId: 'u1',
        criteria: null,
        notificationsEnabled: false,
        createdAt: DateTime.utc(2026, 5, 9),
        updatedAt: DateTime.utc(2026, 5, 10),
      );
      var loadCount = 0;
      when(() => repo.loadMine()).thenAnswer((_) async {
        loadCount++;
        if (loadCount == 1) return Success(audi);
        return Success(clearedFromApi);
      });
      when(
        () => repo.clearPersistedCriteria(),
      ).thenAnswer((_) async => Success(clearedFromApi));
      when(() => auth.state).thenReturn(const AuthState.authenticated(user));
      whenListen(
        auth,
        const Stream<AuthState>.empty(),
        initialState: const AuthState.authenticated(user),
      );

      await sl.reset();
      _registerSlWithRepository(repo);

      final l10n = ruStrings();

      await tester.pumpWidget(_wrappedPage(auth));
      await tester.tap(find.text('open_alert_editor_test'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text(l10n.filterClear));
      await tester.tap(find.text(l10n.filterClear));
      await tester.pumpAndSettle();

      verify(() => repo.clearPersistedCriteria()).called(1);
      expect(find.text('Audi'), findsNothing);

      await tester.tap(find.byIcon(Icons.arrow_back_ios_new_rounded));
      await tester.pumpAndSettle();

      verifyNever(() => repo.saveCriteria(any()));

      expect(find.text('open_alert_editor_test'), findsOneWidget);

      await tester.tap(find.text('open_alert_editor_test'));
      await tester.pumpAndSettle();

      expect(find.text('Audi'), findsNothing);
      expect(loadCount, 2);
    },
  );

  testWidgets('reset persist failure shows localized message only', (tester) async {
    const user = AuthUser(id: 'u1', email: 'a@b.com');
    final audi = FilterAlertSettings(
      userId: 'u1',
      criteria: const ListingDiscoveryCriteria(make: 'Audi'),
      notificationsEnabled: false,
      createdAt: DateTime.utc(2026, 5, 9),
      updatedAt: DateTime.utc(2026, 5, 9),
    );
    when(() => repo.loadMine()).thenAnswer((_) async => Success(audi));
    when(() => repo.clearPersistedCriteria()).thenAnswer(
      (_) async =>
          FailureResult(ServerFailure(r'{"code":"PGRST403","hint":"jwt"}')),
    );
    when(() => auth.state).thenReturn(const AuthState.authenticated(user));
    whenListen(
      auth,
      const Stream<AuthState>.empty(),
      initialState: const AuthState.authenticated(user),
    );

    await sl.reset();
    _registerSlWithRepository(repo);

    final l10n = ruStrings();

    await tester.pumpWidget(_wrappedPage(auth));
    await tester.tap(find.text('open_alert_editor_test'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text(l10n.filterClear));
    await tester.tap(find.text(l10n.filterClear));
    await tester.pumpAndSettle();

    verify(() => repo.clearPersistedCriteria()).called(1);
    expect(find.text(l10n.filterAlertResetFailed), findsOneWidget);
    expect(find.textContaining('PGRST'), findsNothing);
  });
}
