import 'dart:io';

import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  const requiredKeys = [
    'listingRecallTitle',
    'listingRecallSourceBadge',
    'listingRecallCampaignsFound',
    'listingRecallCampaignCount',
    'listingRecallLastUpdated',
    'listingRecallComponent',
    'listingRecallCampaignNumber',
    'listingRecallManufacturer',
    'listingRecallSummary',
    'listingRecallConsequence',
    'listingRecallRemedy',
    'listingRecallNotes',
    'listingRecallReportReceivedDate',
    'listingRecallParkIt',
    'listingRecallParkOutside',
    'listingRecallOverTheAirUpdate',
    'listingRecallFlagYes',
    'listingRecallLimitationsTitle',
    'listingRecallLimitationUsMarketDataOnly',
    'listingRecallLimitationModelLevelNotExactVehicle',
    'listingRecallLimitationNotVinVerifiedRecallStatus',
    'listingRecallLimitationMayDifferByTrimEngineMarket',
    'listingRecallLimitationVerifyWithOfficialDealerOrNhtsa',
    'listingRecallLimitationMultipleCampaignsListed',
    'listingRecallLimitationGeneric',
    'listingRecallShowDetails',
    'listingRecallHideDetails',
  ];

  const forbiddenPhrases = [
    'This vehicle has an open recall',
    'This exact car has an open recall',
    'No recalls for this vehicle',
    'VIN verified',
    'Officially verified for this exact listing',
    'Guaranteed safe',
    'У этого автомобиля открытый отзыв',
    'Для этого автомобиля нет отзывов',
    'VIN проверен',
    'Acest vehicul are o rechemare deschisă',
  ];

  test('RU and RO ARB files contain all listingRecall keys', () {
    for (final localeFile in ['lib/l10n/app_ru.arb', 'lib/l10n/app_ro.arb']) {
      final raw = File(localeFile).readAsStringSync();
      for (final key in requiredKeys) {
        expect(raw.contains('"$key"'), isTrue, reason: '$key in $localeFile');
      }
    }
  });

  test('generated localization accessors exist for RU and RO', () {
    final ru = ruStrings();
    final ro = roStrings();

    expect(ru.listingRecallTitle, isNotEmpty);
    expect(ru.listingRecallSourceBadge, 'NHTSA');
    expect(ru.listingRecallShowDetails, 'Подробнее');
    expect(ru.listingRecallHideDetails, 'Скрыть');
    expect(ro.listingRecallTitle, isNotEmpty);
    expect(ro.listingRecallSourceBadge, 'NHTSA');
    expect(ro.listingRecallShowDetails, 'Detalii');
    expect(ro.listingRecallHideDetails, 'Ascunde');
  });

  test('AppLocalizations delegate resolves listingRecall keys', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.listingRecallLimitationGeneric, isNotEmpty);
    }
  });

  test('forbidden exact-vehicle claim phrases are absent from ARB values', () {
    for (final localeFile in ['lib/l10n/app_ru.arb', 'lib/l10n/app_ro.arb']) {
      final raw = File(localeFile).readAsStringSync();
      for (final phrase in forbiddenPhrases) {
        expect(raw.contains(phrase), isFalse, reason: '$phrase in $localeFile');
      }
    }
  });
}
