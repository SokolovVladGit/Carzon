import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_apply_result.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_host.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_summary_strip.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';
import '../../helpers/filter_form_brand_picker_helpers.dart';

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
    expect(find.byKey(const ValueKey<String>('listings_filter_make_pick_trigger')), findsOneWidget);
    expect(find.byType(ListingsFilterSummaryStrip), findsOneWidget);
  });
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
      priceCurrencyFilter: ListingPriceCurrencyFilter.any,
    );

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: ListView(
            children: [ListingsFilterForm(seed: seed)],
          ),
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
            seed:
                ListingsFilterFormSeed.fromListingsState(const ListingsState()),
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
          seed:
              ListingsFilterFormSeed.fromListingsState(const ListingsState()),
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
            const ListingsState(
              minYear: 2024,
              maxYear: 1998,
            ),
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
            seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
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
            seed: ListingsFilterFormSeed.fromListingsState(const ListingsState()),
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
            seed:
                ListingsFilterFormSeed.fromListingsState(const ListingsState()),
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

  testWidgets(
    'alertSetup filter reset does not invoke onBrowseFeedReset',
    (tester) async {
      final l10n = ruStrings();
      var calls = 0;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: ListingsFilterHost(
            mode: ListingsFilterHostMode.alertSetup,
            seed:
                ListingsFilterFormSeed.fromListingsState(const ListingsState()),
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
    },
  );
}
