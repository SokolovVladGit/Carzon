import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
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
  final date = DateTime.utc(2026, 1, 14, 12);

  test('formatListingAddedDate uses localized month abbreviations', () {
    final ruFormatted = formatListingAddedDate(ru, date);
    final roFormatted = formatListingAddedDate(ro, date);

    expect(ruFormatted, isNot(contains('2026-01-14')));
    expect(roFormatted, isNot(contains('2026-01-14')));
    expect(ruFormatted, contains('2026'));
    expect(roFormatted, contains('2026'));
    expect(ruFormatted.toLowerCase(), contains('янв'));
    expect(roFormatted.toLowerCase(), contains('ian'));
  });

  test('listingDetailsMetadataViews uses localized plural forms', () {
    expect(ru.listingDetailsMetadataViews(128), contains('просмотр'));
    expect(ro.listingDetailsMetadataViews(128), contains('vizualiz'));
  });

  test('listingDetailsMetadataViewsToday uses live chip copy', () {
    expect(ru.listingDetailsMetadataViewsToday(1), 'Сегодня +1');
    expect(ro.listingDetailsMetadataViewsToday(2), 'Astăzi +2');
  });
}
