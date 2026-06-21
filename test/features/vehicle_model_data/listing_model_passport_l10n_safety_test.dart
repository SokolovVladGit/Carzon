import 'dart:io';

import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  const requiredKeys = [
    'listingModelPassportSectionTitle',
    'listingModelPassportFuelEconomyTitle',
    'listingModelPassportCombinedConsumption',
    'listingModelPassportCityConsumption',
    'listingModelPassportHighwayConsumption',
    'listingModelPassportFuelType',
    'listingModelPassportCo2Emissions',
    'listingModelPassportSource',
    'listingModelPassportLastUpdated',
    'listingModelPassportLoading',
    'listingModelPassportPendingTitle',
    'listingModelPassportPendingBody',
    'listingModelPassportLimitationsTitle',
    'listingModelPassportSourceEpa',
    'listingModelPassportUnitLPer100km',
    'listingModelPassportUnitGPerKm',
    'listingModelPassportLimitationUsMarketOnly',
    'listingModelPassportLimitationTrimEngineMarket',
    'listingModelPassportLimitationModelLevel',
    'listingModelPassportLimitationSourceUnavailable',
    'listingModelPassportLimitationOpenData',
    'listingModelPassportLimitationNotHistory',
    'listingModelPassportLimitationNotRecall',
    'listingModelPassportLimitationMultipleConfigurations',
    'listingModelPassportLimitationBasicCatalogOnly',
    'listingModelPassportLimitationGeneric',
    'listingModelPassportFuelRegularGasoline',
    'listingModelPassportFuelPremiumGasoline',
    'listingModelPassportFuelMidgradeGasoline',
    'listingModelPassportFuelDiesel',
    'listingModelPassportFuelElectricity',
    'listingModelPassportFuelHybrid',
    'listingModelPassportFuelPlugInHybrid',
    'listingModelPassportFuelTypeGeneric',
  ];

  test('RU and RO ARB files contain all listingModelPassport keys', () {
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

    expect(ru.listingModelPassportSectionTitle, isNotEmpty);
    expect(ru.listingModelPassportSourceEpa, 'EPA · FuelEconomy.gov');
    expect(ro.listingModelPassportSectionTitle, isNotEmpty);
    expect(ro.listingModelPassportSourceEpa, 'EPA · FuelEconomy.gov');
  });

  test('AppLocalizations delegate resolves listingModelPassport keys', () {
    for (final locale in AppLocalizations.supportedLocales) {
      final l10n = lookupAppLocalizations(locale);
      expect(l10n.listingModelPassportLimitationGeneric, isNotEmpty);
    }
  });
}
