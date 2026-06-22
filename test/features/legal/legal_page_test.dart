import 'package:carzon/features/legal/presentation/pages/legal_page.dart';
import 'package:carzon/features/legal/presentation/utils/legal_sections_builder.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  Widget wrap({
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
      home: const LegalPage(),
    );
  }

  Future<void> scrollToText(WidgetTester tester, String text) async {
    final listFinder = find.byType(Scrollable);
    final textFinder = find.text(text);
    await tester.scrollUntilVisible(textFinder, 200, scrollable: listFinder);
    expect(textFinder, findsOneWidget);
  }

  testWidgets('LegalPage renders the AppBar title', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.widgetWithText(AppBar, l10n.legalTitle), findsOneWidget);
  });

  testWidgets('LegalPage renders disclaimer callout with label', (tester) async {
    await tester.pumpWidget(wrap());

    expect(
      find.byKey(const ValueKey<String>('legal_disclaimer_callout')),
      findsOneWidget,
    );
    expect(find.text(l10n.legalDisclaimerLabel), findsOneWidget);
    expect(find.text(l10n.legalDisclaimer), findsOneWidget);
  });

  testWidgets('LegalPage renders the required section headings', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    for (final heading in buildLegalSections(l10n).map((s) => s.heading)) {
      await scrollToText(tester, heading);
    }
  });

  testWidgets('LegalPage renders contact bullets', (tester) async {
    await tester.pumpWidget(wrap());

    await scrollToText(tester, l10n.legalSectionContactHeading);
    expect(find.text(l10n.legalSectionContactB1), findsOneWidget);
    expect(find.text(l10n.legalSectionContactB2), findsOneWidget);
    expect(find.text(l10n.legalSectionContactB3), findsOneWidget);
  });

  testWidgets('LegalPage body is scrollable', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byType(ListView), findsOneWidget);
  });

  testWidgets('LegalPage shows suspicious-link and scam safety guidance', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    await scrollToText(tester, l10n.legalSectionSafetyP4);
    expect(find.textContaining('подозрительных ссылок'), findsOneWidget);
  });

  testWidgets('LegalPage shows official-data and recall limitation guidance', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    await scrollToText(tester, l10n.legalSectionSafetyP5);
    expect(find.textContaining('кампаниям отзыва'), findsOneWidget);
  });

  testWidgets('LegalPage contact copy mentions in-app support via Settings', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    await scrollToText(tester, l10n.legalSectionContactUsP2);
    expect(find.textContaining('Настройки'), findsOneWidget);
    expect(find.textContaining('Связаться с поддержкой'), findsOneWidget);
  });

  testWidgets('LegalPage renders in RO locale without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(locale: const Locale('ro')));
    await tester.pumpAndSettle();

    final ro = lookupAppLocalizations(const Locale('ro'));
    expect(find.widgetWithText(AppBar, ro.legalTitle), findsOneWidget);
    await scrollToText(tester, ro.legalSectionSafetyP4);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LegalPage renders in dark theme without exceptions', (
    tester,
  ) async {
    await tester.pumpWidget(wrap(themeMode: ThemeMode.dark));
    await tester.pumpAndSettle();

    expect(find.byType(LegalPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('LegalPage renders on narrow width without overflow', (
    tester,
  ) async {
    final binding = TestWidgetsFlutterBinding.ensureInitialized();
    binding.window.physicalSizeTestValue = const Size(320, 800);
    binding.window.devicePixelRatioTestValue = 1.0;
    addTearDown(binding.window.clearPhysicalSizeTestValue);
    addTearDown(binding.window.clearDevicePixelRatioTestValue);

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.byType(LegalPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
