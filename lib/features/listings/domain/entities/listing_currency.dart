/// Display/settlement currency aligned with `public.listings.price_currency`
/// (`eur` | `usd`). The numeric amount remains in [Listing.priceEur] until a
/// dedicated amount column exists.
enum ListingCurrency { eur, usd }

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
