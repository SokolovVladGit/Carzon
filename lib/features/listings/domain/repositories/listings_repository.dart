import '../../../../core/utils/result.dart';
import '../entities/listing.dart';

class ListingsQuery {
  const ListingsQuery({
    this.search,
    this.make,
    this.minYear,
    this.maxYear,
    this.sellerId,
    this.page = 0,
    this.pageSize = 20,
  });

  final String? search;
  final String? make;
  final int? minYear;
  final int? maxYear;
  /// When set, returns listings owned by this seller only (RLS still
  /// applies — non-owner callers cannot bypass visibility).
  final String? sellerId;
  final int page;
  final int pageSize;
}

abstract interface class ListingsRepository {
  Future<Result<List<Listing>>> getListings(ListingsQuery query);
  Future<Result<Listing>> getById(String id);
}
