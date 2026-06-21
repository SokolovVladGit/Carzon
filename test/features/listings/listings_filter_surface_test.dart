import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_apply_result.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_host.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_summary_strip.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_segmented_control.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/filter_form_brand_picker_helpers.dart';

Future<void> _pumpStandaloneFilterForm(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Scaffold(
        body: SingleChildScrollView(
          child: ListingsFilterForm(
            seed: ListingsFilterFormSeed.fromListingsState(
              const ListingsState(),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _scrollFilterControlIntoView(
  WidgetTester tester,
  Finder control,
) async {
  await tester.scrollUntilVisible(
    control,
    120,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.pumpAndSettle();
}

const Size _kFilterSheetViewport = Size(390, 844);

Future<void> _pumpFilterHostAtViewport(
  WidgetTester tester, {
  Size viewport = _kFilterSheetViewport,
}) async {
  tester.view.physicalSize = viewport;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      locale: const Locale('ru'),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: ListingsFilterHost(
        seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
        onDismiss: () {},
        onApply: (_) {},
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Size _summaryStripSize(WidgetTester tester) {
  return tester.getSize(find.byType(ListingsFilterSummaryStrip));
}

Size _filterFormSize(WidgetTester tester) {
  return tester.getSize(find.byType(ListingsFilterForm));
}

double _filterListMaxScrollExtent(WidgetTester tester) {
  final scrollable = find.descendant(
    of: find.byType(ListingsFilterHost),
    matching: find.byType(Scrollable),
  );
  final position = tester.state<ScrollableState>(scrollable.first).position;
  return position.maxScrollExtent;
}

void main() {
  testWidgets('ListingsFilterHost shows structured filter surface', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(l10n.filtersTitle), findsOneWidget);
    expect(find.text(l10n.filtersHeaderEyebrow), findsOneWidget);
    expect(find.text(l10n.filtersSubtitle), findsOneWidget);
    expect(find.text(l10n.filtersSummaryDefaultTitle), findsOneWidget);
    expect(find.text(l10n.filtersSectionMakeModel), findsOneWidget);
    expect(find.text(l10n.filtersSectionBudget), findsOneWidget);
    expect(find.text(l10n.filtersSectionLocation), findsOneWidget);
    expect(find.text(l10n.filterShowCars), findsOneWidget);
    expect(find.text(l10n.filtersSectionVehicle), findsOneWidget);
    expect(
      find.byKey(const ValueKey<String>('listings_filter_make_pick_trigger')),
      findsOneWidget,
    );
    expect(find.byType(ListingsFilterSummaryStrip), findsOneWidget);
  });

  testWidgets(
    'ListingsFilterHost has no layout exceptions on compact viewport',
    (tester) async {
      tester.view.physicalSize = const Size(320, 568);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListingsFilterHost(
            seed: ListingsFilterFormSeed.fromListingsState(
              const ListingsState(),
            ),
            onDismiss: () {},
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('currency filter defaults to Any / Любая', (tester) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.filterPriceCurrencyAny), findsOneWidget);
    expect(find.text(l10n.filterPriceCurrencyUsd), findsOneWidget);
    expect(find.text(l10n.filterPriceCurrencyEur), findsOneWidget);
    expect(find.text('USD'), findsOneWidget);
    expect(find.text('EUR'), findsOneWidget);
  });

  testWidgets('currency segmented control updates apply result', (
    tester,
  ) async {
    final l10n = ruStrings();
    final formKey = GlobalKey<ListingsFilterFormState>();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListingsFilterForm(
              key: formKey,
              seed: ListingsFilterFormSeed.fromListingsState(
                const ListingsState(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final currencyControl = find.byKey(
      const ValueKey<String>('listings_filter_currency_segmented'),
    );
    await tester.scrollUntilVisible(
      currencyControl,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.filterPriceCurrencyUsd));
    await tester.pumpAndSettle();

    final result = formKey.currentState!.submit();
    expect(result, isNotNull);
    expect(result!.priceCurrencyFilter, ListingPriceCurrencyFilter.usd);
  });

  testWidgets('ListingsFilterForm shows seed values when reopened', (
    tester,
  ) async {
    final l10n = ruStrings();
    const seed = ListingsFilterFormSeed(
      make: 'Volkswagen',
      model: 'Golf',
      minYear: 2015,
      maxYear: 2020,
      minPrice: 5000,
      maxPrice: 15000,
      maxMileage: 120000,
      city: 'Тирасполь',
      typeFilter: ListingTypeFilter.sale,
      region: MarketRegionFilter.moldova,
      sort: ListingSortOption.priceLowToHigh,
      bodyType: null,
      fuelType: null,
      transmissionType: null,
      drivetrain: null,
      priceCurrencyFilter: ListingPriceCurrencyFilter.any,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(children: [ListingsFilterForm(seed: seed)]),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Volkswagen'), findsOneWidget);
    expect(find.text('Golf'), findsOneWidget);
    expect(find.text('2015'), findsOneWidget);
    expect(find.text('2020'), findsOneWidget);
    expect(find.text('5000'), findsOneWidget);
    expect(find.text('15000'), findsOneWidget);
    expect(find.text('120000'), findsOneWidget);
    expect(find.text('Тирасполь'), findsOneWidget);
    expect(find.text(l10n.typeSale), findsOneWidget);
  });

  testWidgets('Apply invokes callback with result from host', (tester) async {
    final l10n = ruStrings();
    ListingsFilterApplyResult? received;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (r) => received = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.filterShowCars));
    await tester.pumpAndSettle();
    expect(received, isNotNull);
    expect(received!.cleared, isTrue);
  });

  testWidgets('summary strip updates live when make changes', (tester) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text(l10n.filtersSummaryDefaultTitle), findsOneWidget);
    await pickListingFilterBrand(tester, 'Toyota');
    await tester.pump();
    expect(find.text(l10n.filtersSummaryDefaultTitle), findsNothing);
    expect(find.textContaining('Toyota'), findsWidgets);
  });

  testWidgets('reset returns summary to default; sheet stays open', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pickListingFilterBrand(tester, 'Toyota');
    await tester.pump();
    expect(find.text(l10n.filtersSummaryDefaultTitle), findsNothing);
    await tester.tap(find.text(l10n.filterClear));
    await tester.pump();
    expect(find.text(l10n.filtersSummaryDefaultTitle), findsOneWidget);
    expect(find.text(l10n.filtersTitle), findsOneWidget);
  });

  testWidgets(
    'ListingsFilterHost alertSetup mode shows singular alert editor copy',
    (tester) async {
      final l10n = ruStrings();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListingsFilterHost(
            mode: ListingsFilterHostMode.alertSetup,
            seed: ListingsFilterFormSeed.fromListingsState(
              const ListingsState(),
            ),
            onDismiss: () {},
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(l10n.filterAlertEditorEyebrow), findsOneWidget);
      expect(find.text(l10n.filterAlertEditorTitle), findsOneWidget);
      expect(find.text(l10n.filterAlertEditorSubtitle), findsOneWidget);
      expect(find.text(l10n.filterAlertSaveFilterAction), findsOneWidget);
      expect(find.text(l10n.filtersTitle), findsNothing);
      expect(find.text(l10n.filterShowCars), findsNothing);
      expect(find.text(l10n.filterClear), findsOneWidget);
      expect(find.byType(ListingsFilterSummaryStrip), findsNothing);
      expect(find.text(l10n.filtersSummaryDefaultTitle), findsNothing);
    },
  );

  testWidgets('Apply in alertSetup mode invokes callback with save button', (
    tester,
  ) async {
    final l10n = ruStrings();
    ListingsFilterApplyResult? received;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          mode: ListingsFilterHostMode.alertSetup,
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (r) => received = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.filterAlertSaveFilterAction));
    await tester.pumpAndSettle();
    expect(received, isNotNull);
    expect(received!.cleared, isTrue);
  });

  testWidgets('alertSetup exposes same catalog make picker', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          mode: ListingsFilterHostMode.alertSetup,
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey<String>('listings_filter_make_pick_trigger')),
      findsOneWidget,
    );
    expect(find.byType(ListingsFilterSummaryStrip), findsNothing);
  });

  testWidgets('apply passes canonical multi-word catalog make', (tester) async {
    final l10n = ruStrings();
    ListingsFilterApplyResult? received;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (r) => received = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pickListingFilterBrand(tester, 'Mercedes-Benz');
    await tester.tap(find.text(l10n.filterShowCars));
    await tester.pumpAndSettle();
    expect(received?.make, 'Mercedes-Benz');
  });

  testWidgets('apply passes newly added Chinese catalog make', (tester) async {
    final l10n = ruStrings();
    ListingsFilterApplyResult? received;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (r) => received = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pickListingFilterBrand(tester, 'Lynk & Co');
    await tester.tap(find.text(l10n.filterShowCars));
    await tester.pumpAndSettle();
    expect(received?.make, 'Lynk & Co');
  });

  testWidgets('apply passes picked catalog make into apply result', (
    tester,
  ) async {
    final l10n = ruStrings();
    ListingsFilterApplyResult? received;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (r) => received = r,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await pickListingFilterBrand(tester, 'Toyota');
    await tester.tap(find.text(l10n.filterShowCars));
    await tester.pumpAndSettle();
    expect(received?.make, 'Toyota');
  });

  testWidgets('inverted min/max years from seed blocks apply', (tester) async {
    final l10n = ruStrings();
    ListingsFilterApplyResult? received;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(
            const ListingsState(minYear: 2024, maxYear: 1998),
          ),
          onDismiss: () {},
          onApply: (r) => received = r,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(l10n.filterShowCars),
      140,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(find.text(l10n.filterShowCars));
    await tester.pumpAndSettle();
    expect(received, isNull);
    expect(find.text(l10n.filterYearRangeInverted), findsWidgets);
  });

  testWidgets(
    'browse budget and year bounded fields use price/year labels, soft empty mark, and CTAs',
    (tester) async {
      const emptyBound = '\u2014';
      final l10n = ruStrings();
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListingsFilterHost(
            seed: ListingsFilterFormSeed.fromListingsState(
              const ListingsState(),
            ),
            onDismiss: () {},
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.filterShowCars), findsOneWidget);
      expect(find.text(l10n.filtersSectionBudget), findsOneWidget);
      expect(find.text(l10n.filterYearManufactureSection), findsOneWidget);
      expect(find.text(l10n.filterYearFromShort), findsOneWidget);
      expect(find.text(l10n.filterYearToShort), findsOneWidget);
      expect(find.text(l10n.filterPriceFrom), findsOneWidget);
      expect(find.text(l10n.filterPriceTo), findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('listings_filter_min_price_pick'),
          ),
          matching: find.text(l10n.filterPriceFrom),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('listings_filter_max_price_pick'),
          ),
          matching: find.text(l10n.filterPriceTo),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('listings_filter_min_price_field'),
          ),
          matching: find.text(emptyBound),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('listings_filter_max_price_field'),
          ),
          matching: find.text(emptyBound),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('listings_filter_min_year_pick'),
          ),
          matching: find.text(emptyBound),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('listings_filter_max_year_pick'),
          ),
          matching: find.text(emptyBound),
        ),
        findsOneWidget,
      );
      expect(find.text(l10n.createListingChooseYear), findsNothing);

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListingsFilterHost(
            mode: ListingsFilterHostMode.alertSetup,
            seed: ListingsFilterFormSeed.fromListingsState(
              const ListingsState(),
            ),
            onDismiss: () {},
            onApply: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text(l10n.filterAlertSaveFilterAction), findsOneWidget);
      expect(find.text(l10n.filterYearFromShort), findsOneWidget);
      expect(find.text(l10n.filterYearToShort), findsOneWidget);
      expect(find.text(l10n.filterPriceFrom), findsOneWidget);
      expect(find.text(l10n.filterPriceTo), findsOneWidget);
    },
  );

  testWidgets('browse filter reset invokes onBrowseFeedReset', (tester) async {
    final l10n = ruStrings();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
          onBrowseFeedReset: () => calls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.filterClear));
    await tester.tap(find.text(l10n.filterClear));
    await tester.pump();
    expect(calls, 1);
  });

  testWidgets(
    'alertSetup filter reset invokes onAlertResetPersist (not browse callback)',
    (tester) async {
      final l10n = ruStrings();
      var persistCalls = 0;
      var browseCalls = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListingsFilterHost(
            mode: ListingsFilterHostMode.alertSetup,
            seed: ListingsFilterFormSeed.fromListingsState(
              const ListingsState(),
            ),
            onDismiss: () {},
            onApply: (_) {},
            onBrowseFeedReset: () => browseCalls++,
            onAlertResetPersist: () async {
              persistCalls++;
            },
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text(l10n.filterClear));
      await tester.tap(find.text(l10n.filterClear));
      await tester.pumpAndSettle();
      expect(persistCalls, 1);
      expect(browseCalls, 0);
    },
  );

  testWidgets('alertSetup filter reset does not invoke onBrowseFeedReset', (
    tester,
  ) async {
    final l10n = ruStrings();
    var calls = 0;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          mode: ListingsFilterHostMode.alertSetup,
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
          onBrowseFeedReset: () => calls++,
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text(l10n.filterClear));
    await tester.tap(find.text(l10n.filterClear));
    await tester.pump();
    expect(calls, 0);
  });

  testWidgets('vehicle spec selectors use premium pick sheets', (tester) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListingsFilterForm(
              seed: ListingsFilterFormSeed.fromListingsState(
                const ListingsState(
                  fuelTypeFilter: ListingFuelType.hybrid,
                  transmissionTypeFilter: ListingTransmissionType.automatic,
                  bodyTypeFilter: ListingBodyType.suv,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButton<ListingBodyType?>), findsNothing);
    expect(find.byType(DropdownButton<ListingFuelType?>), findsNothing);
    expect(find.byType(DropdownButton<ListingTransmissionType?>), findsNothing);
    expect(find.byType(DropdownButton<ListingDrivetrain?>), findsNothing);
    expect(find.byType(DropdownButton<ListingSortOption>), findsNothing);

    final bodyTrigger = find.byKey(
      const ValueKey<String>('listings_filter_body_type_pick_trigger'),
    );
    final fuelTrigger = find.byKey(
      const ValueKey<String>('listings_filter_fuel_type_pick_trigger'),
    );
    final transmissionTrigger = find.byKey(
      const ValueKey<String>('listings_filter_transmission_type_pick_trigger'),
    );
    final drivetrainTrigger = find.byKey(
      const ValueKey<String>('listings_filter_drivetrain_pick_trigger'),
    );

    expect(drivetrainTrigger, findsOneWidget);

    expect(
      find.descendant(
        of: bodyTrigger,
        matching: find.text(l10n.listingBodyTypeSuv),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: fuelTrigger,
        matching: find.text(l10n.listingFuelTypeHybrid),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: transmissionTrigger,
        matching: find.text(l10n.listingTransmissionAutomatic),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      fuelTrigger,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(fuelTrigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.listingFuelTypeDiesel).last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: fuelTrigger,
        matching: find.text(l10n.listingFuelTypeDiesel),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      transmissionTrigger,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(transmissionTrigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.listingTransmissionManual).last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: transmissionTrigger,
        matching: find.text(l10n.listingTransmissionManual),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      drivetrainTrigger,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(drivetrainTrigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.listingDrivetrainAwd).last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: drivetrainTrigger,
        matching: find.text(l10n.listingDrivetrainAwd),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      bodyTrigger,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(bodyTrigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.listingBodyTypeNotSpecified).last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: bodyTrigger,
        matching: find.text(l10n.listingsBodyChipAll),
      ),
      findsOneWidget,
    );
  });

  testWidgets('sort selector uses premium pick sheet', (tester) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListingsFilterForm(
              seed: ListingsFilterFormSeed.fromListingsState(
                const ListingsState(
                  sortOption: ListingSortOption.priceLowToHigh,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(DropdownButton<ListingSortOption>), findsNothing);

    final sortTrigger = find.byKey(
      const ValueKey<String>('listings_filter_sort_pick_trigger'),
    );
    expect(
      find.descendant(
        of: sortTrigger,
        matching: find.text(l10n.filterSortPriceLowHigh),
      ),
      findsOneWidget,
    );

    await tester.scrollUntilVisible(
      sortTrigger,
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(sortTrigger);
    await tester.pumpAndSettle();
    await tester.tap(find.text(l10n.filterSortPriceHighLow).last);
    await tester.pumpAndSettle();

    expect(
      find.descendant(
        of: sortTrigger,
        matching: find.text(l10n.filterSortPriceHighLow),
      ),
      findsOneWidget,
    );
  });

  testWidgets('premium segmented selectors update region and listing type', (
    tester,
  ) async {
    final l10n = ruStrings();
    final formKey = GlobalKey<ListingsFilterFormState>();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            child: ListingsFilterForm(
              key: formKey,
              seed: ListingsFilterFormSeed.fromListingsState(
                const ListingsState(),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(FilterChip), findsNothing);

    await tester.scrollUntilVisible(
      find.text(l10n.regionMoldova),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.regionMoldova));
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text(l10n.typeSale),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text(l10n.typeSale));
    await tester.pumpAndSettle();

    final result = formKey.currentState!.submit();
    expect(result, isNotNull);
    expect(result!.region, MarketRegionFilter.moldova);
    expect(result.typeFilter, ListingTypeFilter.sale);
  });

  testWidgets(
    'region segmented labels stay fully readable for each selection',
    (tester) async {
      final l10n = ruStrings();
      await tester.binding.setSurfaceSize(const Size(360, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      for (final region in [
        MarketRegionFilter.transnistria,
        MarketRegionFilter.moldova,
        MarketRegionFilter.both,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('ru'),
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: SingleChildScrollView(
                child: ListingsFilterForm(
                  seed: ListingsFilterFormSeed.fromListingsState(
                    ListingsState(regionFilter: region),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        final regionControl = find.byKey(
          const ValueKey<String>('listings_filter_region_segmented'),
        );

        await tester.scrollUntilVisible(
          regionControl,
          120,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.pumpAndSettle();

        for (final label in [
          l10n.regionTransnistria,
          l10n.regionMoldova,
          l10n.regionBoth,
        ]) {
          expect(
            find.descendant(of: regionControl, matching: find.text(label)),
            findsOneWidget,
          );
        }

        expect(
          find.descendant(
            of: regionControl,
            matching: find.textContaining('...'),
          ),
          findsNothing,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );

  testWidgets('variant segmented controls render on compact viewport', (
    tester,
  ) async {
    final l10n = ruStrings();
    tester.view.physicalSize = const Size(320, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: ListingsFilterHost(
          seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
          onDismiss: () {},
          onApply: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey<String>('listings_filter_currency_segmented')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('listings_filter_region_segmented')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('listings_filter_type_segmented')),
      findsOneWidget,
    );
    expect(find.text(l10n.regionTransnistria), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('currency selector keeps stable size when selection changes', (
    tester,
  ) async {
    final l10n = ruStrings();
    await _pumpStandaloneFilterForm(tester);

    final control = find.byKey(
      const ValueKey<String>('listings_filter_currency_segmented'),
    );
    await _scrollFilterControlIntoView(tester, control);

    final baseline = tester.getSize(control);
    expect(
      baseline.height,
      filterChoiceVariantOuterHeight(
        ListingsFilterSegmentedControlVariant.currency,
      ),
    );

    for (final label in [
      l10n.filterPriceCurrencyUsd,
      l10n.filterPriceCurrencyEur,
      l10n.filterPriceCurrencyAny,
    ]) {
      final option = find.descendant(of: control, matching: find.text(label));
      await _scrollFilterControlIntoView(tester, option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(tester.getSize(control), baseline);
    }
  });

  testWidgets('region selector keeps stable size when selection changes', (
    tester,
  ) async {
    final l10n = ruStrings();
    await _pumpStandaloneFilterForm(tester);

    final control = find.byKey(
      const ValueKey<String>('listings_filter_region_segmented'),
    );
    await _scrollFilterControlIntoView(tester, control);

    final baseline = tester.getSize(control);
    expect(
      baseline.height,
      filterChoiceVariantOuterHeight(
        ListingsFilterSegmentedControlVariant.region,
      ),
    );

    for (final label in [
      l10n.regionMoldova,
      l10n.regionTransnistria,
      l10n.regionBoth,
    ]) {
      final option = find.descendant(of: control, matching: find.text(label));
      await _scrollFilterControlIntoView(tester, option);
      await tester.tap(option);
      await tester.pumpAndSettle();
      expect(tester.getSize(control), baseline);
    }
  });

  testWidgets(
    'listing type selector keeps stable size when selection changes',
    (tester) async {
      final l10n = ruStrings();
      await _pumpStandaloneFilterForm(tester);

      final control = find.byKey(
        const ValueKey<String>('listings_filter_type_segmented'),
      );
      await _scrollFilterControlIntoView(tester, control);

      final baseline = tester.getSize(control);
      expect(
        baseline.height,
        filterChoiceVariantOuterHeight(
          ListingsFilterSegmentedControlVariant.listingType,
        ),
      );

      for (final label in [l10n.typeSale, l10n.typeExchange, l10n.typeAny]) {
        final option = find.descendant(of: control, matching: find.text(label));
        await _scrollFilterControlIntoView(tester, option);
        await tester.tap(option);
        await tester.pumpAndSettle();
        expect(tester.getSize(control), baseline);
      }
    },
  );

  group('summary strip layout stability on first filter change', () {
    testWidgets('summary strip height unchanged after currency first tap', (
      tester,
    ) async {
      final l10n = ruStrings();
      await _pumpFilterHostAtViewport(tester);

      expect(find.text(l10n.filtersSummaryDefaultTitle), findsOneWidget);

      final stripBaseline = _summaryStripSize(tester);
      final formBaseline = _filterFormSize(tester);
      final scrollBaseline = _filterListMaxScrollExtent(tester);

      final currencyControl = find.byKey(
        const ValueKey<String>('listings_filter_currency_segmented'),
      );
      await _scrollFilterControlIntoView(tester, currencyControl);
      await tester.tap(find.text(l10n.filterPriceCurrencyUsd));
      await tester.pumpAndSettle();

      expect(find.text(l10n.filtersSummaryDefaultTitle), findsNothing);
      expect(_summaryStripSize(tester), stripBaseline);
      expect(_filterFormSize(tester), formBaseline);
      expect(_filterListMaxScrollExtent(tester), scrollBaseline);
    });

    testWidgets('summary strip height unchanged after region first tap', (
      tester,
    ) async {
      final l10n = ruStrings();
      await _pumpFilterHostAtViewport(tester);

      final stripBaseline = _summaryStripSize(tester);
      final formBaseline = _filterFormSize(tester);

      final regionControl = find.byKey(
        const ValueKey<String>('listings_filter_region_segmented'),
      );
      await _scrollFilterControlIntoView(tester, regionControl);
      await tester.tap(find.text(l10n.regionMoldova));
      await tester.pumpAndSettle();

      expect(_summaryStripSize(tester), stripBaseline);
      expect(_filterFormSize(tester), formBaseline);
    });

    testWidgets('summary strip height unchanged after listing type first tap', (
      tester,
    ) async {
      final l10n = ruStrings();
      await _pumpFilterHostAtViewport(tester);

      final stripBaseline = _summaryStripSize(tester);
      final formBaseline = _filterFormSize(tester);
      final scrollBaseline = _filterListMaxScrollExtent(tester);

      final typeControl = find.byKey(
        const ValueKey<String>('listings_filter_type_segmented'),
      );
      await _scrollFilterControlIntoView(tester, typeControl);
      await tester.tap(find.text(l10n.typeSale));
      await tester.pumpAndSettle();

      expect(_summaryStripSize(tester), stripBaseline);
      expect(_filterFormSize(tester), formBaseline);
      expect(_filterListMaxScrollExtent(tester), scrollBaseline);
    });

    testWidgets(
      'reserved outer height matches measured vanilla strip on viewport',
      (tester) async {
        await _pumpFilterHostAtViewport(tester);

        final theme = Theme.of(
          tester.element(find.byType(ListingsFilterSummaryStrip)),
        );
        final measured = _summaryStripSize(tester);
        final reserved = ListingsFilterSummaryStrip.reservedOuterHeight(
          theme,
          light: theme.brightness == Brightness.light,
        );

        expect(measured.height, reserved);
      },
    );
  });
}
