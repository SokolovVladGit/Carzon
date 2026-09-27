import 'dart:math' as math;

import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/create_listing/presentation/widgets/create_listing_compose_layout.dart';
import 'package:carzon/features/create_listing/presentation/widgets/listing_type_deal_selector.dart';
import 'package:carzon/features/create_listing/presentation/widgets/market_placement_selector.dart';
import 'package:carzon/features/create_listing/presentation/widgets/premium_listing_controls.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  BoxDecoration thumbOf(WidgetTester tester, String label) {
    final animated = tester.widget<AnimatedContainer>(
      find
          .ancestor(
            of: find.text(label),
            matching: find.byType(AnimatedContainer),
          )
          .first,
    );
    return animated.decoration! as BoxDecoration;
  }

  Color textColorOf(WidgetTester tester, String label) {
    return tester.widget<Text>(find.text(label)).style!.color!;
  }

  double contrast(Color foreground, Color background) {
    final lighter = math.max(
      foreground.computeLuminance(),
      background.computeLuminance(),
    );
    final darker = math.min(
      foreground.computeLuminance(),
      background.computeLuminance(),
    );
    return (lighter + 0.05) / (darker + 0.05);
  }

  Future<void> pumpCurrency(
    WidgetTester tester, {
    required ThemeData theme,
    required ListingCurrency selected,
    required ValueChanged<ListingCurrency> onChanged,
    double width = 390,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: SizedBox(
              width: width,
              child: PremiumListingCurrencyBar(
                theme: theme,
                selected: selected,
                enabled: true,
                eurLabel: l10n.currencyCodeEur,
                usdLabel: l10n.currencyCodeUsd,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pumpDeal(
    WidgetTester tester, {
    required ThemeData theme,
    required ListingType value,
    required ValueChanged<ListingType> onChanged,
    double width = 390,
    double textScale = 1,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: MediaQuery(
            data: MediaQueryData(textScaler: TextScaler.linear(textScale)),
            child: SizedBox(
              width: width,
              child: ListingTypeDealSelector(
                l10n: l10n,
                theme: theme,
                value: value,
                submitting: false,
                onChanged: onChanged,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void expectActive(WidgetTester tester, String label) {
    final fill = thumbOf(tester, label).color;
    final text = textColorOf(tester, label);
    expect(fill, kCreateListingActiveFill);
    expect(text, kCreateListingActiveForeground);
    expect(
      text,
      isNot(
        tester
            .widget<MaterialApp>(find.byType(MaterialApp))
            .theme!
            .colorScheme
            .primary,
      ),
    );
    expect(contrast(text, fill!), greaterThanOrEqualTo(4.5));
  }

  void expectInactive(WidgetTester tester, String label) {
    final theme = tester.widget<MaterialApp>(find.byType(MaterialApp)).theme!;
    final fill = thumbOf(tester, label).color;
    final text = textColorOf(tester, label);
    expect(fill, Colors.transparent);
    expect(text, isNot(kCreateListingActiveForeground));
    expect(text, isNot(theme.colorScheme.primary));
    expect(text, createListingInactiveSegmentLabel(theme));
  }

  testWidgets('selected EUR is graphite with white text', (tester) async {
    await pumpCurrency(
      tester,
      theme: AppTheme.light(),
      selected: ListingCurrency.eur,
      onChanged: (_) {},
    );
    expectActive(tester, l10n.currencyCodeEur);
    expectInactive(tester, l10n.currencyCodeUsd);
  });

  testWidgets('selected USD uses the same active treatment', (tester) async {
    ListingCurrency? changed;
    await pumpCurrency(
      tester,
      theme: AppTheme.light(),
      selected: ListingCurrency.eur,
      onChanged: (value) => changed = value,
    );
    await tester.tap(find.text(l10n.currencyCodeUsd));
    expect(changed, ListingCurrency.usd);

    await pumpCurrency(
      tester,
      theme: AppTheme.light(),
      selected: ListingCurrency.usd,
      onChanged: (_) {},
    );
    expectActive(tester, l10n.currencyCodeUsd);
    expectInactive(tester, l10n.currencyCodeEur);
  });

  testWidgets('selected Sale, Exchange, and Both use graphite and white', (
    tester,
  ) async {
    final seen = <ListingType>[];
    Future<void> check(ListingType value, String label) async {
      await pumpDeal(
        tester,
        theme: AppTheme.light(),
        value: value,
        onChanged: seen.add,
      );
      expectActive(tester, label);
      for (final other in [
        l10n.formatTypeSale,
        l10n.formatTypeExchange,
        l10n.createListingDealBothShort,
      ]) {
        if (other == label) continue;
        expectInactive(tester, other);
      }
    }

    await check(ListingType.sale, l10n.formatTypeSale);
    await tester.tap(find.text(l10n.formatTypeExchange));
    expect(seen, [ListingType.exchange]);

    await check(ListingType.exchange, l10n.formatTypeExchange);
    await tester.tap(find.text(l10n.createListingDealBothShort));
    expect(seen, [ListingType.exchange, ListingType.both]);

    await check(ListingType.both, l10n.createListingDealBothShort);
    await tester.tap(find.text(l10n.formatTypeSale));
    expect(seen, [ListingType.exchange, ListingType.both, ListingType.sale]);
  });

  testWidgets('dark mode keeps graphite contrast at 320 and large text', (
    tester,
  ) async {
    await pumpCurrency(
      tester,
      theme: AppTheme.dark(),
      selected: ListingCurrency.eur,
      onChanged: (_) {},
      width: 320,
      textScale: 1.3,
    );
    expectActive(tester, l10n.currencyCodeEur);
    expectInactive(tester, l10n.currencyCodeUsd);
    expect(tester.takeException(), isNull);

    await pumpDeal(
      tester,
      theme: AppTheme.dark(),
      value: ListingType.both,
      onChanged: (_) {},
      width: 320,
      textScale: 1.3,
    );
    expectActive(tester, l10n.createListingDealBothShort);
    expectInactive(tester, l10n.formatTypeSale);
    expectInactive(tester, l10n.formatTypeExchange);
    expect(tester.takeException(), isNull);
  });

  testWidgets('region selector keeps the neutral thumb', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: MarketPlacementSelector(
            l10n: l10n,
            theme: AppTheme.light(),
            value: MarketRegion.transnistria,
            submitting: false,
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final selected = thumbOf(tester, l10n.regionTransnistria);
    expect(selected.color, isNot(kCreateListingActiveFill));
    expect(
      textColorOf(tester, l10n.regionTransnistria),
      isNot(kCreateListingActiveForeground),
    );
  });
}
