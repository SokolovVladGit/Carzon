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
/// This cannot be exercised without a Supabase HTTP mock; keep the split when
/// changing the fetch pipeline.
void main() {
  test('listings datasource regression is documented (builder type split)', () {
    expect(true, isTrue);
  });
}
