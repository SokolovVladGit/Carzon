import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Recall presentation layer (static safety)', () {
    late List<String> sources;

    setUpAll(() {
      sources = [
        File(
          'lib/features/vehicle_recall_data/presentation/widgets/listing_details_recall_section.dart',
        ).readAsStringSync(),
        File(
          'lib/features/vehicle_recall_data/presentation/utils/recall_formatters.dart',
        ).readAsStringSync(),
        File(
          'lib/features/vehicle_recall_data/presentation/utils/recall_limitation_labels.dart',
        ).readAsStringSync(),
        File(
          'lib/features/vehicle_recall_data/presentation/utils/recall_ui_state.dart',
        ).readAsStringSync(),
      ];
    });

    test('does not call NHTSA HTTP or VIN APIs from presentation', () {
      for (final source in sources) {
        expect(source.toLowerCase(), isNot(contains('api.nhtsa.gov')));
        expect(source.toLowerCase(), isNot(contains('recallsbyvehicle')));
        expect(source.toLowerCase(), isNot(contains('decodevinvalues')));
      }
    });

    test('does not expose forbidden internal fields in UI code', () {
      for (final source in sources) {
        expect(source, isNot(contains('listing_vehicle_identity')));
        expect(source, isNot(contains('vin_normalized')));
        expect(source, isNot(contains('source_metadata')));
        expect(source, isNot(contains('cache_key')));
      }
    });

    test('uses GetListingRecallsForBuyer via GetIt in section widget', () {
      final section = sources.first;
      expect(section, contains('GetListingRecallsForBuyer'));
      expect(section, contains('sl<GetListingRecallsForBuyer>'));
    });
  });
}
