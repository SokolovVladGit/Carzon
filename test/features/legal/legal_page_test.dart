import 'package:carzon/features/legal/presentation/pages/legal_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  Widget wrap() => localizedApp(home: const LegalPage());

  testWidgets('LegalPage renders the AppBar title', (tester) async {
    await tester.pumpWidget(wrap());

    expect(
      find.widgetWithText(AppBar, l10n.legalTitle),
      findsOneWidget,
    );
  });

  testWidgets('LegalPage renders the required section headings',
      (tester) async {
    await tester.pumpWidget(wrap());

    // Each heading is rendered as a distinct Text widget inside the
    // scrollable body. Because the body is a lazy ListView, headings
    // below the initial viewport are not built until scrolled to, so
    // we drive a scroll-until-visible for each required heading.
    final listFinder = find.byType(Scrollable);
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
      final headingFinder = find.text(heading);
      await tester.scrollUntilVisible(
        headingFinder,
        200,
        scrollable: listFinder,
      );
      expect(
        headingFinder,
        findsOneWidget,
        reason: 'Expected section "$heading" to be rendered',
      );
    }
  });

  testWidgets('LegalPage body is scrollable', (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.byType(ListView), findsOneWidget);
  });
}
