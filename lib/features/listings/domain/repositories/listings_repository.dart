import '../../../../core/utils/result.dart';
import '../entities/listing.dart';
import '../entities/listing_currency.dart';
import '../entities/listing_image.dart';
import '../entities/listing_sort_option.dart';

class ListingsQuery {
  const ListingsQuery({
    this.search,
    this.make,
    this.model,
    this.minYear,
    this.maxYear,
    this.minPrice,
    this.maxPrice,
    this.priceCurrency,
    this.maxMileage,
    this.city,
    this.sellerId,
    this.marketRegion,
    this.bodyType,
    this.status,
    this.typeIn,
    this.sort = ListingSortOption.newestFirst,
    this.page = 0,
    this.pageSize = 20,
  });

  final String? search;
  final String? make;

  /// Case-insensitive partial match on `listings.model`.
  final String? model;
  final int? minYear;
  final int? maxYear;

  /// Inclusive lower bound on `price_eur`.
  final num? minPrice;

  /// Inclusive upper bound on `price_eur`.
  final num? maxPrice;

  /// When set, restricts rows to this `listings.price_currency` (`eur`|`usd`).
  /// Amount bounds above still apply to `price_eur` only (no FX conversion).
  final ListingCurrency? priceCurrency;

  /// Inclusive upper bound on `mileage_km` (listings at or below this mileage).
  final int? maxMileage;

  /// Case-insensitive partial match on `listings.city`.
  final String? city;

  /// When set, returns listings owned by this seller only (RLS still
  /// applies — non-owner callers cannot bypass visibility).
  final String? sellerId;

  /// When set, restricts the result to a single market region. When null,
  /// both regions are returned (e.g. the "Both" feed option).
  final MarketRegion? marketRegion;

  /// When set, restricts results to this `body_type`. When null, no filter.
  final ListingBodyType? bodyType;

  /// Explicit status filter for the caller. The public feed must pass
  /// [ListingStatus.active] so owners do not see their own hidden/sold/
  /// archived rows leaking in through the owner-read RLS policy.
  /// My Listings intentionally leaves this null so all statuses are
  /// returned for the authenticated owner.
  final ListingStatus? status;

  /// When set (non-null and non-empty), restricts results to listings whose
  /// `type` is IN the provided set. The feed uses this to encode semantic
  /// filters: "Sale" ⇒ {sale, both}, "Exchange" ⇒ {exchange, both}. When
  /// null, no type filter is applied.
  final List<ListingType>? typeIn;

  /// Ordering before range pagination.
  final ListingSortOption sort;

  final int page;
  final int pageSize;
}

abstract interface class ListingsRepository {
  Future<Result<List<Listing>>> getListings(ListingsQuery query);
  Future<Result<Listing>> getById(String id);

  /// Owner-only status change. Backed by the `set_listing_status` RPC
  /// which enforces ownership (`seller_id = auth.uid()`) and the allowed
  /// status set at the database level. Returns the updated listing on
  /// success. Non-owners and anonymous callers get a failure.
  Future<Result<Listing>> updateStatus(String id, ListingStatus status);

  /// Owner-only permanent delete. Backed by the `delete_listing` RPC
  /// which enforces ownership (`seller_id = auth.uid()`) atomically
  /// inside the DELETE. Returns [Success] with unit on success;
  /// [FailureResult] when the listing does not exist, is not owned by
  /// the caller, the caller is not authenticated, or the transport
  /// fails. Cascades to `favorites` rows via the existing FK.
  Future<Result<void>> deleteListing(String id);

  /// Ordered gallery rows (`listing_images`). Read-only; INSERT/UPDATE/DELETE
  /// stay RPC-only in later phases.
  Future<Result<List<ListingImage>>> getListingImages(String listingId);
}
