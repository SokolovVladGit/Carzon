import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/presentation/widgets/listing_city_pick_sheet.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _PickerHost extends StatefulWidget {
  const _PickerHost({
    required this.region,
    this.selected,
    this.themeMode = ThemeMode.light,
  });

  final MarketRegion region;
  final String? selected;
  final ThemeMode themeMode;

  @override
  State<_PickerHost> createState() => _PickerHostState();
}

class _PickerHostState extends State<_PickerHost> {
  ListingCityPickResult? result;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: const Locale('ru'),
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: widget.themeMode,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Column(
            children: [
              FilledButton(
                key: const ValueKey('open_city_picker'),
                onPressed: () async {
                  final picked = await showListingCityPickSheet(
                    context: context,
                    l10n: AppLocalizations.of(context),
                    region: widget.region,
                    selectedCanonicalCity: widget.selected,
                  );
                  if (picked != null) setState(() => result = picked);
                },
                child: const Text('open'),
              ),
              if (result != null)
                Text(
                  result!.manual ? 'manual' : result!.canonicalValue!,
                  key: const ValueKey('picker_result'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> _open(WidgetTester tester, Widget host) async {
  await tester.pumpWidget(host);
  await tester.tap(find.byKey(const ValueKey('open_city_picker')));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows only the selected region catalog', (tester) async {
    await _open(tester, const _PickerHost(region: MarketRegion.transnistria));
    expect(find.text('Тирасполь'), findsOneWidget);
    expect(find.text('Chișinău'), findsNothing);
    expect(
      find.byKey(const ValueKey('listing_city_manual_option')),
      findsOneWidget,
    );

    await tester.tap(find.byTooltip('Отмена'));
    await tester.pumpAndSettle();
    await _open(tester, const _PickerHost(region: MarketRegion.moldova));
    expect(find.text('Chișinău'), findsOneWidget);
    expect(find.text('Тирасполь'), findsNothing);
  });

  testWidgets('marks selected city and returns a known canonical value', (
    tester,
  ) async {
    await _open(
      tester,
      const _PickerHost(region: MarketRegion.moldova, selected: 'Bălți'),
    );
    final tile = tester.widget<ListTile>(
      find.byKey(const ValueKey('listing_city_Bălți')),
    );
    expect(tile.selected, isTrue);

    await tester.tap(find.text('Bălți'));
    await tester.pumpAndSettle();
    expect(find.text('Bălți'), findsOneWidget);
  });

  testWidgets(
    'search matches aliases and keeps manual fallback on no results',
    (tester) async {
      await _open(tester, const _PickerHost(region: MarketRegion.moldova));
      final search = find.byKey(const ValueKey('listing_city_search_field'));
      await tester.enterText(search, 'Strășeni');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('listing_city_Strășeni')),
        findsOneWidget,
      );
      expect(find.text('Chișinău'), findsNothing);

      await tester.enterText(search, 'Chisinau');
      await tester.pumpAndSettle();
      expect(find.text('Chișinău'), findsOneWidget);
      expect(find.text('Bălți'), findsNothing);

      await tester.enterText(search, 'not-a-city');
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('listing_city_empty_state')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('listing_city_manual_option')),
        findsOneWidget,
      );
    },
  );

  testWidgets('manual option returns manual result', (tester) async {
    await _open(tester, const _PickerHost(region: MarketRegion.moldova));
    await tester.tap(find.byKey(const ValueKey('listing_city_manual_option')));
    await tester.pumpAndSettle();
    expect(find.text('manual'), findsOneWidget);
  });

  testWidgets('does not overflow at 320 px in light or dark theme', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await _open(
      tester,
      const _PickerHost(
        region: MarketRegion.transnistria,
        themeMode: ThemeMode.dark,
      ),
    );
    expect(tester.takeException(), isNull);
    expect(find.text('Другой населённый пункт'), findsOneWidget);
  });
}
