import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('favorites listing payload uses explicit public projection', () {
    final source = File(
      'lib/features/favorites/data/datasources/favorites_remote_datasource.dart',
    ).readAsStringSync();

    expect(source, isNot(contains('listings(*)')));
    expect(source, contains('listings(\$_publicListingColumns)'));
    expect(source, contains('ListingModel.fromPublicJson'));
    expect(source, isNot(contains('contact_phone')));
    expect(source, isNot(contains('telegram_username')));
    expect(source, isNot(contains('whatsapp_enabled')));
  });
}
