import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/listing_currency.dart';
import '../../domain/entities/listing_sort_option.dart';
import '../../domain/repositories/listings_repository.dart';
import '../models/listing_image_model.dart';
import '../models/listing_model.dart';

abstract interface class ListingsRemoteDataSource {
  Future<List<ListingModel>> fetch(ListingsQuery query);
  Future<ListingModel> fetchById(String id);
  Future<List<ListingImageModel>> fetchListingImages(String listingId);

  /// Calls the `set_listing_status` SQL function. Ownership and the
  /// allowed status set are enforced in the function body; the client
  /// does not construct an UPDATE itself. Returns the refreshed row.
  Future<ListingModel> updateStatus(String id, String status);

  /// Calls the `delete_listing` SQL function. Ownership is enforced in
  /// the function body (`seller_id = auth.uid()` inside the DELETE);
  /// the client does not construct a DELETE itself. Returns normally
  /// on success; throws [ServerException] on any failure (not
  /// authenticated, not found, not owned, transport).
  Future<void> deleteListing(String id);
}

class SupabaseListingsRemoteDataSource implements ListingsRemoteDataSource {
  SupabaseListingsRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  final AppLogger _logger = AppLogger('SupabaseListingsRemoteDataSource');

  static const String _table = 'listings';
  static const String _imagesTable = 'listing_images';

  @override
  Future<List<ListingModel>> fetch(ListingsQuery query) async {
    try {
      final from = query.page * query.pageSize;
      final to = from + query.pageSize - 1;

      // Keep filter operations on [PostgrestFilterBuilder] only. `.order()` and
      // further transforms return [PostgrestTransformBuilder]; reassigning that
      // into a variable inferred as the filter type throws at runtime:
      // PostgrestTransformBuilder is not a subtype of PostgrestFilterBuilder.
      sb.PostgrestFilterBuilder<sb.PostgrestList> filterQuery =
          _supabase.client.from(_table).select();
      if (query.search != null && query.search!.trim().isNotEmpty) {
        filterQuery = filterQuery.ilike('title', '%${query.search!.trim()}%');
      }
      // `make` is defensively trimmed here as well so any caller that forgets
      // to normalize (or leading/trailing spaces that slip through the UI)
      // still produces a useful query. `ilike` gives case-insensitive partial
      // matching, mirroring the search behaviour — users typing "volkswagen"
      // will match rows stored as "Volkswagen".
      if (query.make != null) {
        final trimmedMake = query.make!.trim();
        if (trimmedMake.isNotEmpty) {
          filterQuery = filterQuery.ilike('make', '%$trimmedMake%');
        }
      }
      if (query.minYear != null) {
        filterQuery = filterQuery.gte('year', query.minYear!);
      }
      if (query.maxYear != null) {
        filterQuery = filterQuery.lte('year', query.maxYear!);
      }
      if (query.sellerId != null && query.sellerId!.isNotEmpty) {
        filterQuery = filterQuery.eq('seller_id', query.sellerId!);
      }
      if (query.marketRegion != null) {
        filterQuery = filterQuery.eq('market_region', query.marketRegion!.name);
      }
      if (query.bodyType != null) {
        filterQuery = filterQuery.eq('body_type', query.bodyType!.name);
      }
      // Explicit status filter: callers (e.g. the public feed) must pass
      // `active` so owners do not see their own non-active listings mixed in
      // via the owner-read RLS policy. Left null by My Listings.
      if (query.status != null) {
        filterQuery = filterQuery.eq('status', query.status!.name);
      }
      // Semantic listing-type filter. The caller is responsible for deciding
      // which DB values belong to each UX option (e.g. "Sale" ⇒ sale + both).
      if (query.typeIn != null && query.typeIn!.isNotEmpty) {
        filterQuery = filterQuery.inFilter(
          'type',
          query.typeIn!.map((t) => t.name).toList(growable: false),
        );
      }

      if (query.model != null) {
        final trimmedModel = query.model!.trim();
        if (trimmedModel.isNotEmpty) {
          filterQuery = filterQuery.ilike('model', '%$trimmedModel%');
        }
      }
      if (query.city != null) {
        final trimmedCity = query.city!.trim();
        if (trimmedCity.isNotEmpty) {
          filterQuery = filterQuery.ilike('city', '%$trimmedCity%');
        }
      }
      if (query.minPrice != null) {
        filterQuery = filterQuery.gte('price_eur', query.minPrice!);
      }
      if (query.maxPrice != null) {
        filterQuery = filterQuery.lte('price_eur', query.maxPrice!);
      }
      if (query.maxMileage != null) {
        filterQuery = filterQuery.lte('mileage_km', query.maxMileage!);
      }
      if (query.priceCurrency != null) {
        filterQuery = filterQuery.eq(
          'price_currency',
          listingCurrencyToDbString(query.priceCurrency!),
        );
      }

      final sb.PostgrestTransformBuilder<sb.PostgrestList> orderedQuery =
          _applySort(filterQuery, query.sort);
      final rows = await orderedQuery.range(from, to);

      return _mapRowsToModels(rows);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      _logger.error(
        'Listings fetch failed before/after PostgREST (non-ServerException): '
        '${e.runtimeType}',
        e,
        st,
      );
      throw ServerException(
        'Failed to fetch listings',
        cause: e,
        stackTrace: st,
      );
    }
  }

