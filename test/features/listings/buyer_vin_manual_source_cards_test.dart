import 'dart:io';

import 'package:carzon/features/listings/presentation/utils/vin_manual_source_cards.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('ru'));
  });

  test('buildBuyerVinManualSourceCards returns four stable source ids', () {
    final cards = buildBuyerVinManualSourceCards(l10n);
    expect(cards.length, 4);
    expect(cards.map((c) => c.sourceId).toList(), kBuyerVinManualSourceCardIds);
  });

  test('manual card copy is conservative and omits forbidden wording', () {
    final cards = buildBuyerVinManualSourceCards(l10n);
    final combined = cards
        .map((c) => '${c.title} ${c.body} ${c.statusLabel} ${c.limitationLine}')
        .join(' ')
        .toLowerCase();

    expect(combined, contains('carzon не получает'));
    expect(combined, isNot(contains('vin проверен')));
    expect(combined, isNot(contains('официально проверено')));
    expect(combined, isNot(contains('история проверена')));
    expect(combined, isNot(contains('без дтп')));
    expect(combined, isNot(contains('чистая история')));
    expect(combined, isNot(contains('юридически чист')));
    expect(combined, isNot(contains('пробег подтвержд')));
    expect(combined, isNot(contains('ограничений нет')));
  });

  test('ARB manual block includes section title and status labels', () {
    final raw = File('lib/l10n/app_ru.arb').readAsStringSync();
    expect(raw, contains('listingBuyerVinReportManualSourcesSectionTitle'));
    expect(raw, contains('listingBuyerVinReportManualMdRcaTitle'));
    expect(raw, contains('listingBuyerVinReportManualStatusExternalCheck'));
    expect(raw, contains('Дополнительные проверки'));
  });
}
