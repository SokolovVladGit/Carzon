import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'listing_details_page does not import owner VIN report types (decoded stays off public path)',
    () {
      final src = File(
        'lib/features/listings/presentation/pages/listing_details_page.dart',
      ).readAsStringSync();
      expect(src.contains('OwnerListingVinReport'), isFalse);
      expect(src.contains('owner_listing_vin_report_status'), isFalse);
    },
  );
}
