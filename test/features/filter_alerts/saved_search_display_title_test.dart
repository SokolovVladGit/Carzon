import 'package:carzon/features/filter_alerts/presentation/utils/saved_search_display_title.dart';
import 'package:carzon/features/listings/domain/entities/listing.dart';
import 'package:carzon/features/listings/domain/entities/listing_currency.dart';
import 'package:carzon/features/listings/domain/entities/listing_discovery_criteria.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/l10n_test_helpers.dart';

void main() {
  final l10n = ruStrings();

  test('make only uses make as title', () {
    expect(
      buildSavedSearchDisplayTitle(
        l10n,
        const ListingDiscoveryCriteria(make: 'Opel'),
      ),
      'Opel',
    );
  });

  test('make and model join with space', () {
    expect(
      buildSavedSearchDisplayTitle(
        l10n,
        const ListingDiscoveryCriteria(make: 'BMW', model: '320'),
      ),
      'BMW 320',
    );
  });

  test('make with budget uses middot separator', () {
    final title = buildSavedSearchDisplayTitle(
      l10n,
      const ListingDiscoveryCriteria(
        make: 'BMW',
        maxPrice: 15000,
        priceCurrencyFilter: ListingPriceCurrencyFilter.eur,
      ),
    );
    expect(title.startsWith('BMW · '), isTrue);
    expect(title.contains('15'), isTrue);
  });

  test('body type and city when no make', () {
    final title = buildSavedSearchDisplayTitle(
      l10n,
      const ListingDiscoveryCriteria(
        bodyType: ListingBodyType.suv,
        city: 'Кишинёв',
      ),
    );
    expect(title, '${l10n.listingBodyTypeSuv} · Кишинёв');
  });

  test('ignores generic stored name and uses criteria fallback', () {
    expect(
      buildSavedSearchDisplayTitle(l10n, const ListingDiscoveryCriteria()),
      l10n.savedSearchDisplayTitleFallback,
    );
  });

  test('search query becomes title when no make', () {
    expect(
      buildSavedSearchDisplayTitle(
        l10n,
        const ListingDiscoveryCriteria(search: 'diesel manual'),
      ),
      'diesel manual',
    );
  });
}
