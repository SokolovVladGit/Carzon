import 'package:carzon/features/vehicle_recall_data/presentation/utils/recall_component_display_labels.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();
  final ro = roStrings();

  group('normalizeRecallComponentKey', () {
    test('normalizes slash and colon spacing', () {
      expect(
        normalizeRecallComponentKey('SEAT BELTS:REAR / OTHER:BUCKLE ASSEMBLY'),
        'SEAT BELTS:REAR/OTHER:BUCKLE ASSEMBLY',
      );
    });
  });

  group('resolveRecallComponentDisplayLabel', () {
    test('maps known NHTSA component strings in RU', () {
      expect(
        resolveRecallComponentDisplayLabel(ru, 'SUSPENSION:FRONT'),
        ru.listingRecallComponentSuspensionFront,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ru,
          'SEAT BELTS:REAR/OTHER:BUCKLE ASSEMBLY',
        ),
        ru.listingRecallComponentSeatBeltsRear,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ru,
          'SEAT BELTS:REAR / OTHER: BUCKLE ASSEMBLY',
        ),
        ru.listingRecallComponentSeatBeltsRear,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ru,
          'EQUIPMENT:OTHER:OWNERS/SERVICE/OTHER MANUAL',
        ),
        ru.listingRecallComponentEquipmentManual,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ru,
          'BACK OVER PREVENTION:DISPLAY FUNCTION',
        ),
        ru.listingRecallComponentBackOverPreventionDisplay,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ru,
          'ELECTRICAL SYSTEM:PROPULSION SYSTEM:TRACTION BATTERY',
        ),
        ru.listingRecallComponentElectricalPropulsionBattery,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ru,
          'SERVICE BRAKES, AIR:SUPPLY:HOSES, LINES/PIPING, AND FITTINGS',
        ),
        ru.listingRecallComponentServiceBrakesAirSupply,
      );
    });

    test('maps known NHTSA component strings in RO', () {
      expect(
        resolveRecallComponentDisplayLabel(ro, 'SUSPENSION:FRONT'),
        ro.listingRecallComponentSuspensionFront,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ro,
          'SEAT BELTS:REAR/OTHER:BUCKLE ASSEMBLY',
        ),
        ro.listingRecallComponentSeatBeltsRear,
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ro,
          'ELECTRICAL SYSTEM:PROPULSION SYSTEM:TRACTION BATTERY',
        ),
        ro.listingRecallComponentElectricalPropulsionBattery,
      );
    });

    test('compact fallback shortens unknown components for collapsed rows', () {
      expect(
        resolveRecallComponentDisplayLabel(ru, 'UNKNOWN:WIDGET:PART'),
        'Unknown · Widget',
      );
      expect(
        resolveRecallComponentDisplayLabel(
          ru,
          'SEAT BELTS:REAR/OTHER:BUCKLE ASSEMBLY EXTRA',
        ),
        ru.listingRecallComponentSeatBeltsRear,
      );
      expect(
        resolveRecallComponentDisplayLabel(ru, 'Airbag inflator'),
        'Airbag inflator',
      );
      expect(
        resolveRecallComponentDisplayLabel(ru, ''),
        '',
      );
    });

    test('truncates very long unknown fallback labels', () {
      final label = resolveRecallComponentDisplayLabel(
        ru,
        'VERYLONGCOMPONENTNAME:ANOTHERVERYLONGSEGMENTNAME',
      );
      expect(label.length, lessThanOrEqualTo(kRecallComponentCollapsedLabelMaxLength));
      expect(label, isNotEmpty);
    });
  });

  group('resolveRecallComponentCategoryLabel', () {
    test('uses first segment of known localized label', () {
      expect(
        resolveRecallComponentCategoryLabel(ru, 'SUSPENSION:FRONT'),
        'Подвеска',
      );
      expect(
        resolveRecallComponentCategoryLabel(
          ru,
          'SEAT BELTS:REAR/OTHER:BUCKLE ASSEMBLY',
        ),
        'Ремни безопасности',
      );
    });

    test('uses compact fallback first segment for unknown components', () {
      expect(
        resolveRecallComponentCategoryLabel(ru, 'FUEL SYSTEM'),
        'Fuel System',
      );
    });
  });

  group('recallComponentHasKnownDisplayLabel', () {
    test('returns true for exact and prefix matches', () {
      expect(recallComponentHasKnownDisplayLabel('SUSPENSION:FRONT'), isTrue);
      expect(
        recallComponentHasKnownDisplayLabel('SEAT BELTS:REAR/OTHER:BUCKLE ASSEMBLY'),
        isTrue,
      );
      expect(recallComponentHasKnownDisplayLabel('UNKNOWN:WIDGET'), isFalse);
    });
  });
}
