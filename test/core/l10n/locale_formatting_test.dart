import 'package:carzon/features/listings/presentation/utils/listing_formatters.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listing_filter_summary_presenter.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form_seed.dart';
import 'package:carzon/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

void main() {
  test('formatKm uses localized kilometer suffix', () {
    final ru = lookupAppLocalizations(const Locale('ru'));
    final ro = lookupAppLocalizations(const Locale('ro'));
    expect(formatKm(ru, 12000), contains(ru.commonKilometersShort));
    expect(formatKm(ro, 12000), contains(ro.commonKilometersShort));
    expect(formatKm(ru, 12000), isNot(contains(' km')));
  });

  test('filter summary number formatting follows l10n locale', () {
    final ro = lookupAppLocalizations(const Locale('ro'));
    final view = buildListingsFilterSummaryView(
      ro,
      ListingsFilterFormSeed.fromListingsState(
        const ListingsState().copyWith(minPrice: 10000, maxPrice: 20000),
      ),
    );
    expect(view.activeLine, isNotNull);
    final formatted = NumberFormat.decimalPattern(ro.localeName).format(10000);
    expect(view.activeLine, contains(formatted));
  });
}
