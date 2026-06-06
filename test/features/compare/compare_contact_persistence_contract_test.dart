import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('compare snapshot does not persist seller contact fields', () {
    final snapshot = File(
      'lib/features/compare/domain/entities/compare_listing_snapshot.dart',
    ).readAsStringSync();

    expect(snapshot, isNot(contains('contactPhone')));
    expect(snapshot, isNot(contains('telegramUsername')));
    expect(snapshot, isNot(contains('whatsappEnabled')));
    expect(snapshot, isNot(contains('contact_phone')));
    expect(snapshot, isNot(contains('telegram_username')));
    expect(snapshot, isNot(contains('whatsapp_enabled')));
  });
}
