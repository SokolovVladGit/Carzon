import 'package:carzon/features/listings/domain/catalog/listing_brands.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_brand_pick_sheet.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  testWidgets('ListingBrandPickSheet lists full catalog including new brands', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListingBrandPickSheet(appL10n: l10n)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Toyota'), findsOneWidget);
    expect(find.text('Mercedes-Benz'), findsOneWidget);
    expect(find.byType(ListTile), findsWidgets);

    expect(find.text(kListingBrandCatalogOther), findsNothing);

    final otherLabel = localizedListingBrandCatalogLabel(
      l10n,
      kListingBrandCatalogOther,
    );
    await tester.enterText(find.byType(TextField), otherLabel.substring(0, 3));
    await tester.pump();
    expect(find.text(otherLabel), findsOneWidget);
  });

  testWidgets('ListingBrandPickSheet search filters to matching brands', (
    tester,
  ) async {
    final l10n = ruStrings();
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: ListingBrandPickSheet(appL10n: l10n)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'byd');
    await tester.pump();

    expect(find.text('BYD'), findsOneWidget);
    expect(find.text('Toyota'), findsNothing);
  });

  testWidgets('picking a catalog brand returns canonical English spelling', (
    tester,
  ) async {
    final l10n = ruStrings();
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                picked = await showListingBrandPickSheet(
                  context: context,
                  l10n: l10n,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    final brandTile = find.text('Mercedes-Benz');
    await tester.scrollUntilVisible(
      brandTile,
      120,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.pumpAndSettle();
    await tester.tap(brandTile);
    await tester.pumpAndSettle();

    expect(picked, 'Mercedes-Benz');
  });

  testWidgets('zero-match search shows manual-entry CTA and returns custom make', (
    tester,
  ) async {
    final l10n = ruStrings();
    String? picked;
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () async {
                picked = await showListingBrandPickSheet(
                  context: context,
                  l10n: l10n,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    const customMake = 'Zaporozhets';
    await tester.enterText(find.byType(TextField), customMake);
    await tester.pumpAndSettle();

    expect(find.text(l10n.brandPickNotFoundTitle), findsOneWidget);
    expect(find.text(l10n.brandPickUseMake(customMake)), findsOneWidget);

    await tester.tap(find.text(l10n.brandPickUseMake(customMake)));
    await tester.pumpAndSettle();

    expect(picked, customMake);
  });

  testWidgets(
    'software keyboard inset keeps empty and filtered results usable',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(375, 667));
      tester.view.viewInsets = const FakeViewPadding(bottom: 291);
      addTearDown(() async {
        tester.view.resetViewInsets();
        await tester.binding.setSurfaceSize(null);
      });

      final l10n = ruStrings();
      String? picked;
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ru'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  picked = await showListingBrandPickSheet(
                    context: context,
                    l10n: l10n,
                  );
                },
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final search = find.byType(TextField);
      await tester.tap(search);
      await tester.showKeyboard(search);
      await tester.pumpAndSettle();

      expect(find.text('Toyota'), findsOneWidget);
      final results = find.byType(ListView);
      expect(results, findsOneWidget);
      expect(tester.getSize(results).height, greaterThan(100));
      expect(tester.takeException(), isNull);

      await tester.enterText(search, 'byd');
      await tester.pumpAndSettle();

      expect(find.text('BYD'), findsOneWidget);
      expect(find.text('Toyota'), findsNothing);
      expect(tester.getSize(results).height, greaterThan(100));
      expect(tester.takeException(), isNull);

      await tester.tap(find.text('BYD'));
      await tester.pumpAndSettle();
      expect(picked, 'BYD');
    },
  );
}
