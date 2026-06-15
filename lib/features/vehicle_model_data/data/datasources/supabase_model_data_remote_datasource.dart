import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/buyer_listing_model_data_source_result.dart';
import 'model_data_remote_datasource.dart';

class SupabaseModelDataRemoteDataSource implements ModelDataRemoteDataSource {
  SupabaseModelDataRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _rpcGetListingModelDataForBuyer =
      'get_listing_model_data_for_buyer';

  @override
  Future<List<BuyerListingModelDataSourceResult>> fetchListingModelDataForBuyer(
    String listingId,
  ) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpcGetListingModelDataForBuyer,
        params: <String, dynamic>{'p_listing_id': listingId},
      );
      final rows = <BuyerListingModelDataSourceResult>[];
      if (data is List) {
        for (final item in data) {
          if (item is! Map) continue;
          final row = Map<String, dynamic>.from(item);
          final parsed = BuyerListingModelDataSourceResult.tryParse(row);
          if (parsed != null) rows.add(parsed);
        }
      }
      return rows;
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to fetch model data for listing $listingId',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
