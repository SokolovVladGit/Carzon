import 'package:carzon/core/errors/failures.dart';
import 'package:carzon/core/utils/result.dart';
import 'package:carzon/features/fuel_prices/domain/entities/fuel_price_snapshot.dart';
import 'package:carzon/features/fuel_prices/domain/usecases/get_fuel_prices_for_app.dart';
import 'package:carzon/features/fuel_prices/presentation/cubit/fuel_prices_cubit.dart';
import 'package:carzon/features/fuel_prices/presentation/pages/fuel_prices_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../helpers/l10n_test_helpers.dart';

class _MockGetFuelPricesForApp extends Mock implements GetFuelPricesForApp {}

FuelPricesCubit _readyCubit(_MockGetFuelPricesForApp useCase) {
  when(() => useCase()).thenAnswer(
    (_) async => Success([
      const FuelPriceSnapshot(
        territory: 'moldova',
        status: 'succeeded',
        isStale: false,
        sourceLabel: 'ANRE · e-Carburanți',
        effectiveDate: '2026-06-22',
        currency: 'MDL',
        unit: 'liter',
        items: [
          FuelPriceItem(fuelCode: 'gasoline_95', price: 27.99),
          FuelPriceItem(fuelCode: 'diesel', price: 25.86),
        ],
        limitationCodes: ['national_ceiling', 'verify_at_station'],
      ),
      const FuelPriceSnapshot(
        territory: 'pmr',
        status: 'succeeded',
        isStale: false,
        sourceLabel: 'Sheriff',
        fetchedAt: null,
        currency: 'PMR_RUB',
        unit: 'liter',
        items: [
          FuelPriceItem(fuelCode: 'ai_98', price: 29.4),
          FuelPriceItem(fuelCode: 'ai_95_premium', price: 26.3),
          FuelPriceItem(fuelCode: 'ai_95', price: 26),
          FuelPriceItem(fuelCode: 'diesel_euro', price: 24.2),
          FuelPriceItem(fuelCode: 'diesel', price: 24),
        ],
        limitationCodes: ['sheriff_network', 'verify_at_station'],
      ),
    ]),
  );
  return FuelPricesCubit(getFuelPricesForApp: useCase)..load();
}

FuelPricesCubit _pmrUnavailableCubit(_MockGetFuelPricesForApp useCase) {
  when(() => useCase()).thenAnswer(
    (_) async => Success([
      const FuelPriceSnapshot(
        territory: 'moldova',
        status: 'succeeded',
        isStale: false,
        sourceLabel: 'ANRE · e-Carburanți',
        effectiveDate: '2026-06-22',
        currency: 'MDL',
        unit: 'liter',
        items: [
          FuelPriceItem(fuelCode: 'gasoline_95', price: 27.99),
        ],
        limitationCodes: ['national_ceiling'],
      ),
      const FuelPriceSnapshot(
        territory: 'pmr',
        status: 'unavailable',
        isStale: false,
        sourceLabel: 'Sheriff',
        currency: 'PMR_RUB',
        unit: 'liter',
        items: [],
        limitationCodes: ['sheriff_network'],
      ),
    ]),
  );
  return FuelPricesCubit(getFuelPricesForApp: useCase)..load();
}

Widget _wrap({
  required FuelPricesCubit cubit,
  Locale locale = const Locale('ru'),
  ThemeMode themeMode = ThemeMode.light,
}) {
  return MaterialApp(
    locale: locale,
    themeMode: themeMode,
    theme: ThemeData(useMaterial3: true),
    darkTheme: ThemeData(useMaterial3: true, brightness: Brightness.dark),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: fuelPricesTestHarness(
      cubit: cubit,
      child: const FuelPricesChrome(),
    ),
  );
}

void main() {
  late _MockGetFuelPricesForApp useCase;

  setUp(() {
    useCase = _MockGetFuelPricesForApp();
  });

  testWidgets('FuelPricesPage renders title and disclaimer', (tester) async {
    final l10n = ruStrings();
    await tester.pumpWidget(_wrap(cubit: _readyCubit(useCase)));
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, l10n.fuelPricesTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('fuel_prices_disclaimer_callout')),
      findsOneWidget,
    );
    expect(find.text(l10n.fuelPricesDisclaimer), findsOneWidget);
  });

  testWidgets('FuelPricesPage shows Moldova board and source metadata', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(_wrap(cubit: _readyCubit(useCase)));
    await tester.pumpAndSettle();

    expect(find.text(l10n.fuelPricesFuelGasoline95), findsOneWidget);
    expect(find.text(l10n.fuelPricesMoldovaScopeNote), findsOneWidget);
    expect(find.text(l10n.fuelPricesSourceLabel('ANRE · e-Carburanți')), findsOneWidget);
  });

  testWidgets('FuelPricesPage switches to PMR territory with all fuel rows', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(_wrap(cubit: _readyCubit(useCase)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.fuelPricesTerritoryPmr));
    await tester.pumpAndSettle();

    expect(find.text(l10n.fuelPricesPmrScopeNote), findsOneWidget);
    expect(find.text(l10n.fuelPricesFuelAi98), findsOneWidget);
    expect(find.text(l10n.fuelPricesFuelAi95Premium), findsOneWidget);
    expect(find.text(l10n.fuelPricesFuelAi95), findsOneWidget);
    expect(find.text(l10n.fuelPricesFuelDieselEuro), findsOneWidget);
    expect(find.text(l10n.fuelPricesFuelDiesel), findsOneWidget);
  });

  testWidgets('FuelPricesPage shows territory unavailable copy for PMR', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(_wrap(cubit: _pmrUnavailableCubit(useCase)));
    await tester.pumpAndSettle();

    await tester.tap(find.text(l10n.fuelPricesTerritoryPmr));
    await tester.pumpAndSettle();

    expect(find.text(l10n.fuelPricesTerritoryUnavailable), findsOneWidget);
    expect(find.text(l10n.fuelPricesLoadFailed), findsNothing);
  });

  testWidgets('FuelPricesPage global failure uses load failed copy', (
    tester,
  ) async {
    final l10n = ruStrings();
    when(() => useCase()).thenAnswer(
      (_) async => const FailureResult(UnknownFailure('x')),
    );
    final cubit = FuelPricesCubit(getFuelPricesForApp: useCase)..load();
    await tester.pumpWidget(_wrap(cubit: cubit));
    await tester.pumpAndSettle();

    expect(find.text(l10n.fuelPricesLoadFailed), findsOneWidget);
    expect(find.text(l10n.fuelPricesTerritoryUnavailable), findsNothing);
  });

  testWidgets('FuelPricesPage renders in RO locale', (tester) async {
    final l10n = roStrings();
    await tester.pumpWidget(
      _wrap(
        cubit: _readyCubit(useCase),
        locale: const Locale('ro'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.widgetWithText(AppBar, l10n.fuelPricesTitle), findsOneWidget);
  });

  testWidgets('FuelPricesPage renders in light theme at 320px width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        cubit: _readyCubit(useCase),
        themeMode: ThemeMode.light,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FuelPricesChrome), findsOneWidget);
  });

  testWidgets('FuelPricesPage renders in dark theme at 320px width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      _wrap(
        cubit: _readyCubit(useCase),
        themeMode: ThemeMode.dark,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FuelPricesChrome), findsOneWidget);
  });
}
