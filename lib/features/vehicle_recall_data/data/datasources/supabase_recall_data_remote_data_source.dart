import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/errors/exceptions.dart';
import '../../../../core/services/supabase_service.dart';
import '../../domain/entities/buyer_listing_recall_source_result.dart';
import 'recall_data_remote_data_source.dart';

class SupabaseRecallDataRemoteDataSource implements RecallDataRemoteDataSource {
  SupabaseRecallDataRemoteDataSource(this._supabase);

  final SupabaseService _supabase;

  static const String _rpcGetListingRecallsForBuyer =
      'get_listing_recalls_for_buyer';

  @override
  Future<BuyerListingRecallSourceResult> fetchListingRecallsForBuyer(
    String listingId,
  ) async {
    try {
      final dynamic data = await _supabase.client.rpc(
        _rpcGetListingRecallsForBuyer,
        params: <String, dynamic>{'p_listing_id': listingId},
      );
      return BuyerListingRecallSourceResult.fromRpcData(data);
    } on sb.PostgrestException catch (e, st) {
      throw ServerException(e.message, cause: e, stackTrace: st);
    } catch (e, st) {
      throw ServerException(
        'Failed to fetch recall data for listing $listingId',
        cause: e,
        stackTrace: st,
      );
    }
  }
}
