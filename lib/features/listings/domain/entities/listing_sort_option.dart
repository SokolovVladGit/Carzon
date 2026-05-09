/// How the public listings feed orders rows before pagination.
///
/// Kept as domain enum so the same choice can be reused when persisting
/// browse / filter-alert snapshots.
enum ListingSortOption {
  /// `created_at` descending (newest listed first).
  newestFirst,

  /// `price_eur` ascending.
  priceLowToHigh,

  /// `price_eur` descending.
  priceHighToLow,

  /// `year` descending (then recency as secondary).
  newestYearFirst,

  /// `mileage_km` ascending (then id as secondary).
  lowestMileageFirst,
}
