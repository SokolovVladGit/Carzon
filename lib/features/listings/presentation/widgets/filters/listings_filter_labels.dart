import 'package:carzon/l10n/app_localizations.dart';

import '../../../domain/entities/listing.dart';
import '../../../domain/entities/listing_sort_option.dart';

String listingFilterBodyTypeLabel(AppLocalizations l10n, ListingBodyType t) {
  switch (t) {
    case ListingBodyType.sedan:
      return l10n.listingBodyTypeSedan;
    case ListingBodyType.hatchback:
      return l10n.listingBodyTypeHatchback;
    case ListingBodyType.wagon:
      return l10n.listingBodyTypeWagon;
    case ListingBodyType.suv:
      return l10n.listingBodyTypeSuv;
    case ListingBodyType.coupe:
      return l10n.listingBodyTypeCoupe;
    case ListingBodyType.convertible:
      return l10n.listingBodyTypeConvertible;
    case ListingBodyType.minivan:
      return l10n.listingBodyTypeMinivan;
    case ListingBodyType.pickup:
      return l10n.listingBodyTypePickup;
    case ListingBodyType.van:
      return l10n.listingBodyTypeVan;
    case ListingBodyType.other:
      return l10n.listingBodyTypeOther;
  }
}

String listingFilterSortOptionLabel(AppLocalizations l10n, ListingSortOption o) {
  switch (o) {
    case ListingSortOption.newestFirst:
      return l10n.filterSortNewestFirst;
    case ListingSortOption.priceLowToHigh:
      return l10n.filterSortPriceLowHigh;
    case ListingSortOption.priceHighToLow:
      return l10n.filterSortPriceHighLow;
    case ListingSortOption.newestYearFirst:
      return l10n.filterSortNewestYear;
    case ListingSortOption.lowestMileageFirst:
      return l10n.filterSortLowestMileage;
  }
}
