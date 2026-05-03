import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
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
  static const String _table = 'listings';
  static const String _imagesTable = 'listing_images';

  @override
  Future<List<ListingModel>> fetch(ListingsQuery query) async {
    try {
      final from = query.page * query.pageSize;
      final to = from + query.pageSize - 1;

      var builder = _supabase.client.from(_table).select();
      if (query.search != null && query.search!.trim().isNotEmpty) {
        builder = builder.ilike('title', '%${query.search!.trim()}%');
      }
      // `make` is defensively trimmed here as well so any caller that forgets
      // to normalize (or leading/trailing spaces that slip through the UI)
      // still produces a useful query. `ilike` gives case-insensitive partial
      // matching, mirroring the search behaviour — users typing "volkswagen"
      // will match rows stored as "Volkswagen".
      if (query.make != null) {
        final trimmedMake = query.make!.trim();
        if (trimmedMake.isNotEmpty) {
          builder = builder.ilike('make', '%$trimmedMake%');
        }
      }
      if (query.minYear != null) builder = builder.gte('year', query.minYear!);
      if (query.maxYear != null) builder = builder.lte('year', query.maxYear!);
      if (query.sellerId != null && query.sellerId!.isNotEmpty) {
        builder = builder.eq('seller_id', query.sellerId!);
      }
      if (query.marketRegion != null) {
        builder = builder.eq('market_region', query.marketRegion!.name);
      }
      // Explicit status filter: callers (e.g. the public feed) must pass
      // `active` so owners do not see their own non-active listings mixed in
      // via the owner-read RLS policy. Left null by My Listings.
      if (query.status != null) {
        builder = builder.eq('status', query.status!.name);
      }
      // Semantic listing-type filter. The caller is responsible for deciding
      // which DB values belong to each UX option (e.g. "Sale" ⇒ sale + both).
      if (query.typeIn != null && query.typeIn!.isNotEmpty) {
        builder = builder.inFilter(
          'type',
          query.typeIn!.map((t) => t.name).toList(growable: false),
        );
      }

      final rows = await builder
          .order('created_at', ascending: false)
          .range(from, to);

      return rows
          .map<ListingModel>((row) => ListingModel.fromJson(row))
          .toList(growable: false);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to fetch listings',
        cause: e,
        stackTrace: st,
      );
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
      return ListingModel.fromJson(row);
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
