import 'package:carzon/core/theme/app_theme.dart';
import 'package:carzon/features/listings/presentation/widgets/buyer_vin_report_sheet_ui.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();

  group('buyerVinReportSectionDecoration', () {
    test('dark mode uses editorial card for data sections', () {
      final scheme = AppTheme.dark().colorScheme;
      final decoration = buyerVinReportSectionDecoration(
        scheme,
        BuyerVinReportSectionTone.dataCore,
      );

      expect(decoration.gradient, isNotNull);
      expect(decoration.border, isNotNull);
    });

    test('light mode dataCore keeps flat surface fill', () {
      final scheme = AppTheme.light().colorScheme;
      final decoration = buyerVinReportSectionDecoration(
        scheme,
        BuyerVinReportSectionTone.dataCore,
      );

      expect(decoration.color, isNotNull);
      expect(decoration.gradient, isNull);
    });
  });

  testWidgets('buyer VIN report hero renders title and close label in dark', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: BuyerVinReportHeroHeader(
              theme: AppTheme.dark(),
              reportTitle: ru.listingBuyerVinReportTitle,
              vinAddedLine: ru.listingBuyerVinReportVinAddedBySeller,
              vinPrivateLine: ru.listingBuyerVinReportFullVinPrivate,
              compareResult: ru.listingBuyerVinReportCompareMatch,
              compareIsMatch: true,
              showSuccessVinBadge: true,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('buyer_vin_report_hero_header')),
      findsOneWidget,
    );
    expect(find.text(ru.listingBuyerVinReportTitle), findsOneWidget);
    expect(
      find.byKey(const ValueKey('vin_present_latin_badge')),
      findsOneWidget,
    );
    expect(find.text(ru.listingBuyerVinReportCompareMatch), findsOneWidget);
    expect(find.textContaining('verified', findRichText: true), findsNothing);
    expect(
      find.textContaining('официально проверен', findRichText: true),
      findsNothing,
    );
  });

  testWidgets('sticky footer close button renders in dark', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark(),
        locale: const Locale('ru'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BuyerVinReportStickyFooter(
            theme: AppTheme.dark(),
            bottomInset: 0,
            closeLabel: ru.listingBuyerVinReportClose,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('buyer_vin_report_sheet_close')),
      findsOneWidget,
    );
    expect(find.text(ru.listingBuyerVinReportClose), findsOneWidget);
  });
}
