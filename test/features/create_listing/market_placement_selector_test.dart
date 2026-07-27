import 'package:carzon/features/create_listing/presentation/widgets/market_placement_selector.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _SelectorHost extends StatefulWidget {
  const _SelectorHost({required this.locale});

  final Locale locale;

  @override
  State<_SelectorHost> createState() => _SelectorHostState();
}

class _SelectorHostState extends State<_SelectorHost> {
  MarketRegion region = MarketRegion.transnistria;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      locale: widget.locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Builder(
        builder: (context) => Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                MarketPlacementSelector(
                  l10n: AppLocalizations.of(context),
                  theme: Theme.of(context),
                  value: region,
                  submitting: false,
                  onChanged: (value) => setState(() => region = value),
                ),
                const SizedBox(key: ValueKey('layout_marker'), height: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  const transnistriaTile = ValueKey('market_region_transnistria');
  const moldovaTile = ValueKey('market_region_moldova');

  testWidgets(
    'Russian region tiles remain single-line and stable when selection changes',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const _SelectorHost(locale: Locale('ru')));
      await tester.pumpAndSettle();

      final transnistriaText = tester.widget<Text>(find.text('Приднестровье'));
      expect(transnistriaText.maxLines, 1);
      expect(transnistriaText.softWrap, isFalse);
      expect(
        find.descendant(
          of: find.byKey(transnistriaTile),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );

      final initialTransnistriaSize = tester.getSize(
        find.byKey(transnistriaTile),
      );
      final initialMoldovaSize = tester.getSize(find.byKey(moldovaTile));
      final initialMarkerTop = tester.getTopLeft(
        find.byKey(const ValueKey('layout_marker')),
      );
      expect(initialTransnistriaSize.height, initialMoldovaSize.height);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(moldovaTile));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(moldovaTile),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(transnistriaTile),
          matching: find.byIcon(Icons.check_rounded),
        ),
        findsNothing,
      );
      expect(
        tester.getSize(find.byKey(transnistriaTile)),
        initialTransnistriaSize,
      );
      expect(tester.getSize(find.byKey(moldovaTile)), initialMoldovaSize);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('layout_marker'))),
        initialMarkerTop,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Romanian region labels do not overflow at 320 px', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(320, 568));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const _SelectorHost(locale: Locale('ro')));
    await tester.pumpAndSettle();

    for (final label in ['Transnistria', 'Moldova']) {
      final text = tester.widget<Text>(find.text(label));
      expect(text.maxLines, 1);
      expect(text.softWrap, isFalse);
    }
    expect(tester.takeException(), isNull);
  });
}