  /// Converts each wire row to [ListingModel], logging safe context on failures.
  List<ListingModel> _mapRowsToModels(List<dynamic> rows) {
    final out = <ListingModel>[];
    for (final raw in rows) {
      Map<String, dynamic> json;
      try {
        json = _listingRowToJsonMap(raw);
      } catch (e, st) {
        _logger.error(
          'Listing row is not a JSON object map (${e.runtimeType})',
          e,
          st,
        );
        rethrow;
      }
      try {
        out.add(ListingModel.fromJson(json));
      } on ServerException catch (e) {
        final idHint = _safeListingIdForLog(json);
        _logger.warn(
          'Listing row mapping ServerException${idHint != null ? ' (id=$idHint)' : ''}: '
          '${e.message}',
        );
        rethrow;
      } catch (e, st) {
        final idHint = _safeListingIdForLog(json);
        _logger.error(
          'Listing row map failed${idHint != null ? ' (listing id: $idHint)' : ''}: '
          '${e.runtimeType}',
          e,
          st,
        );
        rethrow;
      }
    }
    return out;
  }

  static Map<String, dynamic> _listingRowToJsonMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    throw StateError('Expected Map row, got ${raw.runtimeType}');
  }

  static String? _safeListingIdForLog(Map<String, dynamic> json) {
    try {
      final id = json['id'];
      if (id is String) {
        final t = id.trim();
        if (t.isNotEmpty) return t;
      } else if (id != null) {
        final s = id.toString().trim();
        if (s.isNotEmpty) return s;
      }
    } catch (_) {}
    return null;
  }

  /// Single-column ordering per option (matches pre-Stage-1 feed behavior).
  /// Avoid chaining extra `order()` keys so default queries stay compatible
  /// with all hosted PostgREST builds and row sets.
  ///
  /// Must return [sb.PostgrestTransformBuilder] — `.order()` does not return
  /// a filter builder (see [fetch]).
  static sb.PostgrestTransformBuilder<sb.PostgrestList> _applySort(
    sb.PostgrestFilterBuilder<sb.PostgrestList> filterQuery,
    ListingSortOption sort,
  ) {
    switch (sort) {
      case ListingSortOption.newestFirst:
        return filterQuery.order('created_at', ascending: false);
      case ListingSortOption.priceLowToHigh:
        return filterQuery.order('price_eur', ascending: true);
      case ListingSortOption.priceHighToLow:
        return filterQuery.order('price_eur', ascending: false);
      case ListingSortOption.newestYearFirst:
        return filterQuery
            .order('year', ascending: false)
            .order('created_at', ascending: false);
      case ListingSortOption.lowestMileageFirst:
        return filterQuery.order('mileage_km', ascending: true);
    }
  }

  @override
  Future<ListingModel> fetchById(String id) async {
    try {
      final row = await _supabase.client
          .from(_table)
          .select()
          .eq('id', id)
          .single();
      return ListingModel.fromJson(_listingRowToJsonMap(row));
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to fetch listing $id',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<ListingImageModel>> fetchListingImages(String listingId) async {
    try {
      final rows = await _supabase.client
          .from(_imagesTable)
          .select()
          .eq('listing_id', listingId)
          .order('position', ascending: true);
      return rows
          .map<ListingImageModel>(
            (row) => ListingImageModel.fromJson(
              Map<String, dynamic>.from(row as Map),
            ),
          )
          .toList(growable: false);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to fetch listing images for $listingId',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<ListingModel> updateStatus(String id, String status) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        'set_listing_status',
        params: {'p_listing_id': id, 'p_status': status},
      );
      // Postgrest can return the row as either a JSON object (single-row
      // scalar return) or a single-element list depending on versions.
      // Both shapes are handled defensively.
      Map<String, dynamic>? row;
      if (data is Map<String, dynamic>) {
        row = data;
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        row = Map<String, dynamic>.from(data.first as Map);
      }
      if (row == null) {
        throw ServerException(
          'Unexpected response from set_listing_status RPC.',
        );
      }
      return ListingModel.fromJson(row);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } on ServerException {
      rethrow;
    } catch (e, st) {
      throw ServerException(
        'Failed to update listing status for $id',
        cause: e,
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteListing(String id) async {
    try {
      // The function returns void; any non-zero deleted row count is
      // signalled by the function body raising an exception, which
      // surfaces as a PostgrestException. We deliberately ignore the
      // RPC payload here.
      await _supabase.client.rpc(
        'delete_listing',
        params: {'p_listing_id': id},
      );
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to delete listing $id',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
