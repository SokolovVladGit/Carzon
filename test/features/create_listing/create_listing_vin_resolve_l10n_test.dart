import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

const _keys = [
  'createListingVinAutofillHint',
  'createListingVinResolving',
  'createListingVehicleFound',
  'createListingConfirmVehicle',
  'createListingEnterManually',
  'createListingChangeManually',
  'createListingVehicleIdentifiedFromVin',
  'createListingVinChecksumHint',
  'createListingVinPartialTitle',
  'createListingVinPartial',
  'createListingVinNoData',
  'createListingVinResolverFailed',
  'createListingVinMayMiss',
  'createListingAdditionalDetails',
  'createListingAdditionalDetailsSubtitle',
];

void main() {
  test('RU/RO VIN-first keys exist and are non-English', () {
    final ruArb =
        jsonDecode(File('lib/l10n/app_ru.arb').readAsStringSync())
            as Map<String, dynamic>;
    final roArb =
        jsonDecode(File('lib/l10n/app_ro.arb').readAsStringSync())
            as Map<String, dynamic>;
    final ru = ruStrings();
    final ro = roStrings();

    for (final key in _keys) {
      expect(ruArb[key], isA<String>());
      expect(roArb[key], isA<String>());
      expect((ruArb[key] as String).trim(), isNotEmpty);
      expect((roArb[key] as String).trim(), isNotEmpty);
    }

    expect(ru.createListingEnterManually, isNot('Enter manually'));
    expect(ro.createListingEnterManually, isNot('Enter manually'));
    expect(ru.createListingConfirmVehicle, isNot('Confirm'));
    expect(
      ro.createListingAdditionalDetails,
      isNot('Additional vehicle details'),
    );
    expect(
      ru.createListingVinAutofillHint,
      'Введите или отсканируйте VIN. Carzon автоматически определит марку, модель и год.',
    );
    expect(
      ro.createListingVinAutofillHint,
      'Introduceți sau scanați VIN-ul. Carzon va identifica automat marca, modelul și anul.',
    );
    expect(ru.createListingVinChecksumHint, contains('Проверьте VIN'));
    expect(
      ru.createListingVinChecksumHint.toLowerCase(),
      isNot(contains('checksum')),
    );
    expect(ro.createListingVinChecksumHint, contains('Verificați VIN'));
    expect(
      ru.createListingVinPartialTitle,
      'Не удалось полностью определить автомобиль.',
    );
    expect(ru.createListingVinResolving, isNot('Resolving'));
    expect(
      ru.createListingVehicleIdentifiedFromVin,
      isNot('Vehicle identified from VIN'),
    );
    expect(
      ro.createListingVehicleIdentifiedFromVin,
      isNot('Vehicle identified from VIN'),
    );
    expect(
      ru.createListingVehicleIdentifiedFromVin,
      isNot(ro.createListingVehicleIdentifiedFromVin),
    );
  });
}
