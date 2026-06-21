import 'package:carzon/features/legal/presentation/pages/legal_page.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  Widget wrap({Locale locale = const Locale('ru')}) => MaterialApp(
    locale: locale,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: const LegalPage(),
  );

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

  testWidgets('LegalPage renders the required section headings', (
    tester,
  ) async {
    await tester.pumpWidget(wrap());

    // Each heading is rendered as a distinct Text widget inside the
    // scrollable body. Because the body is a lazy ListView, headings
    // below the initial viewport are not built until scrolled to, so
    // we drive a scroll-until-visible for each required heading.
    for (final heading in [
      l10n.legalSectionAboutHeading,
      l10n.legalSectionListingsHeading,
      l10n.legalSectionContactHeading,
      l10n.legalSectionPhotosHeading,
      l10n.legalSectionAccountHeading,
      l10n.legalSectionFavoritesHeading,
      l10n.legalSectionSafetyHeading,
      l10n.legalSectionContactUsHeading,
    ]) {
      await scrollToText(tester, heading);
    }
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
}
