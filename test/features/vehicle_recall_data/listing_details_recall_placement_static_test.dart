import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Recall section is placed after Model Passport in listing details body', () {
    final source = File(
      'lib/features/listings/presentation/widgets/listing_details_body.dart',
    ).readAsStringSync();

    final passportIndex = source.indexOf('ListingDetailsModelPassportSection');
    final recallIndex = source.indexOf('ListingDetailsRecallSection');
    final descriptionIndex = source.indexOf('_ListingDescriptionBlock');

    expect(passportIndex, greaterThan(-1));
    expect(recallIndex, greaterThan(-1));
    expect(passportIndex, lessThan(recallIndex));
    expect(recallIndex, lessThan(descriptionIndex));
  });
}
