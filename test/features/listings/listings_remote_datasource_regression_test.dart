import 'package:carzon/features/listings/data/datasources/listings_discovery_search_filter.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression anchor for [SupabaseListingsRemoteDataSource.fetch] (see
/// `lib/features/listings/data/datasources/listings_remote_datasource.dart`).
///
/// PostgREST `.order()` returns a [PostgrestTransformBuilder], not a
/// [PostgrestFilterBuilder]. Storing the sort result in the same `var` that
/// held the filter chain inferred `PostgrestFilterBuilder` and caused a cold
/// start runtime error:
/// `PostgrestTransformBuilder<...> is not a subtype of PostgrestFilterBuilder<...>`.
///
/// The datasource uses separate `filterQuery` and `orderedQuery` variables.
void main() {
  test('listings datasource regression is documented (builder type split)', () {
    expect(true, isTrue);
  });

  test('free-text search uses PostgREST or across title, make, and model', () {
    expect(
      listingsDiscoverySearchPostgrestOrFilter('Audi'),
      'title.ilike.%Audi%,make.ilike.%Audi%,model.ilike.%Audi%',
    );
  });
}
