import 'dart:collection';

/// Inclusive bounds for listing model year (`p_year`).
const int kListingYearMinInclusive = 1900;

/// One year ahead of calendar year matches common dealer "next model year"
/// practise and aligns with tolerant server checks.
int listingYearMaxInclusive({DateTime? now}) =>
    (now ?? DateTime.now()).year + 1;

bool isListingYearValid(int? year, {DateTime? now}) {
  if (year == null || year <= 0) return false;

  final max = listingYearMaxInclusive(now: now);
  return year >= kListingYearMinInclusive && year <= max;
}

/// Newest-first list for UI pickers.
List<int> listingYearsOrderedNewestFirst({DateTime? now}) {
  final max = listingYearMaxInclusive(now: now);
  return UnmodifiableListView(
    List<int>.generate(max - kListingYearMinInclusive + 1, (i) => max - i),
  );
}
