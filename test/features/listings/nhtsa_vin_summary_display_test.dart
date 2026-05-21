import 'package:carzon/features/listings/presentation/utils/nhtsa_vin_summary_display.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppLocalizations l10n;

  setUpAll(() {
    l10n = lookupAppLocalizations(const Locale('ru'));
  });

  test('nhtsaVinSummaryFieldsFromMap orders fields and omits empty', () {
    final fields = nhtsaVinSummaryFieldsFromMap(l10n, {
      'make': 'Toyota',
      'model': 'Camry',
      'year': 2020,
      'drive_type': 'FWD',
      'plant_country': 'Japan',
    });
    expect(fields, isNotEmpty);
    expect(fields.first.label, l10n.editListingVinReportDecodedMakeLabel);
    expect(fields.first.value, 'Toyota');
    expect(
      fields.any(
        (f) => f.label == l10n.listingBuyerVinReportNhtsaDriveTypeLabel,
      ),
      isTrue,
    );
    expect(fields.any((f) => f.value == 'Japan'), isTrue);
    expect(
      fields.any((f) => f.label == l10n.editListingVinReportDecodedFuelLabel),
      isFalse,
    );
  });

  test('cylinders maps numeric values and never shows worker placeholder', () {
    final fromInt = nhtsaVinSummaryFieldsFromMap(l10n, {'cylinders': 6});
    expect(fromInt.single.value, '6');
    expect(fromInt.single.label, l10n.listingBuyerVinReportNhtsaCylindersLabel);

    final fromString = nhtsaVinSummaryFieldsFromMap(l10n, {'cylinders': '4'});
    expect(fromString.single.value, '4');

    final fromPlaceholder = nhtsaVinSummaryFieldsFromMap(l10n, {
      'cylinders': r'$n',
    });
    expect(fromPlaceholder, isEmpty);

    final allValues = nhtsaVinSummaryFieldsFromMap(l10n, {
      'cylinders': 6,
      'doors': r'$n',
      'make': 'X',
    }).map((f) => f.value);
    expect(allValues, isNot(contains(r'$n')));
  });

  test('nhtsaVinSummaryGroupsFromMap uses core → specs → origin order', () {
    final groups = nhtsaVinSummaryGroupsFromMap(l10n, {
      'make': 'BMW',
      'body_type': 'Sedan',
      'plant_country': 'Germany',
    });
    expect(groups.length, 3);
    expect(groups[0].title, l10n.listingBuyerVinReportNhtsaGroupCoreIdentity);
    expect(groups[1].title, l10n.listingBuyerVinReportNhtsaGroupVehicleSpecs);
    expect(groups[2].title, l10n.listingBuyerVinReportNhtsaGroupOrigin);
    expect(groups[0].fields.first.value, 'BMW');
    expect(
      groups[1].fields.any(
        (f) => f.label == l10n.editListingVinReportDecodedBodyLabel,
      ),
      isTrue,
    );
  });

  test('omits empty groups when no fields in that section', () {
    final groups = nhtsaVinSummaryGroupsFromMap(l10n, {
      'make': 'Audi',
      'model': 'A4',
    });
    expect(groups.length, 1);
    expect(
      groups.single.title,
      l10n.listingBuyerVinReportNhtsaGroupCoreIdentity,
    );
  });

  test('long identity fields prefer stacked layout', () {
    final groups = nhtsaVinSummaryGroupsFromMap(l10n, {
      'manufacturer': 'VOLKSWAGEN AG',
      'vehicle_type': 'MULTIPURPOSE PASSENGER VEHICLE (MPV)',
    });
    final manufacturer = groups.first.fields.firstWhere(
      (f) => f.label == l10n.listingBuyerVinReportNhtsaManufacturerLabel,
    );
    expect(manufacturer.stackValue, isTrue);
    final vehicleType = groups[1].fields.firstWhere(
      (f) => f.label == l10n.listingBuyerVinReportNhtsaVehicleTypeLabel,
    );
    expect(vehicleType.stackValue, isTrue);
  });

  test('catalog caution flag is detected without error codes', () {
    expect(
      nhtsaVinSummaryShowsCatalogCaution({'catalog_decode_caution': true}),
      isTrue,
    );
    expect(nhtsaVinSummaryShowsCatalogCaution({'error_code': '7'}), isFalse);
  });
}
