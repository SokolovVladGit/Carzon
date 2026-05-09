/// Display/settlement currency aligned with `public.listings.price_currency`
/// (`eur` | `usd`). The numeric amount remains in [Listing.priceEur] until a
/// dedicated amount column exists.
enum ListingCurrency { eur, usd }

/// Optional constraint on listing rows by `listings.price_currency`.
///
/// MVP: filtered amounts are compared on `price_eur` only; [any] does not add a
/// currency column predicate. [usd]/[eur] add `.eq('price_currency', …)`.
/// No FX conversion.
enum ListingPriceCurrencyFilter { any, usd, eur }

extension ListingPriceCurrencyFilterX on ListingPriceCurrencyFilter {
  /// `null` for [any] — omit `price_currency` from the query.
  ListingCurrency? get asListingCurrencyOrNull {
    switch (this) {
      case ListingPriceCurrencyFilter.any:
        return null;
      case ListingPriceCurrencyFilter.usd:
        return ListingCurrency.usd;
      case ListingPriceCurrencyFilter.eur:
        return ListingCurrency.eur;
    }
  }
}

/// Parses wire / DB values safely. Unknown or missing values default to EUR
/// so older API rows without `price_currency` keep prior behaviour.
ListingCurrency listingCurrencyFromDbString(String? raw) {
  switch (raw?.trim().toLowerCase()) {
    case 'usd':
      return ListingCurrency.usd;
    case 'eur':
    case '':
    case null:
    default:
      return ListingCurrency.eur;
  }
}

String listingCurrencyToDbString(ListingCurrency currency) => currency.name;
