import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:carzon/features/listings/domain/entities/listing_sort_option.dart';
import 'package:carzon/features/recent_searches/presentation/utils/recent_search_display.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final ru = ruStrings();
  final ro = roStrings();

  test('search query uses localized title and filter chips in subtitle', () {
    final display = buildRecentSearchDisplay(
      ru,
      const ListingDiscoveryCriteria(
        search: 'octavia',
        make: 'Skoda',
        model: 'Octavia',
      ),
    );

    expect(display.title, ru.recentSearchesSearchOnlyLabel('octavia'));
    expect(display.subtitle, contains('Skoda'));
    expect(display.subtitle, isNot(contains('newest_first')));
  });

  test('filters-only uses localized filters title', () {
    final display = buildRecentSearchDisplay(
      ru,
      const ListingDiscoveryCriteria(
        make: 'BMW',
        marketRegion: MarketRegion.moldova,
      ),
    );

    expect(display.title, ru.recentSearchesFiltersOnlyLabel);
    expect(display.subtitle, isNotNull);
    expect(display.subtitle, isNot(contains('moldova')));
    expect(display.subtitle, contains(ru.regionMoldova));
  });

  test('RO localized search title smoke', () {
    final display = buildRecentSearchDisplay(
      ro,
      const ListingDiscoveryCriteria(search: 'dacia'),
    );
    expect(display.title, ro.recentSearchesSearchOnlyLabel('dacia'));
  });

  test('non-default sort appears as localized chip not raw enum', () {
    final display = buildRecentSearchDisplay(
      ru,
      const ListingDiscoveryCriteria(
        make: 'Audi',
        sort: ListingSortOption.priceLowToHigh,
      ),
    );
    expect(display.subtitle, isNotNull);
    expect(display.subtitle!.toLowerCase(), isNot(contains('price_low')));
  });
}
