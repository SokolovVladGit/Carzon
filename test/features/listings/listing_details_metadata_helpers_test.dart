import 'package:carzon/features/listings/presentation/utils/listing_details_metadata.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('ru');
    await initializeDateFormatting('ro');
  });

  final ru = lookupAppLocalizations(const Locale('ru'));
  final ro = lookupAppLocalizations(const Locale('ro'));
  final createdAt = DateTime.utc(2026, 5, 16);

  test('today label is null for zero or missing counts', () {
    expect(listingDetailsMetadataTodayLabel(ru, todayViews: null), isNull);
    expect(listingDetailsMetadataTodayLabel(ru, todayViews: 0), isNull);
  });

  test('today label uses localized live copy when positive', () {
    expect(listingDetailsMetadataTodayLabel(ru, todayViews: 1), 'Сегодня +1');
    expect(listingDetailsMetadataTodayLabel(ro, todayViews: 3), 'Astăzi +3');
  });

  test('added date label uses compact localized formatter output', () {
    final ruDate = listingDetailsMetadataAddedDateLabel(
      ru,
      createdAt: createdAt,
    );
    final roDate = listingDetailsMetadataAddedDateLabel(
      ro,
      createdAt: createdAt,
    );

    expect(ruDate, isNot(contains('Добавлено')));
    expect(roDate, isNot(contains('Adăugat pe')));
    expect(ruDate, contains('2026'));
    expect(roDate, contains('2026'));
  });
}
