import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/listings/presentation/bloc/listings_state.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listing_filter_summary_presenter.dart';
import 'package:carzon/features/listings/presentation/widgets/filters/listings_filter_form_seed.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  test('vanilla draft uses default layout', () {
    final view = buildListingsFilterSummaryView(
      l10n,
      ListingsFilterFormSeed.fromListingsState(const ListingsState()),
    );
    expect(view.useDefaultLayout, isTrue);
  });

  test('make/model and price produce active Russian summary line', () {
    final view = buildListingsFilterSummaryView(
      l10n,
      const ListingsFilterFormSeed(
        make: 'Toyota',
        model: 'Corolla',
        minYear: 2015,
        maxYear: 2020,
        minPrice: null,
        maxPrice: null,
        maxMileage: 120000,
        city: null,
        typeFilter: ListingTypeFilter.any,
        region: MarketRegionFilter.transnistria,
        sort: ListingSortOption.newestFirst,
        bodyType: null,
        priceCurrencyFilter: ListingPriceCurrencyFilter.any,
      ),
    );
    expect(view.useDefaultLayout, isFalse);
    expect(view.activeLine, isNotNull);
    expect(view.activeLine, contains('Toyota Corolla'));
    expect(view.activeLine, contains('2015'));
    expect(view.activeLine, contains('2020'));
    expect(view.activeLine, contains('120'));
  });

  test('exchange and moldova appear in summary', () {
    final view = buildListingsFilterSummaryView(
      l10n,
      const ListingsFilterFormSeed(
        make: null,
        model: null,
        minYear: null,
        maxYear: null,
        minPrice: null,
        maxPrice: 10000,
        maxMileage: null,
        city: null,
        typeFilter: ListingTypeFilter.exchange,
        region: MarketRegionFilter.moldova,
        sort: ListingSortOption.newestFirst,
        bodyType: null,
        priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
      ),
    );
    expect(view.useDefaultLayout, isFalse);
    expect(view.activeLine, contains('€'));
    expect(view.activeLine, contains(l10n.regionMoldova));
    expect(view.activeLine, contains(l10n.typeExchange));
  });
}
