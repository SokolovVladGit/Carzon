import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/repositories/listings_repository.dart';
import '../models/listing_model.dart';

abstract interface class ListingsRemoteDataSource {
  Future<List<ListingModel>> fetch(ListingsQuery query);
  Future<ListingModel> fetchById(String id);
}

class SupabaseListingsRemoteDataSource implements ListingsRemoteDataSource {
  SupabaseListingsRemoteDataSource(this._supabase);

  final SupabaseService _supabase;
  static const String _table = 'listings';

  @override
  Future<List<ListingModel>> fetch(ListingsQuery query) async {
    try {
      final from = query.page * query.pageSize;
      final to = from + query.pageSize - 1;

      var builder = _supabase.client.from(_table).select();
      if (query.search != null && query.search!.trim().isNotEmpty) {
        builder = builder.ilike('title', '%${query.search!.trim()}%');
      }
      if (query.make != null && query.make!.isNotEmpty) {
        builder = builder.eq('make', query.make!);
      }
      if (query.minYear != null) builder = builder.gte('year', query.minYear!);
      if (query.maxYear != null) builder = builder.lte('year', query.maxYear!);
      if (query.sellerId != null && query.sellerId!.isNotEmpty) {
        builder = builder.eq('seller_id', query.sellerId!);
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
      throw ServerException('Failed to fetch listings', cause: e, stackTrace: st);
    }
  }

  @override
  Future<ListingModel> fetchById(String id) async {
    try {
      final row = await _supabase.client.from(_table).select().eq('id', id).single();
      return ListingModel.fromJson(row);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException('Failed to fetch listing $id', cause: e, stackTrace: st);
    }
  }
}
